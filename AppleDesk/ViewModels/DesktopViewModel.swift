import SwiftUI
import Combine
import AVFoundation

// MARK: - Snap Zone (tutti e 7 i tipi, come Windows 11)
enum SnapZone: Equatable {
    case fullscreen
    case leftHalf, rightHalf
    case topLeft, topRight
    case bottomLeft, bottomRight

    func previewFrame(for screen: CGSize) -> CGRect {
        let hw = screen.width / 2; let hh = screen.height / 2
        switch self {
        case .fullscreen:  return CGRect(origin: .zero, size: screen)
        case .leftHalf:    return CGRect(x: 0,  y: 0,  width: hw, height: screen.height)
        case .rightHalf:   return CGRect(x: hw, y: 0,  width: hw, height: screen.height)
        case .topLeft:     return CGRect(x: 0,  y: 0,  width: hw, height: hh)
        case .topRight:    return CGRect(x: hw, y: 0,  width: hw, height: hh)
        case .bottomLeft:  return CGRect(x: 0,  y: hh, width: hw, height: hh)
        case .bottomRight: return CGRect(x: hw, y: hh, width: hw, height: hh)
        }
    }

    // La taskbar si nasconde per questi snap
    var hidesTaskbar: Bool {
        switch self {
        case .fullscreen, .leftHalf, .rightHalf, .bottomLeft, .bottomRight: return true
        case .topLeft, .topRight: return false
        }
    }

    var cornerRadius: CGFloat { self == .fullscreen ? 0 : 16 }
}

@MainActor
class DesktopViewModel: ObservableObject {
    @Published var openWindows: [DesktopWindow] = [] { didSet { scheduleSaveState() } }
    @Published var appStates: [String: DesktopWindow] = [:] { didSet { scheduleSaveState() } }
    // taskbarApps è dinamico: pinned sempre presenti, non-pinned aggiunti all'apertura
    @Published var taskbarApps: [AppItem] = AppItem.defaults
    @Published var activeWindowID: UUID? = nil { didSet { scheduleSaveState() } }
    private var saveStateTask: Task<Void, Never>?
    @Published var showStartMenu: Bool = false
    @Published var taskbarVisible: Bool = true
    @Published var taskbarPinned: Bool = false
    @Published var taskbarAlwaysVisible: Bool = false
    @Published var snapPreview: SnapZone? = nil
    private var autoHideTimer: Timer?
    // Tiene traccia delle finestre snappate e la loro zona
    @Published var snappedWindowZones: [UUID: SnapZone] = [:]

    // Dimensione corrente dello schermo, aggiornata dalla GeometryReader in DesktopView.
    // Serve per aprire le finestre centrate e dimensionate in modo proporzionale.
    @Published var screenSize: CGSize = .zero

    // Spazio verticale riservato in basso per la taskbar (pillola + padding),
    // usato per centrare le finestre tra il bordo alto e la taskbar.
    private let taskbarReservedHeight: CGFloat = 90

    // Tutte le app cercabili nel menu Start
    let allApps: [AppItem] = AppItem.allApps

    func toggleStartMenu() {
        withAnimation(.spring(duration: 0.4, bounce: 0.1)) {
            showStartMenu.toggle()
            taskbarPinned = showStartMenu
            if showStartMenu {
                taskbarVisible = true
            } else {
                hideTaskbarIfNeeded()
            }
        }
    }

    func showTaskbar() {
        withAnimation(.spring(duration: 0.35, bounce: 0.15)) { taskbarVisible = true }
    }

