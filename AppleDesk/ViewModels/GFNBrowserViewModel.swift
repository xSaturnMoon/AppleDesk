import Foundation
import WebKit

enum GFNLoadState: Equatable {
    case loading
    case ready
    case error(String)
}

@MainActor
final class GFNBrowserViewModel: ObservableObject {
    @Published private(set) var loadState: GFNLoadState = .loading
    @Published private(set) var canGoBack = false
    @Published private(set) var pageTitle: String = ""

    let webView: WKWebView
    private let startURL: URL
    private var hasStarted = false

    init(startURL: URL) {
        self.startURL = startURL
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        config.allowsAirPlayForMediaPlayback = true
        config.allowsPictureInPictureMediaPlayback = true

        let prefs = WKWebpagePreferences()
        prefs.preferredContentMode = .desktop
        prefs.allowsContentJavaScript = true
        config.defaultWebpagePreferences = prefs
        config.preferences.isElementFullscreenEnabled = true

        webView = WKWebView(frame: .zero, configuration: config)
        webView.customUserAgent =
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 14_5) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Safari/605.1.15"
        webView.allowsLinkPreview = false
        webView.allowsBackForwardNavigationGestures = true
        webView.isOpaque = true
        webView.backgroundColor = .black
        webView.scrollView.contentInsetAdjustmentBehavior = .never
    }

    func startIfNeeded() {
        guard !hasStarted else { return }
        hasStarted = true
        loadState = .loading
        var req = URLRequest(url: startURL)
        req.cachePolicy = .reloadIgnoringLocalCacheData
        webView.load(req)
    }

    func reload() {
        loadState = .loading
        webView.reload()
    }

    func goBack() {
        webView.goBack()
    }

    func handleNavigationStarted() {
        if loadState != .ready { loadState = .loading }
    }

    func handleNavigationFinished(url: URL?) {
        canGoBack = webView.canGoBack
        pageTitle = webView.title ?? ""
        loadState = .ready
    }

    func handleNavigationFailed(_ message: String) {
        loadState = .error(message)
    }
}
