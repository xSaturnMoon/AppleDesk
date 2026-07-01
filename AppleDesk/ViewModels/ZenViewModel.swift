import SwiftUI
import WebKit

// MARK: - Tab
@MainActor
final class ZenTabModel: ObservableObject, Identifiable, Equatable {
    let id: UUID
    @Published var title: String = "Nuova scheda"
    @Published var urlText: String = ""
    @Published var loadedURL: URL?
    @Published var canGoBack = false
    @Published var canGoForward = false
    @Published var isLoading = false
    @Published var isPinned = false

    let webView: WKWebView
    let isPrivate: Bool

    init(id: UUID = UUID(), isPrivate: Bool = false) {
        self.id = id
        self.isPrivate = isPrivate

        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        config.allowsPictureInPictureMediaPlayback = true
        config.userContentController.add(ZenGlanceScriptHandler.shared, name: "zenGlance")

        let prefs = WKWebpagePreferences()
        prefs.preferredContentMode = .desktop
        prefs.allowsContentJavaScript = true
        config.defaultWebpagePreferences = prefs

        if isPrivate {
            config.websiteDataStore = .nonPersistent()
        }

        if #available(iOS 15.4, *) {
            config.preferences.isElementFullscreenEnabled = true
        }

        self.webView = WKWebView(frame: .zero, configuration: config)
        self.webView.allowsBackForwardNavigationGestures = true
        self.webView.customUserAgent =
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 14_5) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Safari/605.1.15"
    }

    nonisolated static func == (lhs: ZenTabModel, rhs: ZenTabModel) -> Bool { lhs.id == rhs.id }
}

// MARK: - Workspace
@MainActor
final class ZenWorkspace: ObservableObject, Identifiable {
    let id: UUID
    @Published var name: String
    @Published var symbol: String
    @Published var tabs: [ZenTabModel]
    @Published var activeTabID: UUID?

    init(id: UUID = UUID(), name: String, symbol: String, tabs: [ZenTabModel] = [], activeTabID: UUID? = nil) {
        self.id = id
        self.name = name
        self.symbol = symbol
        self.tabs = tabs
        self.activeTabID = activeTabID
    }

    var activeTab: ZenTabModel? { tabs.first { $0.id == activeTabID } ?? tabs.first }

    var pinnedTabs: [ZenTabModel] { tabs.filter(\.isPinned) }
    var unpinnedTabs: [ZenTabModel] { tabs.filter { !$0.isPinned } }

    func snapshot() -> ZenWorkspaceSnapshot {
        ZenWorkspaceSnapshot(
            id: id,
            name: name,
            symbol: symbol,
            tabSnapshots: tabs.map {
                ZenTabSnapshot(
                    id: $0.id,
                    title: $0.title,
                    urlText: $0.urlText,
                    loadedURLString: $0.loadedURL?.absoluteString
                )
            },
            activeTabID: activeTabID,
            pinnedTabIDs: tabs.filter(\.isPinned).map(\.id)
        )
    }
}

// MARK: - Glance script bridge
@MainActor
final class ZenGlanceScriptHandler: NSObject, WKScriptMessageHandler {
    static let shared = ZenGlanceScriptHandler()
    var onGlanceURL: ((URL) -> Void)?

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "zenGlance",
              let urlString = message.body as? String,
              let url = URL(string: urlString) else { return }
        onGlanceURL?(url)
    }
}

// MARK: - ViewModel
@MainActor
final class ZenViewModel: ObservableObject {
    @Published var workspaces: [ZenWorkspace] = []
    @Published var activeWorkspaceID: UUID?
    @Published var sidebarCollapsed = false
    @Published var compactMode = false
    @Published var toolbarVisible = true
    @Published var theme: ZenTheme = .midnight {
        didSet { persistSettings() }
    }
    @Published var searchEngine = "Google" {
        didSet { persistSettings() }
    }
    @Published var zoomLevel: Double = 1.0 {
        didSet {
            UserDefaults.standard.set(zoomLevel, forKey: "zen_zoom")
            applyZoomToAllTabs()
        }
    }
    @Published var history: [String] = []
    @Published var shortcuts: [ZenShortcut] = [] {
        didSet { persistShortcuts() }
    }
    @Published var boosts = ZenBoostSettings() {
        didSet { persistSettings() }
    }
    @Published var splitLayout: ZenSplitLayout = .single {
        didSet { syncSplitTabs() }
    }
    @Published var splitTabIDs: [UUID] = []
    @Published var focusedSplitTabID: UUID?
    @Published var glanceURL: URL?
    @Published var showGlance = false
    @Published var isPrivateSession = false {
        didSet { persistSettings() }
    }
    @Published var showSettings = false
    @Published var showHistory = false
    @Published var showNewWorkspacePrompt = false
    @Published var newWorkspaceName = ""

