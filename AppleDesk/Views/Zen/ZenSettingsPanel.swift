import SwiftUI

struct ZenSettingsPanel: View {
    @ObservedObject var vm: ZenViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    themeSection
                    searchSection
                    zoomSection
                    boostsSection
                    privacySection
                }
                .padding(18)
            }
            .background(ZenPalette.canvas)
            .navigationTitle("Impostazioni")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fine") { dismiss() }
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(ZenPalette.accent)
                }
            }
        }
        .frame(width: 360, height: 500)
        .background(.ultraThinMaterial)
        .environment(\.colorScheme, .dark)
    }

    private var themeSection: some View {
        settingsCard("Aspetto") {
            ForEach(ZenTheme.allCases) { theme in
                Button { vm.theme = theme } label: {
                    HStack(spacing: 10) {
                        Circle().fill(theme.accent).frame(width: 14, height: 14)
                        Text(theme.rawValue)
                            .font(.system(size: 13, weight: vm.theme == theme ? .semibold : .regular))
                            .foregroundStyle(ZenPalette.textPrimary)
                        Spacer()
                        if vm.theme == theme {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(ZenPalette.accent)
                        }
                    }
                    .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var searchSection: some View {
        settingsCard("Ricerca") {
            HStack(spacing: 8) {
                ForEach(["Google", "DuckDuckGo", "Bing"], id: \.self) { engine in
                    Button { vm.searchEngine = engine } label: {
                        Text(engine)
                            .font(.system(size: 11, weight: vm.searchEngine == engine ? .semibold : .regular))
                            .foregroundStyle(vm.searchEngine == engine ? .white : ZenPalette.textSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(vm.searchEngine == engine ? ZenPalette.accent : Color.white.opacity(0.05))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var zoomSection: some View {
        settingsCard("Zoom — \(Int(vm.zoomLevel * 100))%") {
            HStack(spacing: 12) {
                Button { vm.zoomLevel = max(0.5, vm.zoomLevel - 0.1) } label: {
                    Image(systemName: "minus")
                        .frame(width: 32, height: 32)
                        .zenInsetField()
                }
                .buttonStyle(.plain)
                Slider(value: $vm.zoomLevel, in: 0.5...2.0, step: 0.05).tint(ZenPalette.accent)
                Button { vm.zoomLevel = min(2.0, vm.zoomLevel + 0.1) } label: {
                    Image(systemName: "plus")
                        .frame(width: 32, height: 32)
                        .zenInsetField()
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var boostsSection: some View {
        settingsCard("Boosts") {
            toggleRow("Dark mode", isOn: $vm.boosts.forceDarkMode)
            toggleRow("Testo più grande", isOn: $vm.boosts.largerText)
            toggleRow("Blocca tracker", isOn: $vm.boosts.blockTrackers)
        }
    }

    private var privacySection: some View {
        settingsCard("Privacy") {
            Toggle("Sessione privata", isOn: $vm.isPrivateSession)
                .font(.system(size: 13))
                .tint(ZenPalette.accent)
            Button("Cancella cronologia") {
                vm.history.removeAll()
                UserDefaults.standard.removeObject(forKey: "zen_history")
            }
            .font(.system(size: 13))
            .foregroundStyle(.red.opacity(0.8))
            .frame(maxWidth: .infinity, alignment: .leading)
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
    }

    private func settingsCard<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .kerning(0.5)
                .foregroundStyle(ZenPalette.textTertiary)
            content()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .zenGlass()
    }

    private func toggleRow(_ title: String, isOn: Binding<Bool>) -> some View {
        Toggle(title, isOn: isOn)
            .font(.system(size: 13))
            .foregroundStyle(ZenPalette.textPrimary)
            .tint(ZenPalette.accent)
    }
}
