import SwiftUI

/// Sfondo condiviso tra desktop e schermata di accesso.
struct DesktopWallpaper: View {
    @EnvironmentObject private var settingsVM: SettingsViewModel

    var body: some View {
        LinearGradient(
            colors: settingsVM.wallpaper.colors,
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}
