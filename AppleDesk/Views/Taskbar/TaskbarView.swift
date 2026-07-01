import SwiftUI
import AVFoundation

// MARK: - TaskbarView
struct TaskbarView: View {
    @EnvironmentObject var desktopVM: DesktopViewModel
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var weatherService: WeatherService
    @EnvironmentObject var spotifyVM: SpotifyViewModel

    private var spotifyIsOpen: Bool {
        desktopVM.openWindows.contains { $0.appID == "spotify" }
    }

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            WeatherPill()
            if spotifyIsOpen, spotifyVM.playback.hasTrack {
                SpotifyNowPlayingPill()
            }
            DockPill()
            StatusPill()
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 2)
        .animation(.spring(duration: 0.35, bounce: 0.12), value: spotifyVM.playback.title)
    }
}

// MARK: - Weather Pill
struct WeatherPill: View {
    @EnvironmentObject var weatherService: WeatherService

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: weatherService.weather.symbolName)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(.white)
            Text("\(Int(weatherService.weather.temperature))°")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 14)
        .frame(height: 52)
        .background(.ultraThinMaterial)
        .environment(\.colorScheme, .dark)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
            .stroke(.white.opacity(0.15), lineWidth: 0.5))
    }
}

// MARK: - Dock Pill
struct DockPill: View {
    @EnvironmentObject var desktopVM: DesktopViewModel

    var body: some View {
        HStack(spacing: 12) {
            Spacer()
            Button(action: { desktopVM.toggleStartMenu() }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.white.opacity(desktopVM.showStartMenu ? 0.35 : 0.0))
                        .frame(width: 44, height: 44)
                    Image(systemName: "applelogo")
                        .font(.system(size: 26, weight: .medium))
                        .foregroundStyle(.white)
                }
            }
            .buttonStyle(.plain)

            Rectangle()
                .fill(.white.opacity(0.2))
                .frame(width: 1, height: 24)
                .padding(.horizontal, 4)

            ForEach(desktopVM.taskbarApps) { app in
                DockIcon(
                    app: app,
                    isOpen: desktopVM.openWindows.contains { $0.appID == app.id },
                    action: {
                        withAnimation(.spring(duration: 0.3, bounce: 0.25)) {
                            desktopVM.openApp(app)
                            if desktopVM.showStartMenu { desktopVM.toggleStartMenu() }
                        }
                    },
                    onClose: { desktopVM.closeApp(app.id) }
                )
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
        .frame(height: 52)
        .background(.ultraThinMaterial)
        .environment(\.colorScheme, .dark)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
            .stroke(.white.opacity(0.15), lineWidth: 0.5))
        .animation(.spring(duration: 0.3, bounce: 0.2), value: desktopVM.taskbarApps.map(\.id))
    }
}

struct DockIcon: View {
    let app: AppItem
    let isOpen: Bool
    let action: () -> Void
    let onClose: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isOpen ? Color.white.opacity(0.18) : Color.white.opacity(0.0))
                    .frame(width: 40, height: 40)
                if let asset = app.iconAsset {
                    Image(asset)
                        .resizable().scaledToFit()
                        .frame(width: 29, height: 29)
                } else {
                    Image(systemName: app.icon)
                        .resizable().scaledToFit()
                        .frame(width: 22, height: 22)
                        .foregroundStyle(app.color == .clear ? .white : app.color)
                }
            }
        }
        .buttonStyle(.plain)
        .overlay {
            MiddleClickOverlay {
                if isOpen { onClose() }
            }
        }
        .overlay(alignment: .bottom) {
            if isOpen {
                Circle()
                    .fill(.white.opacity(0.85))
                    .frame(width: 3, height: 3)
                    .offset(y: 6)
            }
        }
        .transition(.scale.combined(with: .opacity))
    }
}

// MARK: - Status Pill
struct StatusPill: View {
    @EnvironmentObject var desktopVM: DesktopViewModel
    @EnvironmentObject var batteryService: BatteryService
    @EnvironmentObject var spotifyVM: SpotifyViewModel
    @State private var now = Date()
    @State private var showControlCenter = false
    let clock = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var spotifyIsOpen: Bool {
        desktopVM.openWindows.contains { $0.appID == "spotify" }
    }

