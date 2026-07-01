import Foundation
import WebKit
import MediaPlayer
import UIKit

@MainActor
final class SpotifyStateHandler: NSObject, WKScriptMessageHandler {
    weak var viewModel: SpotifyViewModel?

    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage) {
        guard message.name == "spotifyState" else { return }
        Task { @MainActor in
            viewModel?.applyStatePayload(message.body)
        }
    }
}

@MainActor
final class SpotifyViewModel: ObservableObject {
    static let playerURL = URL(string: "https://open.spotify.com")!

    @Published private(set) var loadState: SpotifyLoadState = .loading
    @Published private(set) var playback = SpotifyPlayback.empty
    @Published private(set) var isWindowAttached = false

    let webView: WKWebView
    private let stateHandler = SpotifyStateHandler()
    private var bridgeInstalled = false
    private var hasLoadedOnce = false

    init() {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        config.allowsAirPlayForMediaPlayback = true

        let prefs = WKWebpagePreferences()
        prefs.preferredContentMode = .desktop
        prefs.allowsContentJavaScript = true
        config.defaultWebpagePreferences = prefs

        stateHandler.viewModel = self
        config.userContentController.add(stateHandler, name: "spotifyState")

        webView = WKWebView(frame: .zero, configuration: config)
        webView.customUserAgent =
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 14_5) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Safari/605.1.15"
        webView.allowsLinkPreview = false
        webView.isOpaque = false
        webView.backgroundColor = UIColor(red: 0.07, green: 0.07, blue: 0.07, alpha: 1)
    }

    var isSessionActive: Bool {
        switch loadState {
        case .ready, .loginRequired: return true
        default: return false
        }
    }

    func markWindowAttached(_ attached: Bool) {
        isWindowAttached = attached
    }

    func handleNavigationStarted() {
        if !hasLoadedOnce { loadState = .loading }
    }

    func handleNavigationFinished(url: URL?) {
        hasLoadedOnce = true
        webView.evaluateJavaScript(SpotifyBridge.removeBanners)
        installBridgeIfNeeded()

        if let path = url?.path, path.contains("/login") || path.contains("/signup") {
            loadState = .loginRequired
        } else {
            loadState = .ready
        }
        refreshState()
    }

    func handleNavigationFailed(message: String) {
        loadState = .error(message)
    }

    func installBridgeIfNeeded() {
        guard !bridgeInstalled else { return }
        bridgeInstalled = true
        webView.evaluateJavaScript(SpotifyBridge.installObserver)
    }

    func reload() {
        hasLoadedOnce = false
        loadState = .loading
        webView.load(URLRequest(url: Self.playerURL))
    }

    func playPause() {
        runControl(SpotifyBridge.playPause)
    }

    func nextTrack() {
        runControl(SpotifyBridge.nextTrack)
    }

    func previousTrack() {
        runControl(SpotifyBridge.previousTrack)
    }

    func toggleShuffle() {
        runControl(SpotifyBridge.toggleShuffle)
    }

    func toggleRepeat() {
        runControl(SpotifyBridge.toggleRepeat)
    }

    func refreshState() {
        webView.evaluateJavaScript(SpotifyBridge.readState) { [weak self] result, _ in
            Task { @MainActor in
                guard let self else { return }
                if let dict = result as? [String: Any] {
                    self.applyStatePayload(dict)
                }
            }
        }
    }

    func applyStatePayload(_ body: Any) {
        guard let dict = body as? [String: Any] else { return }

        if dict["onLoginPage"] as? Bool == true {
            loadState = .loginRequired
        } else if case .loginRequired = loadState {
            loadState = .ready
        }

        var next = playback
        next.title = dict["title"] as? String ?? ""
        next.artist = dict["artist"] as? String ?? ""
        next.album = dict["album"] as? String ?? ""
        next.isPlaying = dict["isPlaying"] as? Bool ?? false
        next.shuffleOn = dict["shuffleOn"] as? Bool ?? false
        next.progress = dict["progress"] as? Double ?? 0
        next.positionMs = dict["positionMs"] as? Int ?? 0
        next.durationMs = dict["durationMs"] as? Int ?? 0

        if let raw = dict["repeatMode"] as? String {
            next.repeatMode = SpotifyRepeatMode(rawValue: raw) ?? .off
        }

        if let urlString = dict["artworkUrl"] as? String, !urlString.isEmpty {
            next.artworkURL = URL(string: urlString)
        } else if !next.hasTrack {
            next.artworkURL = nil
        }

        playback = next
        updateNowPlayingCenter()
    }

    private func runControl(_ script: String) {
        webView.evaluateJavaScript(script) { [weak self] _, _ in
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(280))
                self?.refreshState()
            }
        }
    }

    private func updateNowPlayingCenter() {
        guard playback.hasTrack else { return }
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: playback.title,
            MPMediaItemPropertyArtist: playback.artist,
            MPNowPlayingInfoPropertyPlaybackRate: playback.isPlaying ? 1.0 : 0.0,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: Double(playback.positionMs) / 1000.0
        ]
        if playback.durationMs > 0 {
            info[MPMediaItemPropertyPlaybackDuration] = Double(playback.durationMs) / 1000.0
        }
        if !playback.album.isEmpty {
            info[MPMediaItemPropertyAlbumTitle] = playback.album
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
}