    // Nasconde dopo 2s se le condizioni lo richiedono (es. l'utente ha mosso il cursore via)
    func scheduleAutoHide() {
        autoHideTimer?.invalidate()
        autoHideTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
            DispatchQueue.main.async { self?.hideTaskbarIfNeeded() }
        }
    }

    func cancelAutoHide() {
        autoHideTimer?.invalidate()
        autoHideTimer = nil
    }

    func hideTaskbarIfNeeded() {
        guard !taskbarAlwaysVisible else {
            showTaskbar()
            return
        }
        guard !taskbarPinned else { return }
        let shouldHide = openWindows.contains { w in
            guard !w.isMinimized else { return false }
            if w.isMaximized { return true }
            if let z = snappedWindowZones[w.id], z.hidesTaskbar { return true }
            return false
        }
        if shouldHide {
            withAnimation(.spring(duration: 0.35, bounce: 0.05)) { taskbarVisible = false }
        }
    }

    func addSnappedWindow(_ id: UUID, zone: SnapZone) {
        snappedWindowZones[id] = zone
        syncTaskbarVisibility()
    }

    func removeSnappedWindow(_ id: UUID) {
        snappedWindowZones.removeValue(forKey: id)
    }

    init() { loadState() }

    private func scheduleSaveState() {
        saveStateTask?.cancel()
        saveStateTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(80))
            guard !Task.isCancelled else { return }
            saveState()
        }
    }

    private func saveState() {
        if let data = try? JSONEncoder().encode(openWindows) {
            UserDefaults.standard.set(data, forKey: "savedWindows")
        }
        if let data = try? JSONEncoder().encode(appStates) {
            UserDefaults.standard.set(data, forKey: "savedAppStates")
        }
        if let activeID = activeWindowID?.uuidString {
            UserDefaults.standard.set(activeID, forKey: "activeWindowID")
        }
    }

    private func loadState() {
        if let data = UserDefaults.standard.data(forKey: "savedWindows"),
           let saved = try? JSONDecoder().decode([DesktopWindow].self, from: data) {
            self.openWindows = saved.map { window in
                var w = window
                if w.appID == "chrome" { w = DesktopWindow(id: w.id, appID: "zen", title: "Zen", icon: "globe", iconAsset: "zen_icon", position: w.position, size: w.size, isMinimized: w.isMinimized, isMaximized: w.isMaximized) }
                return w
            }
        }
        if let data = UserDefaults.standard.data(forKey: "savedAppStates"),
           let saved = try? JSONDecoder().decode([String: DesktopWindow].self, from: data) {
            var migrated = saved
            if let chrome = migrated.removeValue(forKey: "chrome") {
                migrated["zen"] = DesktopWindow(appID: "zen", title: "Zen", icon: "globe", iconAsset: "zen_icon", position: chrome.position, size: chrome.size, isMinimized: chrome.isMinimized, isMaximized: chrome.isMaximized)
            }
            self.appStates = migrated
        }
        if let activeIDStr = UserDefaults.standard.string(forKey: "activeWindowID"),
           let activeID = UUID(uuidString: activeIDStr) {
            self.activeWindowID = activeID
        } else {
            self.activeWindowID = openWindows.last?.id
        }
        // Ripristina taskbarApps per app non-pinnate già aperte
        for window in openWindows {
            if let app = allApps.first(where: { $0.id == window.appID }),
               !app.isPinned,
               !taskbarApps.contains(where: { $0.id == app.id }) {
                taskbarApps.append(app)
            }
        }
    }

    /// Calcola dimensione e posizione (centro) di default per una nuova finestra,
    /// centrata tra i due bordi laterali e tra il bordo alto e la taskbar.
    private func defaultWindowFrame(for appID: String) -> (size: CGSize, position: CGPoint) {
        // Fallback se lo schermo non è ancora noto (primissimo frame)
        guard screenSize.width > 0, screenSize.height > 0 else {
            let fallback: CGSize = switch appID {
            case "finder": CGSize(width: 860, height: 540)
            case "zen": CGSize(width: 900, height: 580)
            case "spotify": CGSize(width: 920, height: 620)
            case "settings": CGSize(width: 980, height: 640)
            case "geforcenow": CGSize(width: 1020, height: 680)
            case "cs2": CGSize(width: 1080, height: 700)
            default: CGSize(width: 780, height: 560)
            }
            return (fallback, CGPoint(x: fallback.width / 2 + 40, y: fallback.height / 2 + 40))
        }

        // Finder un filo più grande delle altre app, ma sempre entro lo schermo disponibile
        let widthRatio: CGFloat = switch appID {
        case "finder": 0.72
        case "zen": 0.78
        case "spotify": 0.76
        case "settings": 0.82
        case "geforcenow": 0.86
        case "cs2": 0.90
        default: 0.68
        }
        let heightRatio: CGFloat = switch appID {
        case "finder": 0.78
        case "zen": 0.82
        case "spotify": 0.84
        case "settings": 0.86
        case "geforcenow": 0.88
        case "cs2": 0.92
        default: 0.74
        }

        let availableHeight = screenSize.height - taskbarReservedHeight
        let width = min(screenSize.width * widthRatio, screenSize.width - 80)
        let height = min(availableHeight * heightRatio, availableHeight - 40)
        let size = CGSize(width: max(width, 420), height: max(height, 320))

        // Centro esatto tra i due bordi laterali, e tra il bordo alto e la taskbar
        let center = CGPoint(x: screenSize.width / 2, y: availableHeight / 2)
        return (size, center)
    }

    func openApp(_ app: AppItem) {
        // Aggiunge alla taskbar se non pinnata e non già presente
        if !taskbarApps.contains(where: { $0.id == app.id }) {
            withAnimation(.spring(duration: 0.3, bounce: 0.2)) {
                taskbarApps.append(app)
            }
        }

        if let idx = openWindows.firstIndex(where: { $0.appID == app.id }) {
            withAnimation(.spring(duration: 0.38, bounce: 0.12)) {
                openWindows[idx].isMinimized = false
                appStates[app.id] = openWindows[idx]
            }
            bringToFront(openWindows[idx].id)
        } else {
            var win = appStates[app.id] ?? {
                let (size, position) = defaultWindowFrame(for: app.id)
                return DesktopWindow(
                    appID: app.id, title: app.name, icon: app.icon, iconAsset: app.iconAsset,
                    position: position, size: size
                )
            }()
            win.id = UUID()
            win.isMinimized = false
            openWindows.append(win)
            activeWindowID = win.id
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { self.syncTaskbarVisibility() }
        }
    }

    func closeApp(_ appID: String) {
        if let window = openWindows.first(where: { $0.appID == appID }) {
            closeWindow(window.id)
        }
    }

    func minimizeWindow(_ id: UUID) {
        if let idx = openWindows.firstIndex(where: { $0.id == id }) {
            withAnimation(.spring(duration: 0.38, bounce: 0.12)) {
                openWindows[idx].isMinimized = true
                appStates[openWindows[idx].appID] = openWindows[idx]
            }
            activeWindowID = openWindows.last(where: { !$0.isMinimized })?.id
            syncTaskbarVisibility()
        }
    }

    func closeWindow(_ id: UUID) {
        // Se l'app non è pinnata, toglila dalla taskbar alla chiusura
        if let window = openWindows.first(where: { $0.id == id }),
           let app = allApps.first(where: { $0.id == window.appID }),
           !app.isPinned {
            withAnimation(.spring(duration: 0.3, bounce: 0.1)) {
                taskbarApps.removeAll { $0.id == app.id }
            }
        }
        snappedWindowZones.removeValue(forKey: id)
        openWindows.removeAll { $0.id == id }
        activeWindowID = openWindows.last(where: { !$0.isMinimized })?.id ?? openWindows.last?.id
        syncTaskbarVisibility()
    }

    func setMaximized(_ id: UUID, value: Bool) {
        if let idx = openWindows.firstIndex(where: { $0.id == id }) {
            openWindows[idx].isMaximized = value
            appStates[openWindows[idx].appID] = openWindows[idx]
            if !value { snappedWindowZones.removeValue(forKey: id) }
            syncTaskbarVisibility()
        }
    }

    func bringToFront(_ id: UUID) {
        guard let idx = openWindows.firstIndex(where: { $0.id == id }) else { return }
        let win = openWindows.remove(at: idx)
        openWindows.append(win)
        activeWindowID = id
    }

    func updateWindow(_ id: UUID, position: CGPoint, size: CGSize) {
        if let idx = openWindows.firstIndex(where: { $0.id == id }) {
            openWindows[idx].position = position
            openWindows[idx].size = size
            appStates[openWindows[idx].appID] = openWindows[idx]
        }
    }

    func syncTaskbarVisibility() {
        if taskbarAlwaysVisible || taskbarPinned {
            taskbarVisible = true
            return
        }
        let shouldHide = openWindows.contains { w in
            guard !w.isMinimized else { return false }
            if w.isMaximized { return true }
            if let z = snappedWindowZones[w.id], z.hidesTaskbar { return true }
            return false
        }
        withAnimation(.spring(duration: 0.4, bounce: 0.08)) { taskbarVisible = !shouldHide }
    }

    func restart(authVM: AuthViewModel) {
        withAnimation(.spring(duration: 0.4, bounce: 0.05)) {
            openWindows.removeAll()
            snappedWindowZones.removeAll()
            taskbarApps = AppItem.defaults
            showStartMenu = false
            taskbarPinned = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { authVM.logout() }
    }

    func shutdown() { exit(0) }

    func resetWindowLayout() {
        withAnimation(.spring(duration: 0.35, bounce: 0.05)) {
            openWindows.removeAll()
            snappedWindowZones.removeAll()
            appStates.removeAll()
            activeWindowID = nil
        }
        UserDefaults.standard.removeObject(forKey: "savedWindows")
        UserDefaults.standard.removeObject(forKey: "savedAppStates")
        UserDefaults.standard.removeObject(forKey: "activeWindowID")
        syncTaskbarVisibility()
    }
}