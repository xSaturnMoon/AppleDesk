import SwiftUI

struct FinderWindowContent: View {
    @StateObject private var vm = FinderViewModel()

    var body: some View {
        HStack(spacing: 0) {
            FinderSidebar(vm: vm)
                .frame(width: 190)

            Rectangle().fill(.white.opacity(0.08)).frame(width: 1)

            VStack(spacing: 0) {
                FinderToolbar(vm: vm)
                FinderContentView(vm: vm)
                statusBar
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.3))

        // Nuova cartella
        .alert("Nuova cartella", isPresented: $vm.showNewFolderPrompt) {
            TextField("Nome cartella", text: $vm.newFolderName)
            Button("Annulla", role: .cancel) { }
            Button("Crea") { vm.createFolder() }
        }

        // Rinomina
        .alert("Rinomina", isPresented: Binding(
            get: { vm.renamingItem != nil },
            set: { if !$0 { vm.renamingItem = nil } }
        )) {
            TextField("Nome", text: $vm.renameText)
            Button("Annulla", role: .cancel) { vm.renamingItem = nil }
            Button("Rinomina") { vm.confirmRename() }
        }

        // Elimina
        .confirmationDialog(
            "Eliminare \"\(vm.itemPendingDelete?.name ?? "")\"?",
            isPresented: $vm.showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Elimina", role: .destructive) { vm.confirmDelete() }
            Button("Annulla", role: .cancel) { vm.itemPendingDelete = nil }
        }

        // Zip
        .alert("Comprimi", isPresented: $vm.showZipPrompt) {
            TextField("Nome archivio", text: $vm.zipName)
            Button("Annulla", role: .cancel) { vm.zipItem = nil }
            Button("Comprimi") { vm.confirmZip() }
        }

        // Unzip
        .alert("Decomprimi", isPresented: $vm.showUnzipPrompt) {
            TextField("Nome cartella", text: $vm.unzipName)
            Button("Annulla", role: .cancel) { vm.unzipItem = nil }
            Button("Decomprimi") { vm.confirmUnzip() }
        }

        // Errori
        .alert("Errore", isPresented: Binding(
            get: { vm.errorMessage != nil },
            set: { if !$0 { vm.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(vm.errorMessage ?? "")
        }
    }

    private var statusBar: some View {
        HStack {
            Text("\(vm.filteredItems.count) elementi")
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.4))
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
    }
}
