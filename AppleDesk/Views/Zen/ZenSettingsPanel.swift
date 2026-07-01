import SwiftUI

struct ZenSettingsPanel: View {
    @ObservedObject var vm: ZenViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    themeSection
                    searchSection
                    zoomSection
                    boostsSection
                    privacySection
                }
                .padding(20)
            }
            .background(
                LinearGradient(colors: vm.theme.gradient, startPoint: .top, endPoint: .bottom)
            )
            .navigationTitle("Impostazioni Zen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fine") { dismiss() }
                        .foregroundStyle(vm.theme.accent)
                }
            }
        }
        .frame(width: 360, height: 480)
        .background(.ultraThinMaterial)
        .environment(\.colorScheme, .dark)
    }

    private var themeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Tema")
            ForEach(ZenTheme.allCases) { theme in
                Button {
                    withAnimation { vm.theme = theme }
                } label: {
                    HStack(spacing: 10) {
                        Circle().fill(theme.accent).frame(width: 16, height: 16)
                        Text(theme.rawValue)
                            .font(.system(size: 13, weight: vm.theme == theme ? .bold : .medium))
                            .foregroundStyle(.white)
                        Spacer()
                        if vm.theme == theme {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(theme.accent)
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 10)
                    .background(Color.white.opacity(vm.theme == theme ? 0.08 : 0.03))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .zenGlass()
    }

    private var searchSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Motore di ricerca")
            HStack(spacing: 8) {
                ForEach(["Google", "DuckDuckGo", "Bing"], id: \.self) { engine in
                    Button { vm.searchEngine = engine } label: {
                        Text(engine)
                            .font(.system(size: 11, weight: vm.searchEngine == engine ? .bold : .regular))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(vm.searchEngine == engine ? vm.theme.accent : Color.white.opacity(0.1))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .zenGlass()
    }

    private var zoomSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Zoom pagina — \(Int(vm.zoomLevel * 100))%")
            HStack(spacing: 12) {
                Button { vm.zoomLevel = max(0.5, vm.zoomLevel - 0.1) } label: {
                    Image(systemName: "minus").foregroundStyle(.white)
                        .frame(width: 36, height: 32)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                Slider(value: $vm.zoomLevel, in: 0.5...2.0, step: 0.05)
                    .tint(vm.theme.accent)
                Button { vm.zoomLevel = min(2.0, vm.zoomLevel + 0.1) } label: {
                    Image(systemName: "plus").foregroundStyle(.white)
                        .frame(width: 36, height: 32)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
            Button { vm.zoomLevel = 1.0 } label: {
                Text("Ripristina 100%")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.45))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .zenGlass()
    }

    private var boostsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Zen Boosts")
            toggleRow("Dark mode forzata", isOn: $vm.boosts.forceDarkMode, icon: "moon.fill")
            toggleRow("Testo più grande", isOn: $vm.boosts.largerText, icon: "textformat.size")
            toggleRow("Blocca tracker comuni", isOn: $vm.boosts.blockTrackers, icon: "shield.fill")
        }
        .padding(14)
        .zenGlass()
    }

    private var privacySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Privacy")
            Toggle(isOn: $vm.isPrivateSession) {
                Label("Nuove schede in sessione privata", systemImage: "eye.slash.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(.white)
            }
            .tint(vm.theme.accent)

            Button(role: .destructive) {
                vm.history.removeAll()
                UserDefaults.standard.removeObject(forKey: "zen_history")
            } label: {
                Label("Cancella cronologia", systemImage: "trash")
                    .font(.system(size: 13))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.red.opacity(0.85))
        }
        .padding(14)
        .zenGlass()
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(.white.opacity(0.5))
    }

    private func toggleRow(_ title: String, isOn: Binding<Bool>, icon: String) -> some View {
        Toggle(isOn: isOn) {
            Label(title, systemImage: icon)
                .font(.system(size: 13))
                .foregroundStyle(.white)
        }
        .tint(vm.theme.accent)
    }
}
