import SwiftUI

// MARK: - Palette & spacing (design system Zen)
enum ZenPalette {
    static let canvas = Color(red: 0.09, green: 0.09, blue: 0.095)
    static let canvasElevated = Color(red: 0.11, green: 0.11, blue: 0.115)
    static let accent = Color(red: 0.95, green: 0.44, blue: 0.40)
    static let textPrimary = Color.white.opacity(0.92)
    static let textSecondary = Color.white.opacity(0.42)
    static let textTertiary = Color.white.opacity(0.28)
    static let stroke = Color.white.opacity(0.07)
    static let rowHover = Color.white.opacity(0.06)
    static let rowActive = Color.white.opacity(0.10)

    static let sidebarWidth: CGFloat = 216
    static let sidebarCollapsedWidth: CGFloat = 56
    static let horizontalPadding: CGFloat = 14
    static let rowRadius: CGFloat = 10
    static let barRadius: CGFloat = 12
}

// MARK: - Glass surfaces
struct ZenGlassSurface: ViewModifier {
    var radius: CGFloat = ZenPalette.barRadius

    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .environment(\.colorScheme, .dark)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(ZenPalette.stroke, lineWidth: 0.5)
            )
    }
}

struct ZenInsetField: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: ZenPalette.barRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: ZenPalette.barRadius, style: .continuous)
                    .stroke(ZenPalette.stroke, lineWidth: 0.5)
            )
    }
}

extension View {
    func zenGlass(radius: CGFloat = ZenPalette.barRadius) -> some View {
        modifier(ZenGlassSurface(radius: radius))
    }

    func zenInsetField() -> some View {
        modifier(ZenInsetField())
    }
}

// MARK: - Icona Zen (anello concentrici — per overlay senza sfondo squircle)
struct ZenMark: View {
    var size: CGFloat = 48
    var ringColor: Color = ZenPalette.cream

    private static let cream = Color(red: 0.96, green: 0.94, blue: 0.90)

    var body: some View {
        ZStack {
            Circle()
                .stroke(ringColor, lineWidth: size * 0.045)
                .frame(width: size * 0.88, height: size * 0.88)
            Circle()
                .stroke(ringColor, lineWidth: size * 0.11)
                .frame(width: size * 0.58, height: size * 0.58)
            Circle()
                .stroke(ringColor, lineWidth: size * 0.045)
                .frame(width: size * 0.28, height: size * 0.28)
        }
        .frame(width: size, height: size)
    }
}

// Alias per compatibilità con ZenPalette
extension ZenPalette {
    static let cream = Color(red: 0.96, green: 0.94, blue: 0.90)
}
