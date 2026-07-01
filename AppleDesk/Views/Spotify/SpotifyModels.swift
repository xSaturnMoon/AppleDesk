import Foundation

enum SpotifyRepeatMode: String, Equatable, Codable {
    case off, all, track
}

enum SpotifyLoadState: Equatable {
    case loading
    case ready
    case loginRequired
    case error(String)
}

struct SpotifyPlayback: Equatable {
    var title: String = ""
    var artist: String = ""
    var album: String = ""
    var artworkURL: URL?
    var isPlaying: Bool = false
    var shuffleOn: Bool = false
    var repeatMode: SpotifyRepeatMode = .off
    var progress: Double = 0
    var durationMs: Int = 0
    var positionMs: Int = 0

    var hasTrack: Bool { !title.isEmpty }

    static let empty = SpotifyPlayback()
}
