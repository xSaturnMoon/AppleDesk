import SwiftUI

struct ZenContentArea: View {
    @ObservedObject var vm: ZenViewModel

    var body: some View {
        ZStack {
            if vm.splitLayout == .single {
                singlePane
            } else {
                splitPanes
            }

            if vm.compactMode && !vm.toolbarVisible {
                compactRevealButton
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.2))
    }

    private var singlePane: some View {
        Group {
            if let tab = vm.focusedTab {
                ZenTabPane(vm: vm, tab: tab, isFocused: true)
            }
        }
    }

    @ViewBuilder
    private var splitPanes: some View {
        let tabs = vm.tabsInSplit()
        switch vm.splitLayout {
        case .single:
            singlePane
        case .twoHorizontal:
            HStack(spacing: 1) {
                ForEach(Array(tabs.prefix(2).enumerated()), id: \.element.id) { _, tab in
                    ZenTabPane(vm: vm, tab: tab, isFocused: vm.focusedSplitTabID == tab.id)
                }
            }
        case .three:
            HStack(spacing: 1) {
                if let first = tabs.first {
                    ZenTabPane(vm: vm, tab: first, isFocused: vm.focusedSplitTabID == first.id)
                        .frame(maxWidth: .infinity)
                }
                VStack(spacing: 1) {
                    ForEach(Array(tabs.dropFirst().prefix(2).enumerated()), id: \.element.id) { _, tab in
                        ZenTabPane(vm: vm, tab: tab, isFocused: vm.focusedSplitTabID == tab.id)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        case .four:
            VStack(spacing: 1) {
                HStack(spacing: 1) {
                    ForEach(Array(tabs.prefix(2).enumerated()), id: \.element.id) { _, tab in
                        ZenTabPane(vm: vm, tab: tab, isFocused: vm.focusedSplitTabID == tab.id)
                    }
                }
                HStack(spacing: 1) {
                    ForEach(Array(tabs.dropFirst(2).prefix(2).enumerated()), id: \.element.id) { _, tab in
                        ZenTabPane(vm: vm, tab: tab, isFocused: vm.focusedSplitTabID == tab.id)
                    }
                }
            }
        }
    }

    private var compactRevealButton: some View {
        VStack {
            Button { vm.revealUIInCompact() } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(.white.opacity(0.15), lineWidth: 0.5))
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
            Spacer()
        }
    }
}

// MARK: - Singolo pannello
struct ZenTabPane: View {
    @ObservedObject var vm: ZenViewModel
    @ObservedObject var tab: ZenTabModel
    let isFocused: Bool

    var body: some View {
        ZStack {
            if tab.loadedURL != nil {
                ZenWebView(tab: tab, vm: vm)
                if tab.isLoading {
                    ProgressView()
                        .tint(vm.theme.accent)
                        .padding(14)
                        .zenGlass(cornerRadius: 14)
                }
            } else {
                ZenHomePage(
                    vm: vm,
                    tab: tab,
                    onSubmit: { vm.loadURL(tab.urlText, on: tab) },
                    urlText: Binding(
                        get: { tab.urlText },
                        set: { tab.urlText = $0 }
                    )
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .top) {
            if vm.splitLayout != .single {
                paneHeader
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 0)
                .stroke(isFocused ? vm.theme.accent.opacity(0.55) : Color.clear, lineWidth: 2)
        }
        .contentShape(Rectangle())
        .onTapGesture { vm.focusedSplitTabID = tab.id }
        .contextMenu {
            if let url = tab.loadedURL {
                Button { vm.openGlance(url: url) } label: {
                    Label("Zen Glance", systemImage: "eye")
                }
            }
            Button { vm.goHome(on: tab) } label: {
                Label("Nuova scheda", systemImage: "sparkles")
            }
        }
    }

    private var paneHeader: some View {
        HStack(spacing: 6) {
            Image(systemName: "globe")
                .font(.system(size: 10))
                .foregroundStyle(vm.theme.accent)
            Text(tab.title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.white.opacity(0.75))
                .lineLimit(1)
            Spacer()
            if tab.isLoading {
                ProgressView().scaleEffect(0.6).tint(vm.theme.accent)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(.ultraThinMaterial)
        .environment(\.colorScheme, .dark)
    }
}
