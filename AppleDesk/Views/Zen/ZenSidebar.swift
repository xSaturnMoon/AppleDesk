import SwiftUI

// MARK: - Glass styling condiviso
struct ZenGlassPanel: ViewModifier {
    var cornerRadius: CGFloat = 12

    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .environment(\.colorScheme, .dark)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(.white.opacity(0.12), lineWidth: 0.5)
            )
    }
}

extension View {
    func zenGlass(cornerRadius: CGFloat = 12) -> some View {
        modifier(ZenGlassPanel(cornerRadius: cornerRadius))
    }
}

// MARK: - Sidebar
struct ZenSidebar: View {
    @ObservedObject var vm: ZenViewModel

    var body: some View {
        VStack(spacing: 0) {
            header
            Rectangle().fill(.white.opacity(0.08)).frame(height: 1)

            workspacePicker
            Rectangle().fill(.white.opacity(0.06)).frame(height: 1)

            tabList

            Spacer(minLength: 0)

            footer
        }
        .frame(width: vm.sidebarCollapsed ? 52 : 200)
        .frame(maxHeight: .infinity)
        .background(.ultraThinMaterial)
        .environment(\.colorScheme, .dark)
        .animation(.spring(duration: 0.32, bounce: 0.1), value: vm.sidebarCollapsed)
    }

    private var header: some View {
        HStack(spacing: 8) {
            if !vm.sidebarCollapsed {
                Image("zen_icon")
                    .resizable().scaledToFit()
                    .frame(width: 22, height: 22)
                Text("Zen")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            Spacer()
            Button {
                withAnimation(.spring(duration: 0.3, bounce: 0.12)) {
                    vm.sidebarCollapsed.toggle()
                }
            } label: {
                Image(systemName: vm.sidebarCollapsed ? "sidebar.right" : "sidebar.left")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.6))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, vm.sidebarCollapsed ? 10 : 14)
        .padding(.vertical, 12)
    }

    private var workspacePicker: some View {
        VStack(alignment: .leading, spacing: 4) {
            if !vm.sidebarCollapsed {
                Text("WORKSPACE")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white.opacity(0.35))
                    .padding(.horizontal, 14)
                    .padding(.top, 10)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(vm.workspaces) { ws in
                        workspaceChip(ws)
                    }
                    if !vm.sidebarCollapsed {
                        Button { vm.showNewWorkspacePrompt = true } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(vm.theme.accent)
                                .frame(width: 28, height: 28)
                                .background(Color.white.opacity(0.06))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 10)
            }
            .padding(.bottom, 8)
        }
    }

    private func workspaceChip(_ ws: ZenWorkspace) -> some View {
        let selected = vm.activeWorkspaceID == ws.id
        return Button { vm.switchWorkspace(ws.id) } label: {
            HStack(spacing: 5) {
                Image(systemName: ws.symbol)
                    .font(.system(size: 11, weight: .semibold))
                if !vm.sidebarCollapsed {
                    Text(ws.name)
                        .font(.system(size: 11, weight: .semibold))
                        .lineLimit(1)
                }
            }
            .foregroundStyle(selected ? .white : .white.opacity(0.55))
            .padding(.horizontal, vm.sidebarCollapsed ? 8 : 10)
            .padding(.vertical, 6)
            .background(
                Capsule().fill(selected ? vm.theme.accent.opacity(0.85) : Color.white.opacity(0.06))
            )
        }
        .buttonStyle(.plain)
    }

    private var tabList: some View {
        ScrollView {
            LazyVStack(spacing: 2) {
                if let ws = vm.activeWorkspace {
                    ForEach(ws.pinnedTabs) { tab in
                        ZenTabRow(vm: vm, workspace: ws, tab: tab)
                    }
                    if !ws.pinnedTabs.isEmpty && !ws.unpinnedTabs.isEmpty {
                        Rectangle().fill(.white.opacity(0.06)).frame(height: 1).padding(.vertical, 4)
                    }
                    ForEach(ws.unpinnedTabs) { tab in
                        ZenTabRow(vm: vm, workspace: ws, tab: tab)
                    }
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 8)
        }
    }

    private var footer: some View {
        HStack {
            Button { vm.addTab() } label: {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white.opacity(0.8))
                    .frame(width: 32, height: 32)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            if !vm.sidebarCollapsed {
                Spacer()
                Button { vm.showSettings = true } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.5))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }
}

private struct ZenTabRow: View {
    @ObservedObject var vm: ZenViewModel
    @ObservedObject var workspace: ZenWorkspace
    @ObservedObject var tab: ZenTabModel

    var body: some View {
        let isActive = workspace.activeTabID == tab.id
        let inSplit = vm.splitTabIDs.contains(tab.id)

        return Button { vm.selectTab(tab.id) } label: {
            HStack(spacing: 8) {
                Image(systemName: tab.loadedURL == nil ? "sparkles" : "globe")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(isActive ? vm.theme.accent : .white.opacity(0.45))
                    .frame(width: vm.sidebarCollapsed ? 20 : 16)

                if !vm.sidebarCollapsed {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(tab.title)
                            .font(.system(size: 12, weight: isActive ? .semibold : .regular))
                            .foregroundStyle(.white.opacity(isActive ? 0.95 : 0.7))
                            .lineLimit(1)
                        if tab.isLoading {
                            Text("Caricamento…")
                                .font(.system(size: 9))
                                .foregroundStyle(.white.opacity(0.35))
                        }
                    }
                    Spacer(minLength: 0)
                    if tab.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 8))
                            .foregroundStyle(.white.opacity(0.35))
                    }
                    if inSplit && vm.splitLayout != .single {
                        Image(systemName: "square.split.2x1")
                            .font(.system(size: 8))
                            .foregroundStyle(vm.theme.accent.opacity(0.8))
                    }
                }
            }
            .padding(.horizontal, vm.sidebarCollapsed ? 6 : 10)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isActive ? Color.white.opacity(0.12) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button { vm.togglePin(tab) } label: {
                Label(tab.isPinned ? "Rimuovi pin" : "Fissa scheda", systemImage: "pin")
            }
            if let url = tab.loadedURL {
                Button { vm.openGlance(url: url) } label: {
                    Label("Zen Glance", systemImage: "eye")
                }
            }
            Button { vm.addTab() } label: {
                Label("Nuova scheda", systemImage: "plus")
            }
            if workspace.tabs.count > 1 {
                Button(role: .destructive) { vm.closeTab(tab.id) } label: {
                    Label("Chiudi", systemImage: "xmark")
                }
            }
        }
    }
}
