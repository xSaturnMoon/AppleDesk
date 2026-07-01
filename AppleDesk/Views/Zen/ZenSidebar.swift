import SwiftUI

// MARK: - Sidebar
struct ZenSidebar: View {
    @ObservedObject var vm: ZenViewModel

    private var expanded: Bool { !vm.sidebarCollapsed }

    var body: some View {
        VStack(spacing: 0) {
            header

            if expanded {
                workspaceSection
                    .padding(.top, 4)
            }

            newTabButton
                .padding(.top, expanded ? 12 : 8)
                .padding(.horizontal, expanded ? ZenPalette.horizontalPadding : 8)

            tabList
                .padding(.top, 8)

            Spacer(minLength: 0)

            footer
        }
        .frame(width: expanded ? ZenPalette.sidebarWidth : ZenPalette.sidebarCollapsedWidth)
        .frame(maxHeight: .infinity)
        .background(.ultraThinMaterial)
        .environment(\.colorScheme, .dark)
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(ZenPalette.stroke)
                .frame(width: 0.5)
        }
        .animation(.spring(duration: 0.28, bounce: 0.05), value: vm.sidebarCollapsed)
    }

    // MARK: Header

    private var header: some View {
        Group {
            if expanded {
                expandedHeader
            } else {
                collapsedHeader
            }
        }
    }

    private var expandedHeader: some View {
        HStack(spacing: 10) {
            Image("zen_icon")
                .resizable()
                .scaledToFit()
                .frame(width: 26, height: 26)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

            Text("Zen")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(ZenPalette.textPrimary)

            Spacer(minLength: 0)

            collapseButton
        }
        .padding(.horizontal, ZenPalette.horizontalPadding)
        .padding(.top, 14)
        .padding(.bottom, 10)
    }

    private var collapsedHeader: some View {
        VStack(spacing: 10) {
            Image("zen_icon")
                .resizable()
                .scaledToFit()
                .frame(width: 28, height: 28)
                .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))

            collapseButton
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 14)
        .padding(.bottom, 10)
    }

    private var collapseButton: some View {
        Button {
            withAnimation(.spring(duration: 0.28, bounce: 0.05)) {
                vm.sidebarCollapsed.toggle()
            }
        } label: {
            Image(systemName: "sidebar.left")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(ZenPalette.textSecondary)
                .frame(width: 28, height: 28)
        }
        .buttonStyle(.plain)
    }

    // MARK: Workspaces

    private var workspaceSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("WORKSPACE")
                .font(.system(size: 10, weight: .semibold))
                .kerning(0.6)
                .foregroundStyle(ZenPalette.textTertiary)
                .padding(.horizontal, ZenPalette.horizontalPadding)

            VStack(spacing: 4) {
                ForEach(vm.workspaces) { ws in
                    workspaceRow(ws)
                }

                Button { vm.showNewWorkspacePrompt = true } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .semibold))
                        Text("Aggiungi")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundStyle(ZenPalette.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, ZenPalette.horizontalPadding)
        }
    }

    private func workspaceRow(_ ws: ZenWorkspace) -> some View {
        let selected = vm.activeWorkspaceID == ws.id
        return Button { vm.switchWorkspace(ws.id) } label: {
            HStack(spacing: 8) {
                Image(systemName: ws.symbol)
                    .font(.system(size: 12, weight: .medium))
                    .frame(width: 16)
                Text(ws.name)
                    .font(.system(size: 13, weight: selected ? .semibold : .regular))
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            .foregroundStyle(selected ? .white : ZenPalette.textSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: ZenPalette.rowRadius, style: .continuous)
                    .fill(selected ? ZenPalette.accent : ZenPalette.rowHover.opacity(0.5))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: Nuova scheda

    private var newTabButton: some View {
        Button { vm.addTab() } label: {
            Group {
                if expanded {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Nuova scheda")
                            .font(.system(size: 13, weight: .medium))
                        Spacer(minLength: 0)
                    }
                    .foregroundStyle(ZenPalette.textPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .zenInsetField()
                } else {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(ZenPalette.textPrimary)
                        .frame(width: 40, height: 40)
                        .zenInsetField()
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: Tab list

    private var tabList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 2) {
                if let ws = vm.activeWorkspace {
                    ForEach(ws.tabs) { tab in
                        ZenTabRow(vm: vm, workspace: ws, tab: tab, expanded: expanded)
                    }
                }
            }
            .padding(.horizontal, expanded ? ZenPalette.horizontalPadding : 8)
        }
    }

    // MARK: Footer

    private var footer: some View {
        Group {
            if expanded {
                HStack {
                    Spacer(minLength: 0)
                    settingsButton
                }
                .padding(.horizontal, ZenPalette.horizontalPadding)
            } else {
                HStack {
                    Spacer(minLength: 0)
                    settingsButton
                    Spacer(minLength: 0)
                }
            }
        }
        .padding(.vertical, 12)
    }

    private var settingsButton: some View {
        Button { vm.showSettings = true } label: {
            Image(systemName: "gearshape")
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(ZenPalette.textSecondary)
                .frame(width: 28, height: 28)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Tab row
private struct ZenTabRow: View {
    @ObservedObject var vm: ZenViewModel
    @ObservedObject var workspace: ZenWorkspace
    @ObservedObject var tab: ZenTabModel
    let expanded: Bool

    var body: some View {
        let isActive = workspace.activeTabID == tab.id
        let shape = RoundedRectangle(cornerRadius: ZenPalette.rowRadius, style: .continuous)

        HStack(spacing: 8) {
            Circle()
                .fill(isActive ? ZenPalette.accent : ZenPalette.textTertiary)
                .frame(width: 6, height: 6)

            if expanded {
                Text(tab.loadedURL == nil ? "Nuova scheda" : tab.title)
                    .font(.system(size: 12, weight: isActive ? .medium : .regular))
                    .foregroundStyle(isActive ? ZenPalette.textPrimary : ZenPalette.textSecondary)
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, expanded ? 10 : 6)
        .padding(.vertical, expanded ? 9 : 10)
        .frame(maxWidth: .infinity, minHeight: expanded ? 36 : 40, alignment: expanded ? .leading : .center)
        .background(shape.fill(isActive ? ZenPalette.rowActive : Color.clear))
        .contentShape(shape)
        .onTapGesture { vm.selectTab(tab.id) }
        .overlay {
            MiddleClickOverlay {
                if workspace.tabs.count > 1 {
                    vm.closeTab(tab.id)
                }
            }
        }
        .contextMenu { tabContextMenu }
    }

    @ViewBuilder
    private var tabContextMenu: some View {
        if let url = tab.loadedURL {
            Button { vm.openGlance(url: url) } label: {
                Label("Zen Glance", systemImage: "eye")
            }
        }
        Button { vm.togglePin(tab) } label: {
            Label(tab.isPinned ? "Rimuovi pin" : "Fissa scheda", systemImage: "pin")
        }
        if workspace.tabs.count > 1 {
            Button(role: .destructive) { vm.closeTab(tab.id) } label: {
                Label("Chiudi", systemImage: "xmark")
            }
        }
    }
}
