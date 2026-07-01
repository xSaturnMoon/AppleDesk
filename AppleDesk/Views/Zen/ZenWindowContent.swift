import SwiftUI

struct ZenWindowContent: View {
    @StateObject private var vm = ZenViewModel()

    var body: some View {
        ZStack {
            ZenPalette.canvas.ignoresSafeArea()

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
        .sheet(isPresented: $vm.showSettings) {
            ZenSettingsPanel(vm: vm)
        }
        .alert("Nuovo workspace", isPresented: $vm.showNewWorkspacePrompt) {
            TextField("Nome", text: $vm.newWorkspaceName)
            Button("Annulla", role: .cancel) { vm.newWorkspaceName = "" }
            Button("Crea") { vm.addWorkspace() }
        }
    }

    private var shouldShowSidebar: Bool {
        !vm.compactMode || vm.toolbarVisible
    }
}
