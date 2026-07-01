import SwiftUI

struct ZenToolbar: View {
    @ObservedObject var vm: ZenViewModel
    @State private var showSplitPicker = false

    var tab: ZenTabModel? { vm.focusedTab }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                navButtons
                urlBar
                actionButtons
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
            .environment(\.colorScheme, .dark)

            Rectangle().fill(.white.opacity(0.08)).frame(height: 1)
        }
    }

    private var navButtons: some View {
        HStack(spacing: 8) {
            toolbarIcon("chevron.left", enabled: tab?.canGoBack == true) {
                tab?.webView.goBack()
            }
            toolbarIcon("chevron.right", enabled: tab?.canGoForward == true) {
                tab?.webView.goForward()
            }
            toolbarIcon(tab?.isLoading == true ? "xmark" : "arrow.clockwise", enabled: true) {
                if tab?.isLoading == true { tab?.webView.stopLoading() }
                else { vm.reloadActive() }
            }
            toolbarIcon("house.fill", enabled: true) {
                vm.goHome(on: tab)
            }
        }
    }

    private var urlBar: some View {
        HStack(spacing: 8) {
            Image(systemName: tab?.loadedURL == nil ? "magnifyingglass" : "lock.fill")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(tab?.loadedURL == nil ? .white.opacity(0.35) : .green)

            TextField("Cerca o inserisci URL", text: Binding(
                get: { tab?.urlText ?? "" },
                set: { tab?.urlText = $0 }
            ))
            .font(.system(size: 13, weight: .medium, design: .rounded))
            .foregroundStyle(.white)
            .tint(vm.theme.accent)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .onSubmit {
                vm.loadURL(tab?.urlText ?? "", on: tab)
            }

            if let t = tab, t.loadedURL != nil {
                Button {
                    vm.toggleBookmark(urlStr: t.urlText, name: t.title)
                } label: {
                    Image(systemName: vm.isBookmarked(urlStr: t.urlText) ? "star.fill" : "star")
                        .font(.system(size: 12))
                        .foregroundStyle(vm.isBookmarked(urlStr: t.urlText) ? .yellow : .white.opacity(0.45))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.1), lineWidth: 0.5))
    }

    private var actionButtons: some View {
        HStack(spacing: 6) {
            Menu {
                ForEach(ZenSplitLayout.allCases) { layout in
                    Button {
                        vm.setSplitLayout(layout)
                    } label: {
                        Label(layout.label, systemImage: layout.symbol)
                    }
                }
            } label: {
                Image(systemName: vm.splitLayout.symbol)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(vm.splitLayout != .single ? vm.theme.accent : .white.opacity(0.75))
                    .frame(width: 32, height: 32)
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }

            Button { vm.toggleCompactMode() } label: {
                Image(systemName: vm.compactMode ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(vm.compactMode ? vm.theme.accent : .white.opacity(0.75))
                    .frame(width: 32, height: 32)
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)

            Button { vm.showHistory = true } label: {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.75))
                    .frame(width: 32, height: 32)
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)
            .popover(isPresented: $vm.showHistory) {
                ZenHistoryPanel(vm: vm)
            }

            Button { vm.showSettings = true } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.75))
                    .frame(width: 32, height: 32)
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    private func toolbarIcon(_ name: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: name)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(enabled ? .white.opacity(0.85) : .white.opacity(0.2))
        }
        .disabled(!enabled)
        .buttonStyle(.plain)
    }
}

// MARK: - Cronologia
struct ZenHistoryPanel: View {
    @ObservedObject var vm: ZenViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Cronologia")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                Spacer()
                if !vm.history.isEmpty {
                    Button("Cancella") { vm.history.removeAll() }
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.red)
                        .buttonStyle(.plain)
                }
            }

            if vm.isPrivateSession {
                Text("Sessione privata: cronologia disattivata.")
                    .font(.system(size: 12))
                    .foregroundStyle(vm.theme.accent)
            } else if vm.history.isEmpty {
                Text("Nessun sito visitato.")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.5))
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(vm.history.prefix(40), id: \.self) { url in
                            Button {
                                vm.loadURL(url)
                                vm.showHistory = false
                            } label: {
                                Text(url)
                                    .font(.system(size: 11))
                                    .foregroundStyle(vm.theme.accent)
                                    .lineLimit(1)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .buttonStyle(.plain)
                            Divider().background(.white.opacity(0.08))
                        }
                    }
                }
                .frame(maxHeight: 280)
            }
        }
        .padding(16)
        .frame(width: 300)
        .background(.ultraThinMaterial)
        .environment(\.colorScheme, .dark)
    }
}