    var activeWorkspace: ZenWorkspace? {
        workspaces.first { $0.id == activeWorkspaceID } ?? workspaces.first
    }

    var focusedTab: ZenTabModel? {
        if let id = focusedSplitTabID ?? activeWorkspace?.activeTabID {
            return activeWorkspace?.tabs.first { $0.id == id } ?? activeWorkspace?.activeTab
        }
        return activeWorkspace?.activeTab
    }

    init() {
        let savedZoom = UserDefaults.standard.double(forKey: "zen_zoom")
        zoomLevel = savedZoom == 0 ? 1.0 : savedZoom
        loadPersistedState()
        setupGlanceHandler()
        if workspaces.isEmpty { createDefaultWorkspaces() }
        if activeWorkspaceID == nil { activeWorkspaceID = workspaces.first?.id }
        ensureActiveTab()
    }

    // MARK: - Workspaces

    func createDefaultWorkspaces() {
        workspaces = ZenWorkspaceTemplate.defaults.map { template in
            let tab = makeTab()
            return ZenWorkspace(id: template.id, name: template.name, symbol: template.symbol, tabs: [tab], activeTabID: tab.id)
        }
    }

    func switchWorkspace(_ id: UUID) {
        activeWorkspaceID = id
        splitLayout = .single
        splitTabIDs = []
        ensureActiveTab()
        persistWorkspaces()
    }

    func addWorkspace() {
        let name = newWorkspaceName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        let tab = makeTab()
        let ws = ZenWorkspace(name: name, symbol: "square.grid.2x2.fill", tabs: [tab], activeTabID: tab.id)
        workspaces.append(ws)
        activeWorkspaceID = ws.id
        newWorkspaceName = ""
        showNewWorkspacePrompt = false
        persistWorkspaces()
    }

    // MARK: - Tabs

    func makeTab() -> ZenTabModel {
        ZenTabModel(isPrivate: isPrivateSession)
    }

    func addTab() {
        guard let ws = activeWorkspace else { return }
        let tab = makeTab()
        ws.tabs.append(tab)
        ws.activeTabID = tab.id
        syncSplitTabs()
        persistWorkspaces()
    }

    func closeTab(_ id: UUID) {
        guard let ws = activeWorkspace else { return }
        guard ws.tabs.count > 1 else { return }
        ws.tabs.removeAll { $0.id == id }
        if ws.activeTabID == id { ws.activeTabID = ws.tabs.last?.id }
        splitTabIDs.removeAll { $0 == id }
        if splitTabIDs.isEmpty && splitLayout != .single { splitLayout = .single }
        syncSplitTabs()
        persistWorkspaces()
    }

    func selectTab(_ id: UUID) {
        activeWorkspace?.activeTabID = id
        focusedSplitTabID = id
        syncSplitTabs()
    }

    func togglePin(_ tab: ZenTabModel) {
        tab.isPinned.toggle()
        persistWorkspaces()
    }

    func ensureActiveTab() {
        guard let ws = activeWorkspace else { return }
        if ws.tabs.isEmpty {
            let tab = makeTab()
            ws.tabs = [tab]
            ws.activeTabID = tab.id
        } else if ws.activeTabID == nil || !ws.tabs.contains(where: { $0.id == ws.activeTabID }) {
            ws.activeTabID = ws.tabs.first?.id
        }
        focusedSplitTabID = ws.activeTabID
    }

    // MARK: - Split View

    func setSplitLayout(_ layout: ZenSplitLayout) {
        splitLayout = layout
        syncSplitTabs()
    }

    func syncSplitTabs() {
        guard let ws = activeWorkspace else { return }
        let count = splitLayout.panelCount
        guard count > 1 else {
            splitTabIDs = []
            focusedSplitTabID = ws.activeTabID
            return
        }

        var ids: [UUID] = []
        if let active = ws.activeTabID { ids.append(active) }
        for tab in ws.tabs where !ids.contains(tab.id) {
            ids.append(tab.id)
            if ids.count >= count { break }
        }
        while ids.count < count {
            let tab = makeTab()
            ws.tabs.append(tab)
            ids.append(tab.id)
        }
        splitTabIDs = Array(ids.prefix(count))
        focusedSplitTabID = splitTabIDs.first
        persistWorkspaces()
    }

