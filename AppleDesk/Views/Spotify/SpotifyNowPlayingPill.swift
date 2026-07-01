import SwiftUI

/// Mini player sulla taskbar quando Spotify è attivo.
struct SpotifyNowPlayingPill: View {
    @EnvironmentObject var spotifyVM: SpotifyViewModel
    @EnvironmentObject var desktopVM: DesktopViewModel

    private var spotifyWindow: DesktopWindow? {
        desktopVM.openWindows.first { $0.appID == "spotify" }
    }

    private var isMinimized: Bool {
        spotifyWindow?.isMinimized == true
    }

    var body: some View {
        if spotifyVM.playback.hasTrack, spotifyWindow != nil {
            HStack(spacing: 10) {
                SpotifyArtwork(url: spotifyVM.playback.artworkURL, size: 34)

                VStack(alignment: .leading, spacing: 1) {
                    Text(spotifyVM.playback.title)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Text(spotifyVM.playback.artist)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))
                        .lineLimit(1)
                }
                .frame(maxWidth: 140, alignment: .leading)

                HStack(spacing: 6) {
                    Button(action: spotifyVM.previousTrack) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.85))
                    }
                    .buttonStyle(.plain)

                    Button(action: spotifyVM.playPause) {
                        Image(systemName: spotifyVM.playback.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(SpotifyPalette.background)
                            .frame(width: 26, height: 26)
                            .background(SpotifyPalette.accent)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)

                    Button(action: spotifyVM.nextTrack) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.85))
                    }
                    .buttonStyle(.plain)
                }

                if isMinimized {
                    Button {
                        guard let win = spotifyWindow,
                              let idx = desktopVM.openWindows.firstIndex(where: { $0.id == win.id })
                        else { return }
                        withAnimation(.spring(duration: 0.35, bounce: 0.1)) {
                            desktopVM.openWindows[idx].isMinimized = false
                            desktopVM.bringToFront(win.id)
                        }
                    } label: {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.55))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .frame(height: 52)
            .background(.ultraThinMaterial)
            .environment(\.colorScheme, .dark)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(SpotifyPalette.accent.opacity(0.35), lineWidth: 0.5)
            )
            .transition(.move(edge: .leading).combined(with: .opacity))
        }
    }
}
