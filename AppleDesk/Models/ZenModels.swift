import SwiftUI

// MARK: - Temi Zen
enum ZenTheme: String, CaseIterable, Identifiable, Codable {
    case midnight = "Mezzanotte"
    case dusk = "Crepuscolo"
    case ember = "Brace"
    case ocean = "Oceano"
    case forest = "Foresta"

    var id: String { rawValue }

    var accent: Color {
        switch self {
        case .midnight: return Color(red: 0.95, green: 0.44, blue: 0.40)
        case .dusk:     return Color(red: 0.78, green: 0.62, blue: 0.98)
        case .ember:    return Color(red: 0.98, green: 0.58, blue: 0.36)
        case .ocean:    return Color(red: 0.42, green: 0.68, blue: 0.96)
        case .forest:   return Color(red: 0.48, green: 0.78, blue: 0.58)
        }
    }

    /// Sfondo uniforme — niente gradienti invasivi
    var gradient: [Color] {
        [ZenPalette.canvas, ZenPalette.canvas]
    }
}

// MARK: - Split View (fino a 4 pannelli)
enum ZenSplitLayout: Int, CaseIterable, Identifiable, Codable {
    case single = 1
    case twoHorizontal = 2
    case three = 3
    case four = 4

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .single:        return "Singolo"
        case .twoHorizontal: return "2 pannelli"
        case .three:         return "3 pannelli"
        case .four:          return "4 pannelli"
        }
    }

    var symbol: String {
        switch self {
        case .single:        return "rectangle"
        case .twoHorizontal: return "rectangle.split.2x1"
        case .three:         return "rectangle.split.1x2"
        case .four:          return "square.grid.2x2"
        }
    }

    var panelCount: Int { rawValue }
}

// MARK: - Scorciatoie
struct ZenShortcut: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var url: String

    init(id: UUID = UUID(), name: String, url: String) {
        self.id = id
        self.name = name
        self.url = url
    }
}

// MARK: - Zen Boosts (semplificati)
struct ZenBoostSettings: Codable, Equatable {
    var forceDarkMode: Bool = false
    var blockTrackers: Bool = true
}

// MARK: - Workspace (persistenza)
struct ZenWorkspaceSnapshot: Codable, Identifiable, Equatable {
    var id: UUID
    var name: String
    var symbol: String
    var tabSnapshots: [ZenTabSnapshot]
    var activeTabID: UUID?
    var pinnedTabIDs: [UUID]
}

struct ZenTabSnapshot: Codable, Equatable, Identifiable {
    var id: UUID
    var title: String
    var urlText: String
    var loadedURLString: String?
}

// MARK: - Workspace template
struct ZenWorkspaceTemplate: Identifiable {
    let id: UUID
    let name: String
    let symbol: String

    static let defaults: [ZenWorkspaceTemplate] = [
        ZenWorkspaceTemplate(id: UUID(uuidString: "A1000001-0000-0000-0000-000000000001")!, name: "Personale", symbol: "house.fill"),
        ZenWorkspaceTemplate(id: UUID(uuidString: "A1000001-0000-0000-0000-000000000002")!, name: "Lavoro", symbol: "briefcase.fill"),
        ZenWorkspaceTemplate(id: UUID(uuidString: "A1000001-0000-0000-0000-000000000003")!, name: "Studio", symbol: "book.fill"),
    ]
}
