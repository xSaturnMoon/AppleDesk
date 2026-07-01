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
        .background(vm.theme.canvasElevated)
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
            HStack(spacing: 0.5) {
                ForEach(Array(tabs.prefix(2).enumerated()), id: \.element.id) { _, tab in
                    ZenTabPane(vm: vm, tab: tab, isFocused: vm.focusedSplitTabID == tab.id)
                }
            }
        case .three:
            HStack(spacing: 0.5) {
                if let first = tabs.first {
                    ZenTabPane(vm: vm, tab: first, isFocused: vm.focusedSplitTabID == first.id)
                }
                VStack(spacing: 0.5) {
                    ForEach(Array(tabs.dropFirst().prefix(2).enumerated()), id: \.element.id) { _, tab in
                        ZenTabPane(vm: vm, tab: tab, isFocused: vm.focusedSplitTabID == tab.id)
                    }
                }
            }
        case .four:
            VStack(spacing: 0.5) {
                HStack(spacing: 0.5) {
                    ForEach(Array(tabs.prefix(2).enumerated()), id: \.element.id) { _, tab in
                        ZenTabPane(vm: vm, tab: tab, isFocused: vm.focusedSplitTabID == tab.id)
                    }
                }
                HStack(spacing: 0.5) {
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
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(ZenPalette.textSecondary)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 6)
                    .zenGlass(radius: 20)
            }
            .buttonStyle(.plain)
            .padding(.top, 10)
            Spacer()
        }
    }
}

// MARK: - Pannello
struct ZenTabPane: View {
    @ObservedObject var vm: ZenViewModel
    @ObservedObject var tab: ZenTabModel
    let isFocused: Bool

    var body: some View {
        ZStack {
            if tab.loadedURL != nil {
                ZenWebView(tab: tab, vm: vm)
                if tab.isLoading {
                    ProgressView().tint(vm.accent)
                }
            } else {
                ZenHomePage(
                    vm: vm,
                    tab: tab,
                    onSubmit: { vm.loadURL(tab.urlText, on: tab) },
                    urlText: Binding(get: { tab.urlText }, set: { tab.urlText = $0 })
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay {
            if vm.splitLayout != .single && isFocused {
                RoundedRectangle(cornerRadius: 0)
                    .stroke(vm.accent.opacity(0.35), lineWidth: 1)
            }
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
                Label("Nuova scheda", systemImage: "plus")
            }
        }
    }
}
