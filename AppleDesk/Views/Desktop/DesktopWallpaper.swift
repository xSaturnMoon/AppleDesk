import SwiftUI

/// Sfondo condiviso tra desktop e schermata di accesso.
struct DesktopWallpaper: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.13, green: 0.13, blue: 0.14),
                Color(red: 0.09, green: 0.09, blue: 0.10),
                Color(red: 0.06, green: 0.06, blue: 0.07)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}
