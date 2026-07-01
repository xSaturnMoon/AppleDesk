import SwiftUI

struct ZenWindowContent: View {
    @StateObject private var vm = ZenViewModel()

    var body: some View {
        ZStack {
            vm.theme.canvas.ignoresSafeArea()

            HStack(spacing: 0) {
                if shouldShowSidebar {
                    ZenSidebar(vm: vm)
                }

                VStack(spacing: 0) {
                    if vm.toolbarVisible {
                        ZenToolbar(vm: vm)
                    }
                    ZenContentArea(vm: vm)
                }
            }

            if vm.showGlance {
                ZenGlanceOverlay(vm: vm)
                    .zIndex(100)
            }
        }
        .animation(.spring(duration: 0.3, bounce: 0.04), value: vm.compactMode)
        .animation(.spring(duration: 0.3, bounce: 0.04), value: vm.toolbarVisible)
        .animation(.spring(duration: 0.25, bounce: 0.04), value: vm.theme)
        .sheet(isPresented: $vm.showSettings) {
            ZenSettingsPanel(vm: vm)
        }
        .sheet(isPresented: $vm.showWorkspaceIconPicker) {
            ZenWorkspaceIconPicker(vm: vm)
        }
        .alert("Nuovo workspace", isPresented: $vm.showNewWorkspacePrompt) {
            TextField("Nome", text: $vm.newWorkspaceName)
            Button("Annulla", role: .cancel) { vm.newWorkspaceName = "" }
            Button("Crea") { vm.addWorkspace() }
        }
        .alert("Rinomina workspace", isPresented: $vm.showWorkspaceRename) {
            TextField("Nome", text: $vm.workspaceRenameText)
            Button("Annulla", role: .cancel) {
                vm.editingWorkspaceID = nil
                vm.workspaceRenameText = ""
            }
            Button("Salva") { vm.confirmRenameWorkspace() }
        }
    }

    private var shouldShowSidebar: Bool {
        !vm.compactMode || vm.toolbarVisible
    }
}

// MARK: - Selettore icona workspace
struct ZenWorkspaceIconPicker: View {
    @ObservedObject var vm: ZenViewModel
    @Environment(\.dismiss) private var dismiss

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 6)

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(ZenWorkspaceIcons.choices, id: \.self) { symbol in
                        Button { vm.setWorkspaceIcon(symbol) } label: {
                            Image(systemName: symbol)
                                .font(.system(size: 18))
                                .foregroundStyle(vm.accent)
                                .frame(width: 44, height: 44)
                                .background(Color.white.opacity(0.06))
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(18)
            }
            .background(vm.theme.canvas)
            .navigationTitle("Scegli icona")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Annulla") {
                        vm.editingWorkspaceID = nil
                        vm.showWorkspaceIconPicker = false
                        dismiss()
                    }
                    .foregroundStyle(vm.accent)
                }
            }
        }
        .frame(width: 340, height: 360)
        .background(.ultraThinMaterial)
        .environment(\.colorScheme, .dark)
    }
}
