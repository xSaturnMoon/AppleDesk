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
        config.preferences.javaScriptCanOpenWindowsAutomatically = true

        let bootstrap = WKUserScript(
            source: GFNBrowserSpoof.bootstrapScript,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: false
        )
        config.userContentController.addUserScript(bootstrap)

        webView = WKWebView(frame: .zero, configuration: config)
        webView.customUserAgent = GFNBrowserSpoof.desktopChromeUserAgent
        webView.allowsLinkPreview = false
        webView.allowsBackForwardNavigationGestures = true
        webView.isOpaque = true
        webView.backgroundColor = .black
        webView.scrollView.contentInsetAdjustmentBehavior = .never
    }

    func startIfNeeded() {
        guard !hasStarted else { return }
        hasStarted = true
        loadURL(startURL)
    }

    func loadURL(_ url: URL) {
        loadState = .loading
        var req = URLRequest(url: url)
        req.cachePolicy = .reloadIgnoringLocalCacheData
        req.setValue(GFNBrowserSpoof.desktopChromeUserAgent, forHTTPHeaderField: "User-Agent")
        webView.load(req)
    }

    func reload() {
        loadURL(webView.url ?? startURL)
    }

    func openLogin() {
        loadURL(GFNLinks.hub)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            self?.triggerLoginClick()
        }
    }

    func triggerLoginClick() {
        webView.evaluateJavaScript(GFNBrowserSpoof.clickLoginScript) { [weak self] result, _ in
            guard let self else { return }
            if (result as? String) == "not-found" {
                self.loadURL(GFNLinks.hub)
            }
        }
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
        webView.evaluateJavaScript(GFNBrowserSpoof.pageCleanupScript)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            self?.webView.evaluateJavaScript(GFNBrowserSpoof.pageCleanupScript)
        }
    }

    func handleNavigationFailed(_ message: String) {
        loadState = .error(message)
    }
}
