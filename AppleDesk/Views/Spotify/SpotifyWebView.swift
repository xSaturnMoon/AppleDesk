import SwiftUI
import WebKit

struct SpotifyWebView: UIViewRepresentable {
    @ObservedObject var vm: SpotifyViewModel

    func makeUIView(context: Context) -> WKWebView {
        let wv = vm.webView
        wv.navigationDelegate = context.coordinator
        wv.uiDelegate = context.coordinator
        vm.startInitialLoadIfNeeded()
        return wv
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(vm: vm) }

    @MainActor
    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        let vm: SpotifyViewModel

        init(vm: SpotifyViewModel) { self.vm = vm }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                     decisionHandler: @escaping @MainActor @Sendable (WKNavigationActionPolicy) -> Void) {
            let url = navigationAction.request.url
            if let scheme = url?.scheme?.lowercased(),
               scheme == "spotify" || scheme == "itms-apps" || scheme == "itms" {
                decisionHandler(.cancel)
                return
            }
            if let host = url?.host?.lowercased(),
               host.contains("apps.apple.com") || host == "links.spotify.com" {
                decisionHandler(.cancel)
                return
            }
            decisionHandler(.allow)
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            vm.handleNavigationStarted()
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            vm.handleNavigationFinished(url: webView.url)
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            vm.handleNavigationFailed(message: error.localizedDescription)
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!,
                     withError error: Error) {
            vm.handleNavigationFailed(message: error.localizedDescription)
        }

        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
                     for navigationAction: WKNavigationAction,
                     windowFeatures: WKWindowFeatures) -> WKWebView? {
            if navigationAction.targetFrame == nil, let url = navigationAction.request.url {
                webView.load(URLRequest(url: url))
            }
            return nil
        }
    }
}
