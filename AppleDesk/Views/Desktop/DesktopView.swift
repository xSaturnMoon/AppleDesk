import SwiftUI
import UIKit

// MARK: - Option Key Handler
extension UIResponder {
    private static weak var _stored: UIResponder?
    static var currentFirstResponder: UIResponder? {
        _stored = nil
        UIApplication.shared.sendAction(#selector(storeFirstResponder(_:)), to: nil, from: nil, for: nil)
        return _stored
    }
    @objc private func storeFirstResponder(_ sender: Any) { UIResponder._stored = self }
}

class MenuKeyView: UIView {
    var onOptionKey: (() -> Void)?
    private var timer: Timer?

    override var canBecomeFirstResponder: Bool { true }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        becomeFirstResponder()
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                guard let self, !self.isFirstResponder else { return }
                let cur = UIResponder.currentFirstResponder
                let cls = String(describing: type(of: cur as AnyObject))
                guard !(cur is UITextField), !(cur is UITextView),
                      !cls.contains("WKContent"), !cls.contains("WKWebView") else { return }
                self.becomeFirstResponder()
            }
        }
    }

    override func removeFromSuperview() {
        timer?.invalidate(); timer = nil
        super.removeFromSuperview()
    }

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        var handled = false
        for press in presses {
            guard let key = press.key else { continue }
            let isMenuKey = key.keyCode == .keyboardLeftAlt
                || key.keyCode == .keyboardRightAlt
                || key.keyCode == .keyboardLeftGUI
                || key.keyCode == .keyboardRightGUI
            if isMenuKey {
                onOptionKey?()
                handled = true
            }
        }
        if !handled { super.pressesBegan(presses, with: event) }
    }
}

struct MenuKeyHandler: UIViewRepresentable {
    let action: () -> Void
    func makeUIView(context: Context) -> MenuKeyView {
        let v = MenuKeyView()
        v.onOptionKey = action
        DispatchQueue.main.async { v.becomeFirstResponder() }
        return v
    }
    func updateUIView(_ v: MenuKeyView, context: Context) { v.onOptionKey = action }
}

// MARK: - Desktop View
struct DesktopView: View {
    @EnvironmentObject var desktopVM: DesktopViewModel
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var weatherService: WeatherService
    @EnvironmentObject var batteryService: BatteryService
    @EnvironmentObject var spotifyVM: SpotifyViewModel