    var body: some View {
        Button(action: { showControlCenter.toggle() }) {
            HStack(spacing: 12) {
                BatteryView(level: batteryService.level, charging: batteryService.isCharging)
                Rectangle().fill(.white.opacity(0.2)).frame(width: 1, height: 18)
                VStack(alignment: .trailing, spacing: 1) {
                    Text(now, format: .dateTime.hour().minute())
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(now, format: .dateTime.day().month(.abbreviated))
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.55))
                }
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
        .frame(height: 52)
        .background(.ultraThinMaterial)
        .environment(\.colorScheme, .dark)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
            .stroke(.white.opacity(0.15), lineWidth: 0.5))
        .popover(isPresented: $showControlCenter) {
            ControlCenterView(spotifyIsOpen: spotifyIsOpen)
                .environmentObject(spotifyVM)
                .presentationCompactAdaptation(.popover)
        }
        .onChange(of: showControlCenter) { _, open in
            desktopVM.taskbarPinned = open || desktopVM.showStartMenu
            if open { desktopVM.showTaskbar() }
            else if !desktopVM.showStartMenu { desktopVM.hideTaskbarIfNeeded() }
        }
        .onReceive(clock) { d in now = d }
    }
}

// MARK: - Battery
struct BatteryView: View {
    let level: Float
    let charging: Bool

    var barColor: Color {
        if charging { return .green }
        if level < 0.2 { return .red }
        if level < 0.4 { return .orange }
        return .white
    }

    var body: some View {
        HStack(spacing: 3) {
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2.5)
                    .stroke(.white.opacity(0.5), lineWidth: 1)
                    .frame(width: 22, height: 11)
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(barColor)
                    .frame(width: max(1, CGFloat(level) * 18), height: 7)
                    .padding(.leading, 2)
            }
            .overlay(alignment: .trailing) {
                RoundedRectangle(cornerRadius: 1)
                    .fill(.white.opacity(0.5))
                    .frame(width: 2, height: 5)
                    .offset(x: 3)
            }
            if charging {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.green)
            }
        }
    }
}

// MARK: - Control Center
struct ControlCenterView: View {
    let spotifyIsOpen: Bool
    @EnvironmentObject var spotifyVM: SpotifyViewModel

    @State private var brightness: Double = 0.5
    @State private var volume: Double = Double(AVAudioSession.sharedInstance().outputVolume)

    let volTimer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                TimelineView(.periodic(from: Date(), by: 1)) { ctx in
                    Text(ctx.date, format: .dateTime.hour().minute().second())
                        .font(.system(size: 42, weight: .light, design: .rounded))
                        .foregroundStyle(.white)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                }
                .padding(.top, 10)

                VStack(spacing: 16) {
                    HStack(spacing: 10) {
                        Image(systemName: "sun.min.fill")
                            .foregroundStyle(.white.opacity(0.5))
                            .font(.system(size: 13))
                        Slider(value: $brightness, in: 0...1)
                            .tint(.white)
                            .onChange(of: brightness) { _, v in
                                if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                                    scene.screen.brightness = v
                                }
                            }
                        Image(systemName: "sun.max.fill")
                            .foregroundStyle(.white.opacity(0.9))
                            .font(.system(size: 16))
                    }

                    Divider().background(.white.opacity(0.15))

                    HStack(spacing: 10) {
                        Image(systemName: volume < 0.01 ? "speaker.slash.fill" : volume < 0.4 ? "speaker.fill" : "speaker.wave.2.fill")
                            .foregroundStyle(.white.opacity(0.5))
                            .font(.system(size: 13))
                        GeometryReader { g in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(.white.opacity(0.15))
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(.white)
                                    .frame(width: g.size.width * volume)
                                    .animation(.spring(duration: 0.3), value: volume)
                            }
                        }
                        .frame(height: 4)
                        Image(systemName: "speaker.wave.3.fill")
                            .foregroundStyle(.white.opacity(0.9))
                            .font(.system(size: 16))
                    }
                    Text("Volume: \(Int(volume * 100))%  •  Usa i tasti volume fisici")
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.35))
                }
                .padding(16)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                if spotifyIsOpen {
                    SpotifyControlCenterSection(spotifyVM: spotifyVM)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .padding(24)
        }
        .frame(width: 300)
        .background(.ultraThinMaterial)
        .environment(\.colorScheme, .dark)
        .animation(.spring(duration: 0.35, bounce: 0.1), value: spotifyIsOpen)
        .animation(.spring(duration: 0.3), value: spotifyVM.playback.title)
        .onReceive(volTimer) { _ in
            let v = Double(AVAudioSession.sharedInstance().outputVolume)
            if abs(v - volume) > 0.005 { volume = v }
        }
        .onAppear {
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                brightness = Double(scene.screen.brightness)
            }
        }
    }
}
