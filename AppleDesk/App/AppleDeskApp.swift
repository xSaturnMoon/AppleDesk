import SwiftUI

@main
struct AppleDeskApp: App {
    @StateObject private var authVM = AuthViewModel()
    @StateObject private var desktopVM = DesktopViewModel()
    @StateObject private var weatherService = WeatherService()
    @StateObject private var batteryService = BatteryService()
    @StateObject private var spotifyVM = SpotifyViewModel()

    init() {
        // Crea (se serve) la cartella "AppleDesk" con le sottocartelle categoria,
        // visibile in Files.app su "Su iPad".
        FinderService.setupFolderStructureIfNeeded()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authVM)
                .environmentObject(desktopVM)
                .environmentObject(weatherService)
                .environmentObject(batteryService)
                .environmentObject(spotifyVM)
                .preferredColorScheme(.dark)
        }
    }
}