    var body: some View {
        GeometryReader { geo in
            let screenSize = geo.size
            ZStack {
                DesktopWallpaper()

                // Finestre aperte (anche minimizzate restano montate per preservare lo stato)
                ForEach(desktopVM.openWindows) { window in
                    let isMinimized = window.isMinimized
                    WindowView(window: window, screenSize: screenSize)
                        .environmentObject(desktopVM)
                        .scaleEffect(isMinimized ? 0.82 : 1, anchor: .bottom)
                        .opacity(isMinimized ? 0 : 1)
                        .offset(y: isMinimized ? 80 : 0)
                        .allowsHitTesting(!isMinimized)
                        .zIndex(
                            isMinimized
                                ? 1
                                : Double(desktopVM.openWindows.firstIndex(where: { $0.id == window.id }) ?? 0) + 10
                        )
                        .animation(.spring(response: 0.38, dampingFraction: 0.84), value: isMinimized)
                }

                // Option key handler
                MenuKeyHandler { desktopVM.toggleStartMenu() }
                    .frame(width: 0, height: 0)
                    .allowsHitTesting(false)

                // Snap preview
                if let snap = desktopVM.snapPreview {
                    let frame = snap.previewFrame(for: screenSize)
                    RoundedRectangle(cornerRadius: snap.cornerRadius, style: .continuous)
                        .fill(.white.opacity(0.07))
                        .overlay(
                            RoundedRectangle(cornerRadius: snap.cornerRadius, style: .continuous)
                                .stroke(.white.opacity(0.28), lineWidth: 1.5)
                        )
                        .frame(width: frame.width, height: frame.height)
                        .position(x: frame.midX, y: frame.midY)
                        .allowsHitTesting(false)
                        .animation(.spring(duration: 0.18, bounce: 0.05), value: snap)
                        .zIndex(150)
                }

                // Taskbar + Start Menu
                VStack {
                    Spacer()
                    if desktopVM.showStartMenu {
                        StartMenuView()
                            .environmentObject(desktopVM)
                            .environmentObject(authVM)
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .scale(scale: 0.95, anchor: .bottom)),
                                removal: .opacity.combined(with: .scale(scale: 0.95, anchor: .bottom))
                            ))
                            .padding(.bottom, 12)
                            .zIndex(300)
                    }
                    if desktopVM.taskbarVisible {
                        TaskbarView()
                            .environmentObject(desktopVM)
                            .environmentObject(authVM)
                            .environmentObject(weatherService)
                            .environmentObject(batteryService)
                            .environmentObject(spotifyVM)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .padding(.bottom, 16)
                            .zIndex(200)
                            .onHover { hovering in
                                if hovering {
                                    desktopVM.cancelAutoHide()
                                } else {
                                    desktopVM.hideTaskbarIfNeeded()
                                }
                            }
                    }
                }
                .animation(.spring(duration: 0.4, bounce: 0.08), value: desktopVM.showStartMenu)
                .animation(.spring(duration: 0.35, bounce: 0.05), value: desktopVM.taskbarVisible)
                .zIndex(100)
            }
            .onTapGesture {
                if desktopVM.showStartMenu {
                    withAnimation(.spring(duration: 0.35, bounce: 0.1)) {
                        desktopVM.showStartMenu = false
                        desktopVM.taskbarPinned = false
                        desktopVM.hideTaskbarIfNeeded()
                    }
                }
            }
            // Tiene aggiornata la dimensione schermo nel ViewModel (per centrare le nuove finestre)
            .onAppear {
                desktopVM.screenSize = screenSize
            }
            .onChange(of: screenSize) { _, newSize in
                desktopVM.screenSize = newSize
                HoverCoordinator.shared.screenHeight = newSize.height
            }
            // Hover in basso: UIHoverGestureRecognizer sulla UIWindow
            .onAppear {
                installWindowHoverDetector(screenHeight: screenSize.height)
            }
            .onChange(of: screenSize.height) { _, h in
                HoverCoordinator.shared.screenHeight = h
            }
        }
        .ignoresSafeArea()
    }

    private func installWindowHoverDetector(screenHeight: CGFloat) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = scene.windows.first else { return }

            // Rimuovi eventuali detector precedenti
            window.gestureRecognizers?
                .filter { $0 is UIHoverGestureRecognizer && ($0.name == "AppleDeskHover") }
                .forEach { window.removeGestureRecognizer($0) }

            let hover = UIHoverGestureRecognizer(
                target: HoverCoordinator.shared,
                action: #selector(HoverCoordinator.handleHover(_:))
            )
            hover.name = "AppleDeskHover"
            HoverCoordinator.shared.screenHeight = screenHeight
            HoverCoordinator.shared.onTrigger = { desktopVM.showTaskbar() }
            HoverCoordinator.shared.onLeaveEdge = {
                desktopVM.cancelAutoHide()
                desktopVM.hideTaskbarIfNeeded()
            }
            window.addGestureRecognizer(hover)
        }
    }
}

// Coordinator globale per l'hover — vive fuori dalla view
// @unchecked Sendable perché tutte le sue operazioni avvengono sul main thread
class HoverCoordinator: NSObject, @unchecked Sendable {
    static let shared = HoverCoordinator()

    /// Pixel dal bordo inferiore: il cursore deve restare qui 0.4s per rivelare la taskbar.
    private let revealThreshold: CGFloat = 28
    /// Zona più ampia (taskbar + padding): uscendo da qui la taskbar si nasconde di nuovo.
    private let keepVisibleThreshold: CGFloat = 100
    /// Tempo di permanenza sul bordo prima di mostrare la taskbar.
    private let dwellDuration: TimeInterval = 0.4

    var screenHeight: CGFloat = 0
    var onTrigger: (() -> Void)?   // chiamato sempre su DispatchQueue.main
    var onLeaveEdge: (() -> Void)?
    private var hoverTimer: Timer?
    private var wasInKeepZone = false

