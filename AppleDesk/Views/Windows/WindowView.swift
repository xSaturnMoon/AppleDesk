import SwiftUI
import WebKit

// MARK: - Window View
// NOTE: The core WindowView struct is in WindowViewCore.swift
// Everything below are content views and title bar


// MARK: - Title Bar
struct WindowTitleBar: View {
    let title: String; let icon: String; let iconAsset: String?; let isActive: Bool; let isMaximized: Bool
    let onClose: () -> Void; let onMinimize: () -> Void; let onMaximize: () -> Void
    @State private var isHoveringButtons = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                HStack(spacing: 8) {
                    CircleButton(color: Color(red:1.0,green:0.23,blue:0.19), icon:"xmark", showIcon: isHoveringButtons, action: onClose)
                    CircleButton(color: Color(red:1.0,green:0.72,blue:0.0), icon:"minus", showIcon: isHoveringButtons, action: onMinimize)
                    CircleButton(color: Color(red:0.16,green:0.80,blue:0.25),
                                 icon: isMaximized ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right",
                                 showIcon: isHoveringButtons,
                                 action: onMaximize)
                }
                .frame(width: 80, alignment: .leading)
                .onHover { h in withAnimation(.easeInOut(duration: 0.12)) { isHoveringButtons = h } }

                Spacer()

                HStack(spacing: 6) {
                    if let asset = iconAsset {
                        Image(asset)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 14, height: 14)
                    } else {
                        Image(systemName: icon)
                            .font(.system(size:13,weight:.medium))
                            .foregroundStyle(isActive ? .white.opacity(0.9) : .white.opacity(0.5))
                    }
                    Text(title)
                        .font(.system(size:13,weight:.bold,design:.rounded))
                        .foregroundStyle(isActive ? .white : .white.opacity(0.55))
                }

                Spacer()
                Color.clear.frame(width: 80)
            }
            .padding(.horizontal, 16)
            .frame(height: 44)
            .background(LinearGradient(
                colors: [Color(red:0.18,green:0.18,blue:0.20).opacity(0.95),
                         Color(red:0.13,green:0.13,blue:0.15).opacity(0.95)],
                startPoint:.top, endPoint:.bottom))

            Rectangle().fill(.white.opacity(isActive ? 0.12 : 0.05)).frame(height: 1)
        }
    }
}

