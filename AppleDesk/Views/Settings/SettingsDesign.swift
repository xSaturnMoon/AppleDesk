import SwiftUI

enum SettingsPalette {
    static let canvas = Color(red: 0.07, green: 0.07, blue: 0.075)
    static let sidebarWidth: CGFloat = 240
    static let textPrimary = Color.white.opacity(0.92)
    static let textSecondary = Color.white.opacity(0.48)
    static let textTertiary = Color.white.opacity(0.30)
}

// MARK: - Liquid Glass helpers

struct SettingsGlassCard: ViewModifier {
    let enabled: Bool
    var radius: CGFloat = 14

    func body(content: Content) -> some View {
        if enabled {
            content
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
        } else {
            content
                .background(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
                .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .stroke(.white.opacity(0.12), lineWidth: 0.5)
                )
        }
    }
}

extension View {
    func settingsGlass(_ enabled: Bool, radius: CGFloat = 14) -> some View {
        modifier(SettingsGlassCard(enabled: enabled, radius: radius))
    }
}

// MARK: - Reusable rows

struct SettingsToggleRow: View {
    let title: String
    let subtitle: String?
    @Binding var isOn: Bool
    let accent: Color
    let glass: Bool

    init(_ title: String, subtitle: String? = nil, isOn: Binding<Bool>,
         accent: Color, glass: Bool) {
        self.title = title
        self.subtitle = subtitle
        self._isOn = isOn
        self.accent = accent
        self.glass = glass
    }

    var body: some View {
        Toggle(isOn: $isOn) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(SettingsPalette.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(SettingsPalette.textSecondary)
                }
            }
        }
        .tint(accent)
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .settingsGlass(glass, radius: 12)
    }
}

struct SettingsSliderRow: View {
    let title: String
    let valueLabel: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let accent: Color
    let glass: Bool
    var onChange: ((Double) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(SettingsPalette.textPrimary)
                Spacer()
                Text(valueLabel)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(accent)
                    .monospacedDigit()
            }
            Slider(value: $value, in: range)
                .tint(accent)
                .onChange(of: value) { _, v in onChange?(v) }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .settingsGlass(glass, radius: 12)
    }
}

struct SettingsSectionHeader: View {
    let title: String
    let subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(SettingsPalette.textPrimary)
            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(SettingsPalette.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 4)
    }
}

struct SettingsGroupLabel: View {
    let text: String
    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 10, weight: .semibold))
            .kerning(0.6)
            .foregroundStyle(SettingsPalette.textTertiary)
            .padding(.leading, 4)
            .padding(.top, 8)
    }
}

struct WallpaperSwatch: View {
    let style: WallpaperStyle
    let selected: Bool
    let glass: Bool

    var body: some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(LinearGradient(colors: style.colors, startPoint: .top, endPoint: .bottom))
                .frame(height: 56)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(selected ? Color.white : Color.white.opacity(0.15),
                                lineWidth: selected ? 2.5 : 0.5)
                )
                .overlay(alignment: .topTrailing) {
                    if selected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .shadow(radius: 4)
                            .padding(6)
                    }
                }
            Text(style.title)
                .font(.system(size: 11, weight: selected ? .semibold : .regular, design: .rounded))
                .foregroundStyle(selected ? .white : SettingsPalette.textSecondary)
        }
    }
}
