import SwiftUI

/// Finestra gioco cloud: carica direttamente la pagina GeForce NOW del titolo.
struct GFNGameWindowContent: View {
    let game: GFNGame
    @StateObject private var browserVM: GFNBrowserViewModel

    init(game: GFNGame) {
        self.game = game
        _browserVM = StateObject(wrappedValue: GFNBrowserViewModel(startURL: game.launchURL))
    }

    var body: some View {
        VStack(spacing: 0) {
            gameHeader
            if game.requiresGamepad {
                GFNGamepadBanner()
            }
            ZStack {
                GFNWebView(vm: browserVM)
                stateOverlay
            }
        }
        .background(Color.black)
    }

    private var gameHeader: some View {
        HStack(spacing: 12) {
            Image(game.id == "cs2" ? "cs2_icon" : "geforcenow_icon")
                .resizable()
                .scaledToFit()
                .frame(width: 26, height: 26)

            VStack(alignment: .leading, spacing: 1) {
                Text(game.name)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("\(game.genre) · \(game.store) · GeForce NOW")
                    .font(.system(size: 10, design: .rounded))
                    .foregroundStyle(GFNPalette.textSecondary)
            }

            Spacer()

            HStack(spacing: 6) {
                cloudBadge
                if browserVM.canGoBack {
                    GFNToolbarButton(icon: "chevron.left", action: browserVM.goBack)
                }
                GFNToolbarButton(icon: "arrow.clockwise", action: browserVM.reload)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(GFNPalette.surface.opacity(0.95))
        .overlay(alignment: .bottom) {
            Rectangle().fill(GFNPalette.nvidiaGreen.opacity(0.25)).frame(height: 1)
        }
    }

    private var cloudBadge: some View {
        HStack(spacing: 5) {
            Image(systemName: "cloud.fill")
                .font(.system(size: 10, weight: .bold))
            Text("CLOUD")
                .font(.system(size: 9, weight: .heavy, design: .rounded))
                .kerning(0.8)
        }
        .foregroundStyle(GFNPalette.nvidiaGreenBright)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(GFNPalette.nvidiaGreen.opacity(0.15))
        .clipShape(Capsule())
    }

    @ViewBuilder
    private var stateOverlay: some View {
        switch browserVM.loadState {
        case .loading:
            ZStack {
                Color.black.opacity(0.92)
                VStack(spacing: 16) {
                    ProgressView()
                        .tint(GFNPalette.nvidiaGreenBright)
                        .scaleEffect(1.2)
                    Text("Avvio \(game.name)…")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Accedi con il tuo account NVIDIA e premi Play")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(GFNPalette.textSecondary)
                }
            }
        case .error(let message):
            ZStack {
                Color.black.opacity(0.95)
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 32))
                        .foregroundStyle(.orange)
                    Text("Errore di connessione")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                    Text(message)
                        .font(.system(size: 11))
                        .foregroundStyle(GFNPalette.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                    Button("Riprova", action: browserVM.reload)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(GFNPalette.nvidiaGreenBright)
                        .clipShape(Capsule())
                        .buttonStyle(.plain)
                }
            }
        case .ready:
            EmptyView()
        }
    }
}

/// Counter-Strike 2 su GeForce NOW.
struct CS2WindowContent: View {
    var body: some View {
        GFNGameWindowContent(game: .counterStrike2)
    }
}