    // UIHoverGestureRecognizer chiama SEMPRE sul main thread — usiamo assumeIsolated per location(in:)
    @objc func handleHover(_ g: UIHoverGestureRecognizer) {
        let y = MainActor.assumeIsolated { g.location(in: nil).y }
        let inRevealZone = y > screenHeight - revealThreshold
        let inKeepZone = y > screenHeight - keepVisibleThreshold

        if inRevealZone {
            guard hoverTimer == nil else { return }
            nonisolated(unsafe) let cb = onTrigger
            hoverTimer = Timer.scheduledTimer(withTimeInterval: dwellDuration, repeats: false) { [weak self] _ in
                self?.hoverTimer = nil
                DispatchQueue.main.async { cb?() }
            }
        } else {
            hoverTimer?.invalidate()
            hoverTimer = nil
        }

        if inKeepZone {
            wasInKeepZone = true
        } else if wasInKeepZone {
            wasInKeepZone = false
            nonisolated(unsafe) let leave = onLeaveEdge
            DispatchQueue.main.async { leave?() }
        }
    }
}

// MARK: - Start Menu
struct StartMenuView: View {
    @EnvironmentObject var desktopVM: DesktopViewModel
    @EnvironmentObject var authVM: AuthViewModel
    @State private var query = ""
    @FocusState private var searchFocused: Bool

    var results: [AppItem] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return [] }
        return desktopVM.allApps.filter { $0.name.lowercased().contains(q) }
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                Image(systemName: "applelogo")
                    .font(.system(size: 36, weight: .ultraLight))
                    .foregroundStyle(.white.opacity(0.75))
                Text("Ciao, \(authVM.username)")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
            }
            .padding(.top, 28)
            .padding(.bottom, 20)

            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.45))
                TextField("Cerca app...", text: $query)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(.white)
                    .tint(.white)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .focused($searchFocused)
                if !query.isEmpty {
                    Button { query = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.white.opacity(0.4))
                    }.buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 11)
            .background(Color.white.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.12), lineWidth: 0.8))
            .padding(.horizontal, 24)

            if !results.isEmpty {
                VStack(spacing: 2) {
                    ForEach(results) { app in
                        Button {
                            withAnimation(.spring(duration: 0.3, bounce: 0.2)) {
                                desktopVM.openApp(app)
                                desktopVM.toggleStartMenu()
                            }
                        } label: {
                            HStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill(Color.white.opacity(0.1))
                                        .frame(width: 34, height: 34)
                                    if let asset = app.iconAsset {
                                        Image(asset)
                                            .resizable().scaledToFit()
                                            .frame(width: 26, height: 26)
                                    } else {
                                        Image(systemName: app.icon)
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundStyle(app.color == .clear ? .white : app.color)
                                    }
                                }
                                Text(app.name)
                                    .font(.system(size: 15, weight: .medium, design: .rounded))
                                    .foregroundStyle(.white)
                                Spacer()
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(.white.opacity(0.3))
                            }
                            .padding(.horizontal, 14).padding(.vertical, 10)
                            .background(Color.white.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 24).padding(.top, 14)
            } else if !query.isEmpty {
                Text("Nessuna app trovata")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.35))
                    .padding(.top, 20)
            }

            Spacer()

            Divider().background(.white.opacity(0.1)).padding(.horizontal, 24)

            HStack(spacing: 0) {
                Button {
                    desktopVM.toggleStartMenu()
                    desktopVM.restart(authVM: authVM)
                } label: {
                    HStack(spacing: 7) {
                        Image(systemName: "arrow.counterclockwise").font(.system(size: 13))
                        Text("Riavvia").font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(.white.opacity(0.65))
                    .frame(maxWidth: .infinity).padding(.vertical, 16)
                }.buttonStyle(.plain)

                Divider().frame(height: 20).background(.white.opacity(0.15))

                Button { desktopVM.shutdown() } label: {
                    HStack(spacing: 7) {
                        Image(systemName: "power").font(.system(size: 13))
                        Text("Spegni").font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(.red.opacity(0.75))
                    .frame(maxWidth: .infinity).padding(.vertical, 16)
                }.buttonStyle(.plain)
            }
        }
        .frame(width: 380, height: 460)
        .background(.ultraThinMaterial)
        .environment(\.colorScheme, .dark)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.3), radius: 40, y: 20)
        .focusable()
        .onKeyPress(.escape) {
            guard desktopVM.showStartMenu else { return .ignored }
            desktopVM.toggleStartMenu()
            return .handled
        }
    }
}