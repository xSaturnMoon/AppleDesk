import SwiftUI

// MARK: - Wallpaper

enum WallpaperStyle: String, CaseIterable, Identifiable, Codable {
    case graphite, aurora, sunset, ocean, forest, midnight, rose, ember

    var id: String { rawValue }

    var title: String {
        switch self {
        case .graphite: return "Grafite"
        case .aurora: return "Aurora"
        case .sunset: return "Tramonto"
        case .ocean: return "Oceano"
        case .forest: return "Foresta"
        case .midnight: return "Mezzanotte"
        case .rose: return "Rosa"
        case .ember: return "Brace"
        }
    }

    var icon: String {
        switch self {
        case .graphite: return "circle.lefthalf.filled"
        case .aurora: return "sparkles"
        case .sunset: return "sun.horizon.fill"
        case .ocean: return "water.waves"
        case .forest: return "leaf.fill"
        case .midnight: return "moon.stars.fill"
        case .rose: return "heart.fill"
        case .ember: return "flame.fill"
        }
    }

    var colors: [Color] {
        switch self {
        case .graphite:
            return [Color(red: 0.13, green: 0.13, blue: 0.14),
                    Color(red: 0.09, green: 0.09, blue: 0.10),
                    Color(red: 0.06, green: 0.06, blue: 0.07)]
        case .aurora:
            return [Color(red: 0.18, green: 0.12, blue: 0.32),
                    Color(red: 0.10, green: 0.14, blue: 0.28),
                    Color(red: 0.06, green: 0.08, blue: 0.18)]
        case .sunset:
            return [Color(red: 0.32, green: 0.14, blue: 0.18),
                    Color(red: 0.22, green: 0.10, blue: 0.20),
                    Color(red: 0.12, green: 0.06, blue: 0.14)]
        case .ocean:
            return [Color(red: 0.08, green: 0.22, blue: 0.36),
                    Color(red: 0.05, green: 0.14, blue: 0.26),
                    Color(red: 0.03, green: 0.08, blue: 0.16)]
        case .forest:
            return [Color(red: 0.08, green: 0.22, blue: 0.14),
                    Color(red: 0.05, green: 0.14, blue: 0.10),
                    Color(red: 0.03, green: 0.08, blue: 0.06)]
        case .midnight:
            return [Color(red: 0.06, green: 0.08, blue: 0.22),
                    Color(red: 0.04, green: 0.05, blue: 0.14),
                    Color(red: 0.02, green: 0.03, blue: 0.08)]
        case .rose:
            return [Color(red: 0.28, green: 0.10, blue: 0.22),
                    Color(red: 0.18, green: 0.07, blue: 0.16),
                    Color(red: 0.10, green: 0.04, blue: 0.10)]
        case .ember:
            return [Color(red: 0.28, green: 0.12, blue: 0.06),
                    Color(red: 0.18, green: 0.08, blue: 0.05),
                    Color(red: 0.10, green: 0.04, blue: 0.03)]
        }
    }
}

// MARK: - Accent

enum SettingsAccent: String, CaseIterable, Identifiable, Codable {
    case blue, purple, pink, orange, green, cyan, indigo, red

    var id: String { rawValue }

    var title: String {
        switch self {
        case .blue: return "Blu"
        case .purple: return "Viola"
        case .pink: return "Rosa"
        case .orange: return "Arancio"
        case .green: return "Verde"
        case .cyan: return "Ciano"
        case .indigo: return "Indaco"
        case .red: return "Rosso"
        }
    }

    var color: Color {
        switch self {
        case .blue: return .blue
        case .purple: return .purple
        case .pink: return .pink
        case .orange: return .orange
        case .green: return .green
        case .cyan: return .cyan
        case .indigo: return .indigo
        case .red: return .red
        }
    }
}

// MARK: - Weather city

struct WeatherCity: Identifiable, Hashable {
    let id: String
    let name: String
    let lat: Double
    let lon: Double

    static let presets: [WeatherCity] = [
        WeatherCity(id: "parma", name: "Parma", lat: 44.80, lon: 10.33),
        WeatherCity(id: "milano", name: "Milano", lat: 45.46, lon: 9.19),
        WeatherCity(id: "roma", name: "Roma", lat: 41.90, lon: 12.50),
        WeatherCity(id: "napoli", name: "Napoli", lat: 40.85, lon: 14.27),
        WeatherCity(id: "londra", name: "Londra", lat: 51.51, lon: -0.13),
        WeatherCity(id: "parigi", name: "Parigi", lat: 48.86, lon: 2.35),
        WeatherCity(id: "newyork", name: "New York", lat: 40.71, lon: -74.01),
        WeatherCity(id: "tokyo", name: "Tokyo", lat: 35.68, lon: 139.69),
    ]
}

// MARK: - Sidebar

enum SettingsSection: String, CaseIterable, Identifiable {
    case general, appearance, desktop, account, weather, energy, sound, privacy, system

    var id: String { rawValue }

    var title: String {
        switch self {
        case .general: return "Generale"
        case .appearance: return "Aspetto"
        case .desktop: return "Desktop e Dock"
        case .account: return "Account"
        case .weather: return "Meteo"
        case .energy: return "Energia"
        case .sound: return "Suono e Schermo"
        case .privacy: return "Privacy"
        case .system: return "Sistema"
        }
    }

    var icon: String {
        switch self {
        case .general: return "info.circle.fill"
        case .appearance: return "paintbrush.fill"
        case .desktop: return "macwindow.on.rectangle"
        case .account: return "person.crop.circle.fill"
        case .weather: return "cloud.sun.fill"
        case .energy: return "battery.100.bolt"
        case .sound: return "speaker.wave.2.fill"
        case .privacy: return "hand.raised.fill"
        case .system: return "gearshape.2.fill"
        }
    }
}
