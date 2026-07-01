import SwiftUI

enum GFNPalette {
    static let nvidiaGreen = Color(red: 0.46, green: 0.73, blue: 0.0)
    static let nvidiaGreenBright = Color(red: 0.56, green: 0.82, blue: 0.08)
    static let background = Color(red: 0.05, green: 0.05, blue: 0.055)
    static let surface = Color(red: 0.10, green: 0.10, blue: 0.11)
    static let textPrimary = Color.white.opacity(0.92)
    static let textSecondary = Color.white.opacity(0.48)
    static let stroke = Color.white.opacity(0.10)
}

struct GFNToolbarButton: View {
    let icon: String
    var label: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                if let label {
                    Text(label)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                }
            }
            .foregroundStyle(GFNPalette.textPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(GFNPalette.stroke, lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }
}

struct GFNGamepadBanner: View {
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "gamecontroller.fill")
                .foregroundStyle(GFNPalette.nvidiaGreenBright)
            Text("Su iPad collega un controller per giocare. Tastiera e mouse servono solo per i menu.")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(GFNPalette.textSecondary)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(GFNPalette.nvidiaGreen.opacity(0.12))
        .overlay(alignment: .bottom) {
            Rectangle().fill(GFNPalette.nvidiaGreen.opacity(0.35)).frame(height: 1)
        }
    }
}
