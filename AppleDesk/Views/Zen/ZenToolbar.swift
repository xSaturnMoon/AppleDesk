import SwiftUI

struct ZenToolbar: View {
    @ObservedObject var vm: ZenViewModel

    private var tab: ZenTabModel? { vm.focusedTab }

    var body: some View {
        HStack(spacing: 0) {
            navCluster
                .frame(width: 132, alignment: .leading)

            urlBar
                .frame(maxWidth: .infinity)

            toolsCluster
                .frame(width: 88, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .environment(\.colorScheme, .dark)
        .overlay(alignment: .bottom) {
            Rectangle().fill(ZenPalette.stroke).frame(height: 0.5)
        }
    }

    // MARK: Nav

    private var navCluster: some View {
        HStack(spacing: 18) {
            navButton("chevron.left", enabled: tab?.canGoBack == true) { tab?.webView.goBack() }
            navButton("chevron.right", enabled: tab?.canGoForward == true) { tab?.webView.goForward() }
            navButton(tab?.isLoading == true ? "xmark" : "arrow.clockwise", enabled: true) {
                if tab?.isLoading == true { tab?.webView.stopLoading() }
                else { vm.reloadActive() }
            }
            navButton("house", enabled: true) { vm.goHome(on: tab) }
        }
    }

    // MARK: URL

    private var urlBar: some View {
        HStack(spacing: 10) {
            Image(systemName: tab?.loadedURL == nil ? "magnifyingglass" : "lock.fill")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(ZenPalette.textTertiary)

            TextField("Cerca o inserisci URL", text: Binding(
                get: { tab?.urlText ?? "" },
                set: { tab?.urlText = $0 }
            ))
            .font(.system(size: 13, weight: .regular, design: .rounded))
            .foregroundStyle(ZenPalette.textPrimary)
            .tint(ZenPalette.accent)
            .multilineTextAlignment(.center)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .onSubmit { vm.loadURL(tab?.urlText ?? "", on: tab) }

            if let t = tab, t.loadedURL != nil {
                Button { vm.toggleBookmark(urlStr: t.urlText, name: t.title) } label: {
                    Image(systemName: vm.isBookmarked(urlStr: t.urlText) ? "star.fill" : "star")
                        .font(.system(size: 12))
                        .foregroundStyle(
                            vm.isBookmarked(urlStr: t.urlText) ? Color.yellow.opacity(0.85) : ZenPalette.textTertiary
                        )
                }
                .buttonStyle(.plain)
            } else {
                Color.clear.frame(width: 12, height: 12)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
        .zenInsetField()
        .padding(.horizontal, 12)
    }

    // MARK: Tools

    private var toolsCluster: some View {
        Menu {
            Section("Split View") {
                ForEach(ZenSplitLayout.allCases) { layout in
                    Button { vm.setSplitLayout(layout) } label: {
                        Label(layout.label, systemImage: layout.symbol)
                    }
                }
            }
            Section {
                Button { vm.toggleCompactMode() } label: {
                    Label(vm.compactMode ? "Esci da Compact" : "Compact Mode", systemImage: "arrow.up.left.and.arrow.down.right")
                }
                Button { vm.showHistory = true } label: {
                    Label("Cronologia", systemImage: "clock.arrow.circlepath")
                }
                Button { vm.showSettings = true } label: {
                    Label("Impostazioni", systemImage: "gearshape")
                }
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(ZenPalette.textSecondary)
                .frame(width: 36, height: 36)
                .contentShape(Rectangle())
        }
        .popover(isPresented: $vm.showHistory) {
            ZenHistoryPanel(vm: vm)
        }
    }

    private func navButton(_ name: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: name)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(enabled ? ZenPalette.textPrimary : ZenPalette.textTertiary)
        }
        .disabled(!enabled)
        .buttonStyle(.plain)
    }
}

// MARK: - Cronologia
struct ZenHistoryPanel: View {
    @ObservedObject var vm: ZenViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Cronologia")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(ZenPalette.textPrimary)
                Spacer()
                if !vm.history.isEmpty {
                    Button("Cancella") {
                        vm.history.removeAll()
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.red.opacity(0.8))
                    .buttonStyle(.plain)
                }
            }

            if vm.isPrivateSession {
                Text("Sessione privata attiva.")
                    .font(.system(size: 12))
                    .foregroundStyle(ZenPalette.textSecondary)
            } else if vm.history.isEmpty {
                Text("Nessuna pagina visitata.")
                    .font(.system(size: 12))
                    .foregroundStyle(ZenPalette.textSecondary)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(vm.history.prefix(40), id: \.self) { url in
                            Button {
                                vm.loadURL(url)
                                vm.showHistory = false
                            } label: {
                                Text(url)
                                    .font(.system(size: 11))
                                    .foregroundStyle(ZenPalette.textSecondary)
                                    .lineLimit(1)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, 8)
                            }
                            .buttonStyle(.plain)
                            if url != vm.history.prefix(40).last {
                                Divider().overlay(ZenPalette.stroke)
                            }
                        }
                    }
                }
                .frame(maxHeight: 260)
            }
        }
        .padding(18)
        .frame(width: 300)
        .zenGlass()
    }
}
