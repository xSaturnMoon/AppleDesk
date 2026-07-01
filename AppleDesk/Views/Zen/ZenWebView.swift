import SwiftUI
import WebKit

// MARK: - Zen WebView
struct ZenWebView: UIViewRepresentable {
    @ObservedObject var tab: ZenTabModel
    @ObservedObject var vm: ZenViewModel
    var isGlance = false

    func makeUIView(context: Context) -> WKWebView {
        let wv = tab.webView
        wv.navigationDelegate = context.coordinator
        wv.uiDelegate = context.coordinator
        if let url = tab.loadedURL, wv.url == nil {
            wv.load(URLRequest(url: url))
        }
        context.coordinator.injectGlanceScript(into: wv)
        vm.applyPageStyles(to: wv)
        return wv
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        vm.applyPageStyles(to: uiView)
        guard let target = tab.loadedURL else {
            if uiView.url != nil && !isGlance {
                // home page — stop current load
            }
            return
        }
        let cur = uiView.url?.absoluteString ?? ""
        let tgt = target.absoluteString
        if cur != tgt && cur + "/" != tgt && tgt + "/" != cur {
            uiView.load(URLRequest(url: target))
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    @MainActor
    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        let parent: ZenWebView

        init(_ parent: ZenWebView) { self.parent = parent }

        func injectGlanceScript(into webView: WKWebView) {
            let script = """
            (function(){
              if(window.__zenGlanceInstalled) return;
              window.__zenGlanceInstalled = true;
              document.addEventListener('click', function(e) {
                if (e.metaKey || e.ctrlKey || e.altKey) {
                  var a = e.target.closest('a');
                  if (a && a.href) {
                    e.preventDefault();
                    window.webkit.messageHandlers.zenGlance.postMessage(a.href);
                  }
                }
              }, true);
              document.addEventListener('contextmenu', function(e) {
                var a = e.target.closest('a');
                if (a && a.href) window.__zenLastLink = a.href;
              }, true);
            })();
            """
            webView.evaluateJavaScript(script)
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.vm.applyPageStyles(to: webView)
            injectGlanceScript(into: webView)

            DispatchQueue.main.async {
                self.parent.tab.isLoading = false
                if let url = webView.url {
                    self.parent.tab.urlText = url.absoluteString
                    self.parent.tab.title = webView.title?.isEmpty == false
                        ? webView.title!
                        : (url.host ?? "Sito web")
                    self.parent.vm.addToHistory(url.absoluteString)
                    self.parent.vm.persistWorkspacesSilent()
                }
                self.parent.tab.canGoBack = webView.canGoBack
                self.parent.tab.canGoForward = webView.canGoForward
            }
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.tab.isLoading = true
                self.parent.tab.canGoBack = webView.canGoBack
                self.parent.tab.canGoForward = webView.canGoForward
            }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async { self.parent.tab.isLoading = false }
        }

        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
                     for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            if navigationAction.targetFrame == nil, let url = navigationAction.request.url {
                parent.vm.loadURL(url.absoluteString, on: parent.tab)
            }
            return nil
        }
    }
}

private extension ZenViewModel {
    func persistWorkspacesSilent() {
        let snapshots = workspaces.map { $0.snapshot() }
        if let data = try? JSONEncoder().encode(snapshots) {
            UserDefaults.standard.set(data, forKey: "zen_workspaces")
        }
    }
}
