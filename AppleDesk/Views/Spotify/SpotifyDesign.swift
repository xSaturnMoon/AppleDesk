import SwiftUI

enum SpotifyPalette {
    static let background = Color(red: 0.07, green: 0.07, blue: 0.07)
    static let surface = Color(red: 0.11, green: 0.11, blue: 0.11)
    static let bar = Color(red: 0.09, green: 0.09, blue: 0.09)
    static let accent = Color(red: 0.11, green: 0.84, blue: 0.38)
    static let accentDim = Color(red: 0.11, green: 0.84, blue: 0.38).opacity(0.65)
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.55)
    static let divider = Color.white.opacity(0.1)
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
