import Foundation

/// Gioco avviabile tramite GeForce NOW (deep link ufficiale NVIDIA).
struct GFNGame: Identifiable, Hashable {
    let id: String
    let name: String
    let subtitle: String
    let gameId: String
    let store: String
    let genre: String
    let requiresGamepad: Bool

    var launchURL: URL {
        GFNLinks.gamePage(gameId: gameId, campaign: id)
    }

    static let counterStrike2 = GFNGame(
        id: "cs2",
        name: "Counter-Strike 2",
        subtitle: "Tactical FPS · Steam",
        gameId: "dfdbc357-7f61-45cc-bf64-ae7117da12d5",
        store: "Steam",
        genre: "FPS",
        requiresGamepad: true
    )

    static let featured: [GFNGame] = [.counterStrike2]
}

enum GFNLinks {
    static let base = "https://play.geforcenow.com"
    static let utmSource = "appledesk"

    static var hub: URL {
        URL(string: "\(base)/mall/")!
    }

    static func gamePage(gameId: String, campaign: String) -> URL {
        var c = URLComponents(string: "\(base)/games")!
        c.queryItems = [
            URLQueryItem(name: "game-id", value: gameId),
            URLQueryItem(name: "utm_source", value: utmSource),
            URLQueryItem(name: "utm_campaign", value: campaign),
            URLQueryItem(name: "lang", value: "it_IT"),
        ]
        return c.url!
    }
}
