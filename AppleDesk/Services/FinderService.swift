import Foundation

// MARK: - Finder Service
// Parla col vero filesystem dell'app: la cartella Documents dell'app compare
// dentro Files.app ("Su iPad") col nome "AppleDesk" (CFBundleDisplayName),
// grazie a LSSupportsOpeningDocumentsInPlace + UIFileSharingEnabled in Info.plist.
// Ogni operazione qui sotto agisce su file/cartelle VERI, non su dati finti.
enum FinderService {

    static let rootURL: URL = {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }()

    /// Crea la struttura di cartelle stile macOS al primo avvio. Idempotente:
    /// se una cartella esiste già (o l'utente l'ha rinominata/spostata) non la ricrea sopra.
    static func setupFolderStructureIfNeeded() {
        let fm = FileManager.default
        if !fm.fileExists(atPath: rootURL.path) {
            try? fm.createDirectory(at: rootURL, withIntermediateDirectories: true)
        }
        for category in FinderCategory.all {
            let url = category.url
            if !fm.fileExists(atPath: url.path) {
                try? fm.createDirectory(at: url, withIntermediateDirectories: true)
            }
        }
    }

    // MARK: - Lettura

    static func contents(of folder: URL) -> [FinderItem] {
        let fm = FileManager.default
        guard let urls = try? fm.contentsOfDirectory(
            at: folder,
            includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }

        let items: [FinderItem] = urls.compactMap { url in
            let values = try? url.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey])
            let isDir = values?.isDirectory ?? false
            let size = Int64(values?.fileSize ?? 0)
            let date = values?.contentModificationDate ?? Date.distantPast
            return FinderItem(url: url, name: url.lastPathComponent, isDirectory: isDir, size: size, modificationDate: date)
        }

        return items.sorted { a, b in
            if a.isDirectory != b.isDirectory { return a.isDirectory }
            return a.name.localizedStandardCompare(b.name) == .orderedAscending
        }
    }

    // MARK: - Scrittura

    @discardableResult
    static func createFolder(named name: String, in folder: URL) throws -> URL {
        let clean = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { throw FinderError.invalidName }
        let target = uniqueURL(for: folder.appendingPathComponent(clean, isDirectory: true))
        try FileManager.default.createDirectory(at: target, withIntermediateDirectories: true)
        return target
    }

    @discardableResult
    static func rename(_ item: FinderItem, to newName: String) throws -> URL {
        let clean = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { throw FinderError.invalidName }
        let folder = item.url.deletingLastPathComponent()
        let proposed = folder.appendingPathComponent(clean, isDirectory: item.isDirectory)
        guard proposed.path != item.url.path else { return item.url }
        let target = uniqueURL(for: proposed)
        try FileManager.default.moveItem(at: item.url, to: target)
        return target
    }

    static func delete(_ item: FinderItem) throws {
        let fm = FileManager.default
        do {
            try fm.trashItem(at: item.url, resultingItemURL: nil)
        } catch {
            try fm.removeItem(at: item.url)
        }
    }

    static func move(_ item: FinderItem, to destinationFolder: URL) throws {
        guard destinationFolder.path != item.url.deletingLastPathComponent().path else { return }
        // evita di spostare una cartella dentro se stessa o dentro un suo figlio
        guard destinationFolder.path != item.url.path,
              !destinationFolder.path.hasPrefix(item.url.path + "/") else {
            throw FinderError.invalidDestination
        }
        let target = uniqueURL(for: destinationFolder.appendingPathComponent(item.name, isDirectory: item.isDirectory))
        try FileManager.default.moveItem(at: item.url, to: target)
    }

    // MARK: - Helpers

    /// Se esiste già un file/cartella con lo stesso nome, aggiunge un contatore ("nome 2", "nome 3"...)
    private static func uniqueURL(for url: URL) -> URL {
        let fm = FileManager.default
        guard fm.fileExists(atPath: url.path) else { return url }
        let ext = url.pathExtension
        let base = ext.isEmpty ? url.lastPathComponent : String(url.lastPathComponent.dropLast(ext.count + 1))
        let folder = url.deletingLastPathComponent()
        var counter = 2
        var candidate = url
        while fm.fileExists(atPath: candidate.path) {
            let newName = ext.isEmpty ? "\(base) \(counter)" : "\(base) \(counter).\(ext)"
            candidate = folder.appendingPathComponent(newName, isDirectory: url.hasDirectoryPath)
            counter += 1
        }
        return candidate
    }
}

enum FinderError: LocalizedError {
    case invalidName
    case invalidDestination

    var errorDescription: String? {
        switch self {
        case .invalidName:        return "Nome non valido."
        case .invalidDestination: return "Non puoi spostare un elemento dentro se stesso."
        }
    }
}
