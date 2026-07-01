import SwiftUI

struct SpotifyTransportBar: View {
    @ObservedObject var vm: SpotifyViewModel

    var body: some View {
        VStack(spacing: 8) {
            if vm.playback.hasTrack {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.12))
                        Capsule()
                            .fill(SpotifyPalette.accent)
                            .frame(width: max(0, geo.size.width * vm.playback.progress))
                    }
                }
                .frame(height: 3)
                .padding(.horizontal, 14)
            }

            HStack(spacing: 12) {
                SpotifyArtwork(url: vm.playback.artworkURL, size: 44)

                VStack(alignment: .leading, spacing: 2) {
                    Text(vm.playback.hasTrack ? vm.playback.title : "Nessuna riproduzione")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(SpotifyPalette.textPrimary)
                        .lineLimit(1)
                    Text(vm.playback.hasTrack ? vm.playback.artist : "Avvia un brano nel player")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(SpotifyPalette.textSecondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 4) {
                    transportButton(
                        icon: vm.playback.shuffleOn ? "shuffle" : "shuffle",
                        active: vm.playback.shuffleOn,
                        action: vm.toggleShuffle
                    )
                    transportButton(icon: "backward.fill", size: 16, action: vm.previousTrack)
                    Button(action: vm.playPause) {
                        Image(systemName: vm.playback.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(SpotifyPalette.background)
                            .frame(width: 36, height: 36)
                            .background(SpotifyPalette.accent)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    transportButton(icon: "forward.fill", size: 16, action: vm.nextTrack)
                    transportButton(
                        icon: vm.playback.repeatMode == .track ? "repeat.1" : "repeat",
                        active: vm.playback.repeatMode != .off,
                        action: vm.toggleRepeat
                    )
                }
            }
            .padding(.horizontal, 14)
        }
        .padding(.vertical, 10)
        .background(SpotifyPalette.bar)
        .overlay(alignment: .top) {
            Rectangle().fill(SpotifyPalette.divider).frame(height: 0.5)
        }
    }

    private func transportButton(icon: String, size: CGFloat = 14, active: Bool = false,
                                 action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size, weight: .semibold))
                .foregroundStyle(active ? SpotifyPalette.accent : SpotifyPalette.textSecondary)
                .frame(width: 30, height: 30)
        }
        .buttonStyle(.plain)
    }
}

struct SpotifyArtwork: View {
    let url: URL?
    var size: CGFloat = 44

    var body: some View {
        Group {
            if let url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        artworkPlaceholder
                    }
                }
            } else {
                artworkPlaceholder
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }

    private var artworkPlaceholder: some View {
        ZStack {
            Color.white.opacity(0.08)
            Image(systemName: "music.note")
                .font(.system(size: size * 0.35))
                .foregroundStyle(SpotifyPalette.accentDim)
        }
    }
}
