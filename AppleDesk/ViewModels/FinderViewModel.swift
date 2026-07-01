import SwiftUI
import Combine

@MainActor
final class FinderViewModel: ObservableObject {

    @Published var currentURL: URL = FinderService.rootURL
    @Published var items: [FinderItem] = []
    @Published var viewMode: FinderViewMode = .icons
    @Published var selection: Set<String> = []
    @Published var searchText: String = ""

    // Navigazione avanti/indietro
    @Published private(set) var canGoBack = false
    @Published private(set) var canGoForward = false
    private var backStack: [URL] = []
    private var forwardStack: [URL] = []

    // Colonne stile macOS (Miller columns)
    @Published var columnPath: [URL] = []
    @Published var columnItems: [[FinderItem]] = []

    // UI state
    @Published var showNewFolderPrompt = false
    @Published var newFolderName = "senza titolo"
    @Published var renamingItem: FinderItem?
    @Published var renameText = ""
    @Published var itemPendingDelete: FinderItem?
    @Published var showDeleteConfirm = false
    @Published var errorMessage: String?

    init() {
        FinderService.setupFolderStructureIfNeeded()
        reload()
    }

    var filteredItems: [FinderItem] {
        let trimmed = searchText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return items }
        return items.filter { $0.name.localizedCaseInsensitiveContains(trimmed) }
    }

    var currentTitle: String {
        currentURL.path == FinderService.rootURL.path ? "AppleDesk" : currentURL.lastPathComponent
    }

    var breadcrumb: [(name: String, url: URL)] {
        columnPath.map { url in
            let name = url.path == FinderService.rootURL.path ? "AppleDesk" : url.lastPathComponent
            return (name, url)
        }
    }

    // MARK: - Navigazione

    func navigate(to url: URL, pushHistory: Bool = true) {
        guard url.path != currentURL.path else { return }
        if pushHistory {
            backStack.append(currentURL)
            forwardStack.removeAll()
        }
        currentURL = url
        selection.removeAll()
        updateNavFlags()
        reload()
    }

    func goBack() {
        guard let previous = backStack.popLast() else { return }
        forwardStack.append(currentURL)
        currentURL = previous
        selection.removeAll()
        updateNavFlags()
        reload()
    }

    func goForward() {
        guard let next = forwardStack.popLast() else { return }
        backStack.append(currentURL)
        currentURL = next
        selection.removeAll()
        updateNavFlags()
        reload()
    }

    func goUp() {
        guard currentURL.path != FinderService.rootURL.path else { return }
        navigate(to: currentURL.deletingLastPathComponent())
    }

    private func updateNavFlags() {
        canGoBack = !backStack.isEmpty
        canGoForward = !forwardStack.isEmpty
    }

    // MARK: - Ricarica

    func reload() {
        items = FinderService.contents(of: currentURL)
        rebuildColumns()
    }

    private func rebuildColumns() {
        // colonna 0 = root, poi una colonna per ogni livello fino a currentURL
        var chain: [URL] = [FinderService.rootURL]
        if currentURL.path != FinderService.rootURL.path {
            let rootPath = FinderService.rootURL.path
            let relative = currentURL.path.hasPrefix(rootPath) ? String(currentURL.path.dropFirst(rootPath.count)) : currentURL.path
            let comps = relative.split(separator: "/").map(String.init)
            var running = FinderService.rootURL
            for c in comps {
                running = running.appendingPathComponent(c, isDirectory: true)
                chain.append(running)
            }
        }
        columnPath = chain
        columnItems = chain.map { FinderService.contents(of: $0) }
    }

    func selectInColumn(_ item: FinderItem) {
        if item.isDirectory {
            navigate(to: item.url)
        } else {
            selection = [item.id]
        }
    }

    // MARK: - Selezione

    func handleDoubleTap(_ item: FinderItem) {
        guard item.isDirectory else { return }
        navigate(to: item.url)
    }

    func toggleSelection(_ item: FinderItem) {
        if selection.contains(item.id) {
            selection.remove(item.id)
        } else {
            selection = [item.id]
        }
    }

    // MARK: - Operazioni CRUD reali

    func createFolder() {
        do {
            let url = try FinderService.createFolder(named: newFolderName, in: currentURL)
            reload()
            selection = [url.path]
        } catch {
            errorMessage = error.localizedDescription
        }
        newFolderName = "senza titolo"
    }

    func beginRename(_ item: FinderItem) {
        renamingItem = item
        renameText = item.name
    }

    func confirmRename() {
        guard let item = renamingItem else { return }
        do {
            _ = try FinderService.rename(item, to: renameText)
            reload()
        } catch {
            errorMessage = error.localizedDescription
        }
        renamingItem = nil
    }

    func requestDelete(_ item: FinderItem) {
        itemPendingDelete = item
        showDeleteConfirm = true
    }

    func confirmDelete() {
        guard let item = itemPendingDelete else { return }
        do {
            try FinderService.delete(item)
            reload()
        } catch {
            errorMessage = error.localizedDescription
        }
        itemPendingDelete = nil
    }

    /// Sposta un item (identificato dal path, usato per il drag & drop) dentro `destination`.
    func moveItem(withPath path: String, to destination: URL) {
        let allKnownItems = items + columnItems.flatMap { $0 }
        guard let item = allKnownItems.first(where: { $0.id == path }) else { return }
        do {
            try FinderService.move(item, to: destination)
            reload()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
