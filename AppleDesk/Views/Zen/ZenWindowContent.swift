import SwiftUI

struct ZenWindowContent: View {
    @StateObject private var vm = ZenViewModel()

    var body: some View {
        ZStack {
            LinearGradient(colors: vm.theme.gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            HStack(spacing: 0) {
                if !vm.compactMode {
                    ZenSidebar(vm: vm)
                    Rectangle().fill(.white.opacity(0.08)).frame(width: 1)
                } else if vm.toolbarVisible {
                    ZenSidebar(vm: vm)
                        .transition(.move(edge: .leading).combined(with: .opacity))
                    Rectangle().fill(.white.opacity(0.08)).frame(width: 1)
                }

                VStack(spacing: 0) {
                    if vm.toolbarVisible && !vm.compactMode || (vm.compactMode && vm.toolbarVisible) {
                        ZenToolbar(vm: vm)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    ZenContentArea(vm: vm)
                }
            }

            if vm.showGlance {
                ZenGlanceOverlay(vm: vm)
                    .zIndex(100)
            }
        }
        .animation(.spring(duration: 0.35, bounce: 0.1), value: vm.compactMode)
        .animation(.spring(duration: 0.35, bounce: 0.1), value: vm.toolbarVisible)
        .animation(.spring(duration: 0.3, bounce: 0.1), value: vm.showGlance)
        .sheet(isPresented: $vm.showSettings) {
            ZenSettingsPanel(vm: vm)
        }
        .alert("Nuovo workspace", isPresented: $vm.showNewWorkspacePrompt) {
            TextField("Nome", text: $vm.newWorkspaceName)
            Button("Annulla", role: .cancel) { vm.newWorkspaceName = "" }
            Button("Crea") { vm.addWorkspace() }
        }
    }
}
