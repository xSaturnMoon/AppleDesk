import SwiftUI
import AVFoundation

struct SettingsWindowContent: View {
    @EnvironmentObject var settingsVM: SettingsViewModel
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var desktopVM: DesktopViewModel
    @EnvironmentObject var weatherService: WeatherService
    @EnvironmentObject var batteryService: BatteryService

    @State private var section: SettingsSection = .general
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var profileMessage: String?
    @Namespace private var glassNS

    private var accent: Color { settingsVM.accent.color }
    private var glass: Bool { settingsVM.liquidGlassEnabled }
    private var anim: Animation {
        settingsVM.reduceMotion
            ? .linear(duration: 0.15)
            : .spring(duration: 0.35, bounce: 0.08)
    }

    var body: some View {
        HStack(spacing: 0) {
            sidebar
            detail
        }
        .background(SettingsPalette.canvas)
        .onAppear {
            settingsVM.bind(weather: weatherService, battery: batteryService, desktop: desktopVM)
        }
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        GlassEffectContainer {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 10) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(accent)
                        Text("Impostazioni")
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundStyle(SettingsPalette.textPrimary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 18)
                    .padding(.bottom, 12)

                    ForEach(SettingsSection.allCases) { item in
                        sidebarRow(item)
                    }
                }
                .padding(.bottom, 16)
            }
        }
        .frame(width: SettingsPalette.sidebarWidth)
        .background {
            if glass {
                Color.clear.glassEffect(.regular, in: Rectangle())
            } else {
                Color.black.opacity(0.25)
            }
        }
    }

    private func sidebarRow(_ item: SettingsSection) -> some View {
        Button {
            withAnimation(anim) { section = item }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: item.icon)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(section == item ? accent : SettingsPalette.textSecondary)
                    .frame(width: 22)
                Text(item.title)
                    .font(.system(size: 14, weight: section == item ? .semibold : .regular, design: .rounded))
                    .foregroundStyle(section == item ? SettingsPalette.textPrimary : SettingsPalette.textSecondary)
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background {
                if section == item {
                    Group {
                        if glass {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(.clear)
                                .glassEffect(.regular.tint(accent.opacity(0.35)), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                                .glassEffectID(item.id, in: glassNS)
                        } else {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(accent.opacity(0.18))
                        }
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 10)
    }

    // MARK: - Detail

    private var detail: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                switch section {
                case .general: generalSection
                case .appearance: appearanceSection
                case .desktop: desktopSection
                case .account: accountSection
                case .weather: weatherSection
                case .energy: energySection
                case .sound: soundSection
                case .privacy: privacySection
                case .system: systemSection
                }
            }
            .padding(28)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(
            LinearGradient(
                colors: [Color.white.opacity(0.02), Color.clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    // MARK: - Sections

    private var generalSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SettingsSectionHeader(title: "Generale", subtitle: "Informazioni sul dispositivo e su AppleDesk")

            GlassEffectContainer {
                VStack(spacing: 10) {
                    editableInfoRow("Nome dispositivo", value: $settingsVM.deviceName)
                    Divider().opacity(0.15)
                    staticInfoRow("Sistema", value: "AppleDesk OS")
                    Divider().opacity(0.15)
                    staticInfoRow("Versione", value: settingsVM.appVersion)
                    Divider().opacity(0.15)
                    staticInfoRow("Piattaforma", value: "iPadOS 26")
                }
                .padding(14)
                .settingsGlass(glass, radius: 14)
            }

            SettingsGroupLabel(text: "Informazioni")
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(accent.opacity(0.2))
                        .frame(width: 64, height: 64)
                    Image(systemName: "laptopcomputer")
                        .font(.system(size: 28, weight: .light))
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(settingsVM.deviceName)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Simulatore desktop per iPad con Liquid Glass")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundStyle(SettingsPalette.textSecondary)
                }
            }
            .padding(14)
            .settingsGlass(glass, radius: 14)
        }
    }

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SettingsSectionHeader(title: "Aspetto", subtitle: "Personalizza sfondo, colori e materiali")

            SettingsGroupLabel(text: "Sfondo desktop")
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 12)], spacing: 12) {
                ForEach(WallpaperStyle.allCases) { style in
                    Button {
                        withAnimation(anim) { settingsVM.wallpaper = style }
                    } label: {
                        WallpaperSwatch(style: style, selected: settingsVM.wallpaper == style, glass: glass)
                    }
                    .buttonStyle(.plain)
                }
            }

            SettingsGroupLabel(text: "Colore d'accento")
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 10) {
                ForEach(SettingsAccent.allCases) { item in
                    Button {
                        withAnimation(anim) { settingsVM.accent = item }
                    } label: {
                        HStack(spacing: 8) {
                            Circle().fill(item.color).frame(width: 14, height: 14)
                            Text(item.title)
                                .font(.system(size: 12, weight: settingsVM.accent == item ? .semibold : .regular))
                                .foregroundStyle(settingsVM.accent == item ? .white : SettingsPalette.textSecondary)
                            Spacer()
                            if settingsVM.accent == item {
                                Image(systemName: "checkmark").font(.system(size: 10, weight: .bold)).foregroundStyle(item.color)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .settingsGlass(glass, radius: 10)
                    }
                    .buttonStyle(.plain)
                }
            }

            SettingsToggleRow("Liquid Glass", subtitle: "Materiali ufficiali iPadOS 26",
                              isOn: $settingsVM.liquidGlassEnabled, accent: accent, glass: glass)
            SettingsSliderRow(title: "Intensità blur login", valueLabel: "\(Int(settingsVM.blurIntensity)) px",
                              value: $settingsVM.blurIntensity, range: 8...48, accent: accent, glass: glass)
            SettingsToggleRow("Riduci movimento", subtitle: "Animazioni più sobrie",
                              isOn: $settingsVM.reduceMotion, accent: accent, glass: glass)
        }
    }

    private var desktopSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SettingsSectionHeader(title: "Desktop e Dock", subtitle: "Taskbar, finestre e icone")

            SettingsToggleRow("Taskbar sempre visibile", subtitle: "Non nascondere la barra in fullscreen",
                              isOn: $settingsVM.taskbarAlwaysVisible, accent: accent, glass: glass)
            SettingsToggleRow("Meteo nella taskbar", isOn: $settingsVM.showWeatherInTaskbar,
                              accent: accent, glass: glass)
            SettingsSliderRow(title: "Dimensione icone dock", valueLabel: "\(Int(settingsVM.dockIconScale * 100))%",
                              value: $settingsVM.dockIconScale, range: 0.85...1.25, accent: accent, glass: glass)

            Button { settingsVM.resetWindowLayout() } label: {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Ripristina layout finestre")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .settingsGlass(glass, radius: 12)
            }
            .buttonStyle(.plain)
        }
    }

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SettingsSectionHeader(title: "Account", subtitle: "Profilo e accesso")

            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(authVM.avatarColor.opacity(0.35))
                        .frame(width: 72, height: 72)
                    Text(String(authVM.username.prefix(1)).uppercased())
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(authVM.username.isEmpty ? "Utente" : authVM.username)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Account locale AppleDesk")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundStyle(SettingsPalette.textSecondary)
                }
            }
            .padding(14)
            .settingsGlass(glass, radius: 14)

            SettingsGroupLabel(text: "Colore avatar")
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 7), spacing: 10) {
                ForEach([Color.blue, .purple, .pink, .orange, .green, .cyan, .indigo], id: \.self) { color in
                    Circle()
                        .fill(color)
                        .frame(width: 32, height: 32)
                        .overlay(Circle().stroke(.white, lineWidth: authVM.avatarColor == color ? 2.5 : 0).padding(-3))
                        .onTapGesture { authVM.updateAvatarColor(color) }
                }
            }

            if authVM.hasRegisteredAccount {
                VStack(spacing: 10) {
                    SecureField("Nuova password", text: $newPassword)
                    SecureField("Conferma password", text: $confirmPassword)
                    Button("Aggiorna password") {
                        let ok = authVM.changePassword(new: newPassword, confirm: confirmPassword)
                        profileMessage = ok ? "Password aggiornata" : (authVM.error ?? "Errore")
                        if ok { newPassword = ""; confirmPassword = "" }
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(accent)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .buttonStyle(.plain)
                }
                .font(.system(size: 14, design: .rounded))
                .foregroundStyle(.white)
                .padding(14)
                .settingsGlass(glass, radius: 12)

                Button {
                    authVM.logout()
                } label: {
                    Text("Esci dall'account")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.orange)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                        .settingsGlass(glass, radius: 12)
                }
                .buttonStyle(.plain)
            }

            if let profileMessage {
                Text(profileMessage)
                    .font(.system(size: 12))
                    .foregroundStyle(accent)
            }
        }
    }

    private var weatherSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SettingsSectionHeader(title: "Meteo", subtitle: "Posizione e aggiornamenti")

            HStack(spacing: 12) {
                Image(systemName: weatherService.weather.symbolName)
                    .font(.system(size: 36))
                    .foregroundStyle(.white)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(Int(weatherService.weather.temperature))° · \(weatherService.weather.condition)")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(weatherService.weather.city)
                        .font(.system(size: 12, design: .rounded))
                        .foregroundStyle(SettingsPalette.textSecondary)
                }
                Spacer()
                Button { settingsVM.refreshWeather() } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(accent)
                        .frame(width: 36, height: 36)
                        .settingsGlass(glass, radius: 10)
                }
                .buttonStyle(.plain)
            }
            .padding(14)
            .settingsGlass(glass, radius: 14)

            SettingsToggleRow("Usa posizione GPS", subtitle: "Altrimenti città manuale",
                              isOn: $settingsVM.weatherUseGPS, accent: accent, glass: glass)

            if !settingsVM.weatherUseGPS {
                SettingsGroupLabel(text: "Città")
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 8)], spacing: 8) {
                    ForEach(WeatherCity.presets) { city in
                        Button {
                            settingsVM.weatherCityID = city.id
                        } label: {
                            Text(city.name)
                                .font(.system(size: 13, weight: settingsVM.weatherCityID == city.id ? .semibold : .regular))
                                .foregroundStyle(settingsVM.weatherCityID == city.id ? .white : SettingsPalette.textSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .settingsGlass(glass, radius: 10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(settingsVM.weatherCityID == city.id ? accent : .clear, lineWidth: 1.5)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var energySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SettingsSectionHeader(title: "Energia", subtitle: "Batteria e indicatori")

            SettingsToggleRow("Mostra percentuale batteria", isOn: $settingsVM.showBatteryPercent,
                              accent: accent, glass: glass)
            SettingsToggleRow("Modalità demo batteria", subtitle: "Simula livello e ricarica",
                              isOn: $settingsVM.batteryUseMock, accent: accent, glass: glass)

            if settingsVM.batteryUseMock {
                SettingsSliderRow(title: "Livello simulato", valueLabel: "\(Int(settingsVM.batteryMockLevel * 100))%",
                                  value: $settingsVM.batteryMockLevel, range: 0.05...1.0,
                                  accent: accent, glass: glass)
                SettingsToggleRow("In carica", isOn: $settingsVM.batteryMockCharging,
                                  accent: accent, glass: glass)
            }
        }
    }

    private var soundSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SettingsSectionHeader(title: "Suono e Schermo", subtitle: "Luminosità e volume di sistema")

            SettingsSliderRow(title: "Luminosità", valueLabel: "\(Int(settingsVM.systemBrightness * 100))%",
                              value: $settingsVM.systemBrightness, range: 0.05...1.0,
                              accent: accent, glass: glass) { settingsVM.setBrightness($0) }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Volume")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(SettingsPalette.textPrimary)
                    Spacer()
                    Text("\(Int(settingsVM.systemVolume * 100))%")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(accent)
                }
                HStack(spacing: 10) {
                    Image(systemName: "speaker.fill").foregroundStyle(SettingsPalette.textSecondary)
                    Slider(value: $settingsVM.systemVolume, in: 0...1)
                        .tint(accent)
                    Image(systemName: "speaker.wave.3.fill").foregroundStyle(SettingsPalette.textSecondary)
                }
                Text("Usa i tasti volume fisici per regolare l'audio di sistema")
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(SettingsPalette.textTertiary)
            }
            .padding(14)
            .settingsGlass(glass, radius: 12)
            .onReceive(Timer.publish(every: 0.8, on: .main, in: .common).autoconnect()) { _ in
                let v = Double(AVAudioSession.sharedInstance().outputVolume)
                if abs(v - settingsVM.systemVolume) > 0.01 { settingsVM.systemVolume = v }
            }
        }
    }

    private var privacySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SettingsSectionHeader(title: "Privacy", subtitle: "Dati e cronologia")

            destructiveButton("Cancella cronologia Zen", icon: "clock.arrow.circlepath") {
                UserDefaults.standard.removeObject(forKey: "zen_history")
            }
            destructiveButton("Ripristina tutte le impostazioni", icon: "arrow.counterclockwise.circle") {
                settingsVM.resetAllSettings()
            }
        }
    }

    private var systemSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SettingsSectionHeader(title: "Sistema", subtitle: "Riavvio e spegnimento")

            actionButton("Riavvia AppleDesk", icon: "arrow.counterclockwise", tint: .white) {
                desktopVM.restart(authVM: authVM)
            }
            actionButton("Spegni", icon: "power", tint: .red.opacity(0.9)) {
                desktopVM.shutdown()
            }

            Text("AppleDesk \(settingsVM.appVersion) · Build iPadOS 26 Simulator")
                .font(.system(size: 11, design: .rounded))
                .foregroundStyle(SettingsPalette.textTertiary)
                .padding(.top, 8)
        }
    }

    // MARK: - Helpers

    private func editableInfoRow(_ label: String, value: Binding<String>) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13, design: .rounded))
                .foregroundStyle(SettingsPalette.textSecondary)
            Spacer()
            TextField("", text: value)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 180)
        }
    }

    private func staticInfoRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13, design: .rounded))
                .foregroundStyle(SettingsPalette.textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.white)
        }
    }

    private func destructiveButton(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                Text(title)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
            }
            .foregroundStyle(.red.opacity(0.85))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .settingsGlass(glass, radius: 12)
        }
        .buttonStyle(.plain)
    }

    private func actionButton(_ title: String, icon: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                Text(title)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
            }
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .settingsGlass(glass, radius: 12)
        }
        .buttonStyle(.plain)
    }
}
