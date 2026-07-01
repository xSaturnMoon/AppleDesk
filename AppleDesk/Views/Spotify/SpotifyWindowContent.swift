import SwiftUI

struct SpotifyWindowContent: View {
    @EnvironmentObject var spotifyVM: SpotifyViewModel

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                SpotifyWebView(vm: spotifyVM)

                overlay
            }

            SpotifyTransportBar(vm: spotifyVM)
        }
        .background(SpotifyPalette.background)
        .onAppear { spotifyVM.markWindowAttached(true) }
        .onDisappear { spotifyVM.markWindowAttached(false) }
    }

    @ViewBuilder
    private var overlay: some View {
        switch spotifyVM.loadState {
        case .loading:
            loadingOverlay
        case .loginRequired:
            loginOverlay
        case .error(let message):
            errorOverlay(message: message)
        case .ready:
            EmptyView()
        }
    }

    private var loadingOverlay: some View {
        ZStack {
            SpotifyPalette.background.opacity(0.92)
            VStack(spacing: 14) {
                ProgressView()
                    .tint(SpotifyPalette.accent)
                    .scaleEffect(1.1)
                Text("Caricamento Spotify…")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(SpotifyPalette.textSecondary)
            }
        }
    }

    private var loginOverlay: some View {
        ZStack {
            SpotifyPalette.background.opacity(0.55)
            VStack(spacing: 12) {
                Image("spotify_icon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                Text("Accedi a Spotify")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                Text("Usa email e password nel player.\nI login Google/Facebook potrebbero non funzionare nel browser integrato.")
                    .font(.system(size: 12))
                    .foregroundStyle(SpotifyPalette.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            .padding(20)
            .background(SpotifyPalette.surface.opacity(0.95))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .padding(32)
        }
        .allowsHitTesting(false)
    }

    private func errorOverlay(message: String) -> some View {
        ZStack {
            SpotifyPalette.background.opacity(0.94)
            VStack(spacing: 14) {
                Image(systemName: "wifi.exclamationmark")
                    .font(.system(size: 34, weight: .light))
                    .foregroundStyle(SpotifyPalette.accent)
                Text("Impossibile caricare Spotify")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                Text(message)
                    .font(.system(size: 12))
                    .foregroundStyle(SpotifyPalette.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                Button("Riprova", action: spotifyVM.reload)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(SpotifyPalette.background)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 8)
                    .background(SpotifyPalette.accent)
                    .clipShape(Capsule())
                    .buttonStyle(.plain)
            }
        }
    }
}
