import SwiftUI
import AVFoundation

@MainActor
final class SettingsViewModel: ObservableObject {
    // MARK: - Keys
    private enum Key {
        static let wallpaper = "appledesk_wallpaper"
        static let accent = "appledesk_accent"
        static let deviceName = "appledesk_deviceName"
        static let taskbarAlwaysVisible = "appledesk_taskbarAlwaysVisible"
        static let showWeatherInTaskbar = "appledesk_showWeatherInTaskbar"
        static let reduceMotion = "appledesk_reduceMotion"
        static let liquidGlass = "appledesk_liquidGlass"
        static let dockIconScale = "appledesk_dockIconScale"
        static let weatherUseGPS = "appledesk_weatherUseGPS"
        static let weatherCityID = "appledesk_weatherCityID"
        static let batteryMock = "appledesk_batteryMock"
        static let batteryMockLevel = "appledesk_batteryMockLevel"
        static let batteryMockCharging = "appledesk_batteryMockCharging"
        static let showBatteryPercent = "appledesk_showBatteryPercent"
        static let blurIntensity = "appledesk_blurIntensity"
    }

    // MARK: - Published
    @Published var wallpaper: WallpaperStyle { didSet { persist(Key.wallpaper, wallpaper.rawValue) } }
    @Published var accent: SettingsAccent { didSet { persist(Key.accent, accent.rawValue) } }
    @Published var deviceName: String { didSet { persist(Key.deviceName, deviceName) } }
    @Published var taskbarAlwaysVisible: Bool { didSet { persist(Key.taskbarAlwaysVisible, taskbarAlwaysVisible) } }
    @Published var showWeatherInTaskbar: Bool { didSet { persist(Key.showWeatherInTaskbar, showWeatherInTaskbar) } }
    @Published var reduceMotion: Bool { didSet { persist(Key.reduceMotion, reduceMotion) } }
    @Published var liquidGlassEnabled: Bool { didSet { persist(Key.liquidGlass, liquidGlassEnabled) } }
    @Published var dockIconScale: Double { didSet { persist(Key.dockIconScale, dockIconScale) } }
    @Published var weatherUseGPS: Bool { didSet { persist(Key.weatherUseGPS, weatherUseGPS); refreshWeather() } }
    @Published var weatherCityID: String { didSet { persist(Key.weatherCityID, weatherCityID); refreshWeather() } }
    @Published var batteryUseMock: Bool { didSet { persist(Key.batteryMock, batteryUseMock); syncBattery() } }
    @Published var batteryMockLevel: Double { didSet { persist(Key.batteryMockLevel, batteryMockLevel); syncBattery() } }
    @Published var batteryMockCharging: Bool { didSet { persist(Key.batteryMockCharging, batteryMockCharging); syncBattery() } }
    @Published var showBatteryPercent: Bool { didSet { persist(Key.showBatteryPercent, showBatteryPercent) } }
    @Published var blurIntensity: Double { didSet { persist(Key.blurIntensity, blurIntensity) } }

    @Published var systemBrightness: Double = 0.5
    @Published var systemVolume: Double = 0.5

    private weak var weatherService: WeatherService?
    private weak var batteryService: BatteryService?
    private weak var desktopVM: DesktopViewModel?

    var selectedWeatherCity: WeatherCity {
        WeatherCity.presets.first { $0.id == weatherCityID } ?? WeatherCity.presets[0]
    }

    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    init() {
        let d = UserDefaults.standard
        wallpaper = WallpaperStyle(rawValue: d.string(forKey: Key.wallpaper) ?? "") ?? .graphite
        accent = SettingsAccent(rawValue: d.string(forKey: Key.accent) ?? "") ?? .blue
        deviceName = d.string(forKey: Key.deviceName) ?? "iPad di AppleDesk"
        taskbarAlwaysVisible = d.object(forKey: Key.taskbarAlwaysVisible) as? Bool ?? false
        showWeatherInTaskbar = d.object(forKey: Key.showWeatherInTaskbar) as? Bool ?? true
        reduceMotion = d.object(forKey: Key.reduceMotion) as? Bool ?? false
        liquidGlassEnabled = d.object(forKey: Key.liquidGlass) as? Bool ?? true
        dockIconScale = d.object(forKey: Key.dockIconScale) as? Double ?? 1.0
        weatherUseGPS = d.object(forKey: Key.weatherUseGPS) as? Bool ?? true
        weatherCityID = d.string(forKey: Key.weatherCityID) ?? "parma"
        batteryUseMock = d.object(forKey: Key.batteryMock) as? Bool ?? false
        batteryMockLevel = d.object(forKey: Key.batteryMockLevel) as? Double ?? 0.72
        batteryMockCharging = d.object(forKey: Key.batteryMockCharging) as? Bool ?? false
        showBatteryPercent = d.object(forKey: Key.showBatteryPercent) as? Bool ?? false
        blurIntensity = d.object(forKey: Key.blurIntensity) as? Double ?? 28

        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            systemBrightness = Double(scene.screen.brightness)
        }
        systemVolume = Double(AVAudioSession.sharedInstance().outputVolume)
    }

    func bind(weather: WeatherService, battery: BatteryService, desktop: DesktopViewModel) {
        weatherService = weather
        batteryService = battery
        desktopVM = desktop
        applyDesktopSettings()
        syncBattery()
        refreshWeather()
    }

    func applyDesktopSettings() {
        guard let desktopVM else { return }
        desktopVM.taskbarAlwaysVisible = taskbarAlwaysVisible
        if taskbarAlwaysVisible { desktopVM.showTaskbar() }
    }

    func syncBattery() {
        batteryService?.configureMock(
            useMock: batteryUseMock,
            level: Float(batteryMockLevel),
            charging: batteryMockCharging
        )
    }

    func refreshWeather() {
        guard let weatherService else { return }
        let city = selectedWeatherCity
        weatherService.configure(useGPS: weatherUseGPS, city: city)
        Task { await weatherService.refresh() }
    }

    func setBrightness(_ value: Double) {
        systemBrightness = value
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            scene.screen.brightness = CGFloat(value)
        }
    }

    func setVolume(_ value: Double) {
        systemVolume = value
    }

    func resetWindowLayout() {
        desktopVM?.resetWindowLayout()
    }

    func resetAllSettings() {
        let keys = [
            Key.wallpaper, Key.accent, Key.deviceName, Key.taskbarAlwaysVisible,
            Key.showWeatherInTaskbar, Key.reduceMotion, Key.liquidGlass, Key.dockIconScale,
            Key.weatherUseGPS, Key.weatherCityID, Key.batteryMock, Key.batteryMockLevel,
            Key.batteryMockCharging, Key.showBatteryPercent, Key.blurIntensity
        ]
        keys.forEach { UserDefaults.standard.removeObject(forKey: $0) }
        wallpaper = .graphite
        accent = .blue
        deviceName = "iPad di AppleDesk"
        taskbarAlwaysVisible = false
        showWeatherInTaskbar = true
        reduceMotion = false
        liquidGlassEnabled = true
        dockIconScale = 1.0
        weatherUseGPS = true
        weatherCityID = "parma"
        batteryUseMock = false
        batteryMockLevel = 0.72
        batteryMockCharging = false
        showBatteryPercent = false
        blurIntensity = 28
        applyDesktopSettings()
        syncBattery()
        refreshWeather()
    }

    private func persist(_ key: String, _ value: Any) {
        UserDefaults.standard.set(value, forKey: key)
        if key == Key.taskbarAlwaysVisible { applyDesktopSettings() }
    }
}
