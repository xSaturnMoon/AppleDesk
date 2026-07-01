import SwiftUI

struct ZenHomePage: View {
    @ObservedObject var vm: ZenViewModel
    let tab: ZenTabModel
    let onSubmit: () -> Void
    @Binding var urlText: String

    private let shortcutColumns = Array(repeating: GridItem(.flexible(), spacing: 20), count: 5)

    var body: some View {
        GeometryReader { geo in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer(minLength: max(24, geo.size.height * 0.12))

                    hero
                        .padding(.bottom, 36)

                    searchBar
                        .frame(maxWidth: 460)
                        .padding(.horizontal, 32)
                        .padding(.bottom, 40)

                    shortcutsGrid
                        .frame(maxWidth: 420)
                        .padding(.horizontal, 32)

                    Spacer(minLength: max(24, geo.size.height * 0.12))
                }
                .frame(maxWidth: .infinity, minHeight: geo.size.height)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ZenPalette.canvas)
    }

    // MARK: Hero

    private var hero: some View {
        VStack(spacing: 16) {
            Image("zen_icon")
                .resizable()
                .scaledToFit()
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: .black.opacity(0.25), radius: 12, y: 4)

            Text(greeting)
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .foregroundStyle(ZenPalette.textPrimary)
                .multilineTextAlignment(.center)

            Text(vm.isPrivateSession ? "SESSIONE PRIVATA" : "ZEN BROWSER")
                .font(.system(size: 10, weight: .semibold))
                .kerning(1.2)
                .foregroundStyle(ZenPalette.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Search

    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(ZenPalette.textTertiary)

            TextField("Cerca con \(vm.searchEngine)", text: $urlText)
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundStyle(ZenPalette.textPrimary)
                .onSubmit(onSubmit)

            Button(action: onSubmit) {
                Image(systemName: "arrow.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 30, height: 30)
                    .background(ZenPalette.accent)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.leading, 16)
        .padding(.trailing, 8)
        .padding(.vertical, 10)
        .zenGlass(radius: 22)
    }

    // MARK: Shortcuts

    private var shortcutsGrid: some View {
        LazyVGrid(columns: shortcutColumns, spacing: 22) {
            ForEach(vm.shortcuts.prefix(5)) { shortcut in
                Button { vm.loadURL(shortcut.url, on: tab) } label: {
                    VStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.05))
                                .frame(width: 52, height: 52)
                                .overlay(Circle().stroke(ZenPalette.stroke, lineWidth: 0.5))
                            Image(systemName: "globe")
                                .font(.system(size: 18, weight: .light))
                                .foregroundStyle(ZenPalette.textSecondary)
                        }
                        Text(shortcut.name)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(ZenPalette.textSecondary)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let period = hour < 13 ? "Buongiorno" : (hour < 18 ? "Buon pomeriggio" : "Buonasera")
        return "\(period), benvenuto su Zen"
    }
}