    func tabsInSplit() -> [ZenTabModel] {
        guard let ws = activeWorkspace else { return [] }
        if splitLayout == .single {
            return ws.activeTab.map { [$0] } ?? []
        }
        return splitTabIDs.compactMap { id in ws.tabs.first { $0.id == id } }
    }

    // MARK: - Navigation

    func loadURL(_ urlString: String, on tab: ZenTabModel? = nil) {
        let target = tab ?? focusedTab ?? activeWorkspace?.activeTab
        guard let target else { return }

        let text = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        let resolved: URL
        if text.hasPrefix("http://") || text.hasPrefix("https://") {
            resolved = URL(string: text) ?? URL(string: "https://duckduckgo.com")!
        } else if text.contains(".") && !text.contains(" ") {
            resolved = URL(string: "https://\(text)") ?? URL(string: "https://duckduckgo.com")!
        } else {
            let enc = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            switch searchEngine {
            case "DuckDuckGo": resolved = URL(string: "https://duckduckgo.com/?q=\(enc)")!
            case "Bing":        resolved = URL(string: "https://www.bing.com/search?q=\(enc)")!
            default:            resolved = URL(string: "https://www.google.com/search?q=\(enc)")!
            }
        }

        target.loadedURL = resolved
        target.urlText = resolved.absoluteString
        target.title = resolved.host ?? "Sito web"
        addToHistory(resolved.absoluteString)
        persistWorkspaces()
    }

    func goHome(on tab: ZenTabModel? = nil) {
        let target = tab ?? focusedTab
        target?.loadedURL = nil
        target?.urlText = ""
        target?.title = "Nuova scheda"
        persistWorkspaces()
    }

    func reloadActive() {
        guard let tab = focusedTab else { return }
        if let url = tab.loadedURL {
            let u = url
            tab.loadedURL = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { tab.loadedURL = u }
        }
    }

    func addToHistory(_ url: String) {
        guard !isPrivateSession else { return }
        if history.first != url {
            history.insert(url, at: 0)
            if history.count > 100 { history.removeLast() }
            UserDefaults.standard.set(history, forKey: "zen_history")
        }
    }

    // MARK: - Bookmarks

    func toggleBookmark(urlStr: String, name: String) {
        var u = urlStr.trimmingCharacters(in: .whitespacesAndNewlines)
        if !u.hasPrefix("http") { u = "https://" + u }
        let norm: (String) -> String = {
            $0.replacingOccurrences(of: "https://", with: "")
                .replacingOccurrences(of: "http://", with: "")
                .trimmingCharacters(in: .init(charactersIn: "/"))
                .lowercased()
        }
        if let i = shortcuts.firstIndex(where: { norm($0.url) == norm(u) }) {
            shortcuts.remove(at: i)
        } else {
            shortcuts.append(ZenShortcut(name: name.isEmpty ? (URL(string: u)?.host ?? "Sito") : name, url: u))
        }
    }

    func isBookmarked(urlStr: String) -> Bool {
        var u = urlStr.trimmingCharacters(in: .whitespacesAndNewlines)
        if !u.hasPrefix("http") { u = "https://" + u }
        let norm: (String) -> String = {
            $0.replacingOccurrences(of: "https://", with: "")
                .replacingOccurrences(of: "http://", with: "")
                .trimmingCharacters(in: .init(charactersIn: "/"))
                .lowercased()
        }
        return shortcuts.contains { norm($0.url) == norm(u) }
    }

    // MARK: - Glance

    func openGlance(url: URL) {
        glanceURL = url
        showGlance = true
    }

    func closeGlance() {
        showGlance = false
        glanceURL = nil
    }

    func promoteGlanceToTab() {
        guard let url = glanceURL else { return }
        loadURL(url.absoluteString)
        closeGlance()
    }

    private func setupGlanceHandler() {
        ZenGlanceScriptHandler.shared.onGlanceURL = { [weak self] url in
            self?.openGlance(url: url)
        }
    }

    // MARK: - Boosts

    func boostScript() -> String {
        var parts: [String] = []
        if boosts.forceDarkMode {
            parts.append("""
            (function(){
              var s=document.getElementById('zen-boost-dark');
              if(!s){s=document.createElement('style');s.id='zen-boost-dark';
              s.textContent='html,body{background:#111!important;color:#eee!important}\
              a{color:#8ab4f8!important}img,video{opacity:.92}';document.head.appendChild(s);}
            })();
            """)
        }
        if boosts.largerText {
            parts.append("document.documentElement.style.fontSize='112%';")
        }
        if boosts.blockTrackers {
            parts.append("""
            (function(){var b=['doubleclick.net','googlesyndication.com','facebook.net/tr'];
            document.querySelectorAll('script[src]').forEach(function(s){
              if(b.some(function(x){return s.src.indexOf(x)>-1}))s.remove();});})();
            """)
        }
        return parts.joined(separator: "\n")
    }

