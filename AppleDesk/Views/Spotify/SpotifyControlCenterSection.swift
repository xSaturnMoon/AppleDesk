import SwiftUI

struct SpotifyControlCenterSection: View {
    @ObservedObject var spotifyVM: SpotifyViewModel

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 6) {
                Image("spotify_icon")
                    .resizable().scaledToFit()
                    .frame(width: 16, height: 16)
                Text("Spotify")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.6))
                Spacer()
                if spotifyVM.playback.isPlaying {
                    Image(systemName: "waveform")
                        .font(.system(size: 12))
                        .foregroundStyle(SpotifyPalette.accent)
                        .symbolEffect(.variableColor.iterative, options: .repeating)
                }
            }

            if spotifyVM.playback.hasTrack {
                HStack(spacing: 12) {
                    SpotifyArtwork(url: spotifyVM.playback.artworkURL, size: 52)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(spotifyVM.playback.title)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                        Text(spotifyVM.playback.artist)
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.55))
                            .lineLimit(1)
                    }
                    Spacer()
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.12))
                        Capsule()
                            .fill(SpotifyPalette.accent)
                            .frame(width: max(0, geo.size.width * spotifyVM.playback.progress))
                    }
                }
                .frame(height: 3)

                HStack(spacing: 0) {
                    ccButton(
                        icon: spotifyVM.playback.shuffleOn ? "shuffle" : "shuffle",
                        active: spotifyVM.playback.shuffleOn,
                        action: spotifyVM.toggleShuffle
                    )
                    ccButton(icon: "backward.fill", size: 20, action: spotifyVM.previousTrack)
                    Button(action: spotifyVM.playPause) {
                        Image(systemName: spotifyVM.playback.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 26))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.plain)
                    ccButton(icon: "forward.fill", size: 20, action: spotifyVM.nextTrack)
                    ccButton(
                        icon: spotifyVM.playback.repeatMode == .track ? "repeat.1" : "repeat",
                        active: spotifyVM.playback.repeatMode != .off,
                        action: spotifyVM.toggleRepeat
                    )
                }
            } else {
                Text(spotifyVM.isSessionActive ? "Nessuna canzone in riproduzione" : "Apri Spotify per ascoltare")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.4))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func ccButton(icon: String, size: CGFloat = 15, active: Bool = false,
                          action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size))
                .foregroundStyle(active ? SpotifyPalette.accent : .white.opacity(0.55))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
    }
}
