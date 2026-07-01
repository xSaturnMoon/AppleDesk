import SwiftUI

// MARK: - View Mode (Icone / Lista / Colonne)
enum FinderViewMode: String, CaseIterable {
    case icons, list, columns

    var symbol: String {
        switch self {
        case .icons:   return "square.grid.2x2"
        case .list:    return "list.bullet"
        case .columns: return "rectangle.split.3x1"
        }
    }
}

// MARK: - Categoria sidebar (mappa 1:1 con una sottocartella reale in Documents)
struct FinderCategory: Identifiable, Hashable {
    let id: String
    let name: String
    let symbol: String
    let folderName: String?   // nil = root (AppleDesk / Documents)

    static let root = FinderCategory(id: "root", name: "AppleDesk", symbol: "internaldrive.fill", folderName: nil)

    static let all: [FinderCategory] = [
        FinderCategory(id: "desktop",      name: "Scrivania",    symbol: "menubar.dock.rectangle",  folderName: "Scrivania"),
        FinderCategory(id: "documents",    name: "Documenti",    symbol: "doc.text.fill",           folderName: "Documenti"),
        FinderCategory(id: "downloads",    name: "Download",     symbol: "arrow.down.circle.fill",  folderName: "Download"),
        FinderCategory(id: "applications", name: "Applicazioni", symbol: "square.grid.2x2.fill",    folderName: "Applicazioni"),
        FinderCategory(id: "pictures",     name: "Immagini",     symbol: "photo.fill",              folderName: "Immagini"),
        FinderCategory(id: "movies",       name: "Filmati",      symbol: "film.fill",               folderName: "Filmati"),
        FinderCategory(id: "music",        name: "Musica",       symbol: "music.note",              folderName: "Musica"),
    ]

    var url: URL {
        guard let folderName else { return FinderService.rootURL }
        return FinderService.rootURL.appendingPathComponent(folderName, isDirectory: true)
    }
}

// MARK: - Elemento reale sul filesystem (file o cartella)
struct FinderItem: Identifiable, Hashable {
    let url: URL
    let name: String
    let isDirectory: Bool
    let size: Int64
    let modificationDate: Date

    var isSystemFolder: Bool {
        guard isDirectory else { return false }
        return FinderCategory.all.contains { $0.url.path == url.path }
    }

    var id: String { url.path }

    var symbol: String {
        if isDirectory { return "folder.fill" }
        switch url.pathExtension.lowercased() {
        case "jpg", "jpeg", "png", "heic", "gif", "webp": return "photo.fill"
        case "mp4", "mov", "m4v":                          return "film.fill"
        case "mp3", "wav", "m4a", "aac":                   return "music.note"
        case "pdf":                                        return "doc.richtext.fill"
        case "zip", "rar", "7z":                           return "doc.zipper"
        case "txt", "md":                                  return "doc.plaintext.fill"
        case "swift", "c", "cpp", "py", "js", "ts", "java", "json":
                                                             return "chevron.left.forwardslash.chevron.right"
        default:                                            return "doc.fill"
        }
    }

    var tint: Color {
        isDirectory ? Color(red: 0.35, green: 0.68, blue: 0.98) : .white.opacity(0.75)
    }

    var sizeString: String {
        isDirectory ? "--" : ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    var dateString: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "it_IT")
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: modificationDate)
    }

    var kindString: String {
        if isDirectory { return "Cartella" }
        let ext = url.pathExtension.uppercased()
        return ext.isEmpty ? "Documento" : "Documento \(ext)"
    }
}