    func applyBoosts(to webView: WKWebView) {
        webView.evaluateJavaScript(boostScript())
    }

    func applyZoom(to webView: WKWebView) {
        webView.evaluateJavaScript("document.body.style.zoom = '\(zoomLevel)'")
    }

    private func applyZoomToAllTabs() {
        for ws in workspaces {
            for tab in ws.tabs {
                applyZoom(to: tab.webView)
            }
        }
    }

    // MARK: - Compact mode

    func toggleCompactMode() {
        withAnimation(.spring(duration: 0.35, bounce: 0.12)) {
            compactMode.toggle()
            if compactMode {
                sidebarCollapsed = true
                toolbarVisible = false
            } else {
                sidebarCollapsed = false
                toolbarVisible = true
            }
        }
    }

    func revealUIInCompact() {
        guard compactMode else { return }
        withAnimation(.spring(duration: 0.3, bounce: 0.1)) {
            toolbarVisible.toggle()
        }
    }

    // MARK: - Persistence

    private func persistWorkspaces() {
        let snapshots = workspaces.map { $0.snapshot() }
        if let data = try? JSONEncoder().encode(snapshots) {
            UserDefaults.standard.set(data, forKey: "zen_workspaces")
        }
        if let id = activeWorkspaceID {
            UserDefaults.standard.set(id.uuidString, forKey: "zen_active_workspace")
        }
    }

    private func persistShortcuts() {
        if let data = try? JSONEncoder().encode(shortcuts) {
            UserDefaults.standard.set(data, forKey: "zen_shortcuts")
        }
    }

    private func persistSettings() {
        UserDefaults.standard.set(theme.rawValue, forKey: "zen_theme")
        UserDefaults.standard.set(searchEngine, forKey: "zen_search_engine")
        UserDefaults.standard.set(isPrivateSession, forKey: "zen_private")
        if let data = try? JSONEncoder().encode(boosts) {
            UserDefaults.standard.set(data, forKey: "zen_boosts")
        }
    }

    private func loadPersistedState() {
        if let data = UserDefaults.standard.data(forKey: "zen_shortcuts"),
           let saved = try? JSONDecoder().decode([ZenShortcut].self, from: data) {
            shortcuts = saved
        } else {
            shortcuts = [
                ZenShortcut(name: "DuckDuckGo", url: "https://duckduckgo.com"),
                ZenShortcut(name: "YouTube", url: "https://www.youtube.com"),
                ZenShortcut(name: "GitHub", url: "https://github.com"),
                ZenShortcut(name: "Wikipedia", url: "https://www.wikipedia.org"),
                ZenShortcut(name: "Reddit", url: "https://www.reddit.com"),
            ]
        }

        if let raw = UserDefaults.standard.string(forKey: "zen_theme"),
           let t = ZenTheme(rawValue: raw) { theme = t }
        if let engine = UserDefaults.standard.string(forKey: "zen_search_engine") { searchEngine = engine }
        isPrivateSession = UserDefaults.standard.bool(forKey: "zen_private")
        history = UserDefaults.standard.stringArray(forKey: "zen_history") ?? []
        if let data = UserDefaults.standard.data(forKey: "zen_boosts"),
           let saved = try? JSONDecoder().decode(ZenBoostSettings.self, from: data) {
            boosts = saved
        }

        if let data = UserDefaults.standard.data(forKey: "zen_workspaces"),
           let snapshots = try? JSONDecoder().decode([ZenWorkspaceSnapshot].self, from: data),
           !snapshots.isEmpty {
            workspaces = snapshots.map { snap in
                let tabs = snap.tabSnapshots.map { ts -> ZenTabModel in
                    let tab = ZenTabModel(id: ts.id, isPrivate: isPrivateSession)
                    tab.title = ts.title
                    tab.urlText = ts.urlText
                    if let s = ts.loadedURLString { tab.loadedURL = URL(string: s) }
                    tab.isPinned = snap.pinnedTabIDs.contains(ts.id)
                    return tab
                }
                return ZenWorkspace(id: snap.id, name: snap.name, symbol: snap.symbol, tabs: tabs, activeTabID: snap.activeTabID)
            }
            if let idStr = UserDefaults.standard.string(forKey: "zen_active_workspace"),
               let id = UUID(uuidString: idStr) {
                activeWorkspaceID = id
            }
        }
    }
}