struct CircleButton: View {
    let color: Color; let icon: String; let showIcon: Bool; let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 13, height: 13)
                    .overlay(Circle().stroke(.black.opacity(0.1), lineWidth: 0.5))
                if showIcon {
                    Image(systemName: icon)
                        .font(.system(size: 6.5, weight: .black))
                        .foregroundStyle(.black.opacity(0.65))
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Content Router
struct WindowContent: View {
    let app: AppItem?
    var body: some View {
        Group {
            switch app?.id {
            case "zen":     ZenWindowContent()
            case "spotify": SpotifyWindowContent()
            case "finder":  FinderWindowContent()
            default:
                switch app?.name {
                case "Terminale": TerminalWindowContent()
                case "Note":      NotesWindowContent()
                case "Codice":    CodeWindowContent()
                default:          GenericWindowContent(app: app)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Spotify Service (singleton per controllare il webView da ControlCenter)
@MainActor
class SpotifyService: ObservableObject {
    static let shared = SpotifyService()
    weak var webView: WKWebView?

    func playPause() {
        webView?.evaluateJavaScript("""
            (function(){
                var btn = document.querySelector('[data-testid="control-button-playpause"]');
                if(btn) { btn.click(); return true; }
                return false;
            })()
        """)
    }
    func nextTrack() {
        webView?.evaluateJavaScript("""
            var b = document.querySelector('[data-testid="control-button-skip-forward"]');
            if(b) b.click();
        """)
    }
    func previousTrack() {
        webView?.evaluateJavaScript("""
            var b = document.querySelector('[data-testid="control-button-skip-back"]');
            if(b) b.click();
        """)
    }
    func setRepeat(_ on: Bool) {
        webView?.evaluateJavaScript("""
            var b = document.querySelector('[data-testid="control-button-repeat"]');
            if(b) { var curr = b.getAttribute('aria-label') || '';
                var active = curr.toLowerCase().includes('on');
                if(active !== \(on ? "true" : "false")) b.click(); }
        """)
    }
}

// MARK: - Spotify Window
struct SpotifyWindowContent: View {
    @StateObject private var tab = SpotifyTab()

    var body: some View {
        ZStack {
            SpotifyWebView(tab: tab)
            if tab.isLoading {
                VStack(spacing: 16) {
                    Image(systemName: "music.note")
                        .font(.system(size: 40, weight: .light))
                        .foregroundStyle(.green)
                        .symbolEffect(.pulse)
                    Text("Caricamento Spotifyâ€¦")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
        }
        .background(Color(red: 0.07, green: 0.07, blue: 0.07))
    }
}

@MainActor
class SpotifyTab: ObservableObject {
    @Published var isLoading = true
    let webView: WKWebView

    init() {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        // Disabilita AirPlay per evitare conflitti audio multipli
        config.allowsAirPlayForMediaPlayback = false
        let prefs = WKWebpagePreferences()
        prefs.preferredContentMode = .desktop
        prefs.allowsContentJavaScript = true
        config.defaultWebpagePreferences = prefs
        self.webView = WKWebView(frame: .zero, configuration: config)
        // User agent desktop Mac â€” evita il redirect a Spotify native
        self.webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 14_5) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Safari/605.1.15"
        self.webView.allowsLinkPreview = false
    }
}

struct SpotifyWebView: UIViewRepresentable {
    @ObservedObject var tab: SpotifyTab

    func makeUIView(context: Context) -> WKWebView {
        tab.webView.navigationDelegate = context.coordinator
        SpotifyService.shared.webView = tab.webView
        var req = URLRequest(url: URL(string: "https://open.spotify.com")!)
        req.setValue("https://open.spotify.com", forHTTPHeaderField: "Referer")
        tab.webView.load(req)
        return tab.webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, WKNavigationDelegate {
        let parent: SpotifyWebView
        init(_ p: SpotifyWebView) { parent = p }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                     decisionHandler: @escaping @MainActor @Sendable (WKNavigationActionPolicy) -> Void) {
            let url = navigationAction.request.url
            // Blocca qualsiasi redirect verso l'app Spotify nativa o App Store
            if let scheme = url?.scheme,
               scheme == "spotify" || scheme == "itms-apps" || scheme == "itms" {
                decisionHandler(.cancel)
                return
            }
            // Blocca i redirect all'App Store o a links.spotify.com che aprono l'app
            if let host = url?.host,
               host.contains("apps.apple.com") || host == "links.spotify.com" {
                decisionHandler(.cancel)
                return
            }
            decisionHandler(.allow)
        }

        func webView(_ wv: WKWebView, didFinish navigation: WKNavigation!) {
            // Rimuove il banner "Open in app" di Spotify se presente
            wv.evaluateJavaScript("""
                var banner = document.querySelector('[data-testid="web-player-app-banner"]');
                if (banner) banner.remove();
                var smartBanner = document.querySelector('.smart-banner');
                if (smartBanner) smartBanner.remove();
            """)
            DispatchQueue.main.async { self.parent.tab.isLoading = false }
        }
        func webView(_ wv: WKWebView, didStartProvisionalNavigation _: WKNavigation!) {
            DispatchQueue.main.async { self.parent.tab.isLoading = true }
        }
        func webView(_ wv: WKWebView, didFail _: WKNavigation!, withError _: Error) {
            DispatchQueue.main.async { self.parent.tab.isLoading = false }
        }
    }
}
// MARK: - Terminal
struct TerminalWindowContent: View {
    @State private var output:[String]=["AppleDesk Terminal v1.2","Digita 'help' per i comandi.",""]
    @State private var input=""
    var body: some View {
        VStack(spacing:0) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment:.leading,spacing:4) {
                        ForEach(Array(output.enumerated()),id:\.offset) { _,line in
                            Text(line).font(.system(size:13,design:.monospaced))
                                .foregroundStyle(line.hasPrefix("â†’") ? .cyan : (line.hasPrefix("âžœ") ? .green : .white.opacity(0.85)))
                                .frame(maxWidth:.infinity,alignment:.leading)
                        }
                    }.padding(14).id("bottom")
                }.onChange(of:output.count) { _,_ in proxy.scrollTo("bottom",anchor:.bottom) }
            }
            HStack(spacing:8) {
                Text("âžœ").font(.system(size:13,design:.monospaced)).foregroundStyle(.green)
                TextField("",text:$input).font(.system(size:13,design:.monospaced)).foregroundStyle(.white).tint(.green)
                    .autocorrectionDisabled().textInputAutocapitalization(.never).onSubmit { runCommand() }
            }.padding(.horizontal,14).padding(.vertical,10).background(.black.opacity(0.4))
        }.background(.black.opacity(0.65))
    }
    private func runCommand() {
        let cmd=input.trimmingCharacters(in:.whitespaces); output.append("âžœ "+cmd)
        switch cmd.lowercased() {
        case "help": output+=["  help â€” comandi disponibili","  clear â€” pulisci terminale","  whoami â€” utente","  date â€” data e ora","  system â€” info hardware"]
        case "clear": output=[""]
        case "whoami": output.append("â†’ appledesk_user")
        case "date": output.append("â†’ \(Date().formatted(date:.long,time:.standard))")
        case "system": output+=["â†’ CPU: Apple M4 Pro","â†’ RAM: 16 GB","â†’ OS: AppleDesk 1.0"]
        case "": break
        default: output.append("â†’ comando non trovato: \(cmd)")
        }
        input=""
    }
}

// MARK: - Notes
struct NotesWindowContent: View {
    @State private var text=""
    var body: some View {
        TextEditor(text:$text).font(.system(size:15,design:.rounded)).foregroundStyle(.white)
            .scrollContentBackground(.hidden).background(.clear).padding(16).background(.black.opacity(0.25))
    }
}

// MARK: - Code Editor
struct CodeWindowContent: View {
    @State private var code="// AppleDesk Code Editor\nimport SwiftUI\n\nfunc hello() {\n    print(\"Ciao da AppleDesk!\")\n}\n"
    var body: some View {
        TextEditor(text:$code).font(.system(size:13,design:.monospaced)).foregroundStyle(.green.opacity(0.9))
            .scrollContentBackground(.hidden).background(.clear).padding(16).background(.black.opacity(0.5))
    }
}

// MARK: - Generic
struct GenericWindowContent: View {
    let app: AppItem?
    var body: some View {
        VStack(spacing:20) {
            Image(systemName:app?.icon ?? "app.fill").font(.system(size:54,weight:.light)).foregroundStyle(app?.color ?? .white)
            Text(app?.name ?? "App").font(.system(size:20,weight:.bold,design:.rounded)).foregroundStyle(.white)
            Text("In sviluppoâ€¦").font(.system(size:13)).foregroundStyle(.white.opacity(0.4))
                .padding(.horizontal,14).padding(.vertical,6).background(Color.white.opacity(0.04)).clipShape(Capsule())
        }.frame(maxWidth:.infinity,maxHeight:.infinity).background(.black.opacity(0.3))
    }
}
