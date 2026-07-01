import SwiftUI

// MARK: - Router contenuto principale
struct FinderContentView: View {
    @ObservedObject var vm: FinderViewModel

    var body: some View {
        ZStack {
            switch vm.viewMode {
            case .icons:   FinderIconsView(vm: vm)
            case .list:    FinderListView(vm: vm)
            case .columns: FinderColumnsView(vm: vm)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.18))
        .contentShape(Rectangle())
        .onTapGesture { vm.selection.removeAll() }
        .dropDestination(for: String.self) { paths, _ in
            for path in paths { vm.moveItem(withPath: path, to: vm.currentURL) }
            return true
        } isTargeted: { _ in }
    }
}

// MARK: - Context menu condiviso (Rinomina / Elimina)
private struct FinderItemContextMenu: ViewModifier {
    @ObservedObject var vm: FinderViewModel
    let item: FinderItem

    func body(content: Content) -> some View {
        content.contextMenu {
            if item.isDirectory {
                Button {
                    vm.navigate(to: item.url)
                } label: {
                    Label("Apri", systemImage: "arrow.right.circle")
                }
            }
            Button {
                vm.beginRename(item)
            } label: {
                Label("Rinomina", systemImage: "pencil")
            }
            Button(role: .destructive) {
                vm.requestDelete(item)
            } label: {
                Label("Elimina", systemImage: "trash")
            }
        }
    }
}

private extension View {
    func finderContextMenu(vm: FinderViewModel, item: FinderItem) -> some View {
        modifier(FinderItemContextMenu(vm: vm, item: item))
    }
}

// MARK: - Vista Icone
struct FinderIconsView: View {
    @ObservedObject var vm: FinderViewModel

    private let columns = [GridItem(.adaptive(minimum: 88, maximum: 110), spacing: 14)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 18) {
                ForEach(vm.filteredItems) { item in
                    FinderIconCell(vm: vm, item: item)
                        .finderContextMenu(vm: vm, item: item)
                }
            }
            .padding(18)
        }
    }
}

private struct FinderIconCell: View {
    @ObservedObject var vm: FinderViewModel
    let item: FinderItem
    @State private var isDropTarget = false

    var isSelected: Bool { vm.selection.contains(item.id) }

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                if isSelected {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(red: 0.2, green: 0.47, blue: 0.98).opacity(0.35))
                        .frame(width: 68, height: 60)
                }
                Image(systemName: item.symbol)
                    .font(.system(size: 34, weight: .light))
                    .foregroundStyle(item.tint)
            }
            .frame(height: 60)

            Text(item.name)
                .font(.system(size: 11.5, weight: .medium))
                .foregroundStyle(.white.opacity(0.9))
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(width: 90)
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isDropTarget ? Color(red: 0.2, green: 0.47, blue: 0.98).opacity(0.25) : Color.clear)
        )
        .contentShape(Rectangle())
        .onTapGesture(count: 2) { vm.handleDoubleTap(item) }
        .onTapGesture(count: 1) { vm.toggleSelection(item) }
        .draggable(item.id)
        .dropDestination(for: String.self) { paths, _ in
            guard item.isDirectory else { return false }
            for path in paths { vm.moveItem(withPath: path, to: item.url) }
            return true
        } isTargeted: { targeted in
            isDropTarget = targeted && item.isDirectory
        }
    }
}

// MARK: - Vista Lista (Nome / Data modifica / Dimensione / Tipo)
struct FinderListView: View {
    @ObservedObject var vm: FinderViewModel

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Text("Nome").frame(width: 220, alignment: .leading)
                Text("Data modifica").frame(width: 150, alignment: .leading)
                Text("Dimensione").frame(width: 90, alignment: .leading)
                Text("Tipo").frame(maxWidth: .infinity, alignment: .leading)
            }
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(.white.opacity(0.4))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.04))

            Rectangle().fill(.white.opacity(0.06)).frame(height: 1)

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(vm.filteredItems) { item in
                        FinderListRow(vm: vm, item: item)
                            .finderContextMenu(vm: vm, item: item)
                    }
                }
            }
        }
    }
}

private struct FinderListRow: View {
    @ObservedObject var vm: FinderViewModel
    let item: FinderItem
    @State private var isDropTarget = false

    var isSelected: Bool { vm.selection.contains(item.id) }

    var body: some View {
        HStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: item.symbol)
                    .font(.system(size: 14))
                    .foregroundStyle(item.tint)
                    .frame(width: 18)

                Text(item.name)
                    .font(.system(size: 12.5))
                    .foregroundStyle(.white.opacity(0.9))
                    .lineLimit(1)
            }
            .frame(width: 220, alignment: .leading)

            Text(item.dateString)
                .font(.system(size: 11.5))
                .foregroundStyle(.white.opacity(0.5))
                .frame(width: 150, alignment: .leading)

            Text(item.sizeString)
                .font(.system(size: 11.5))
                .foregroundStyle(.white.opacity(0.5))
                .frame(width: 90, alignment: .leading)

            Text(item.kindString)
                .font(.system(size: 11.5))
                .foregroundStyle(.white.opacity(0.5))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 7)
        .background(
            isSelected ? Color(red: 0.2, green: 0.47, blue: 0.98).opacity(0.35)
            : (isDropTarget ? Color(red: 0.2, green: 0.47, blue: 0.98).opacity(0.2) : Color.clear)
        )
        .contentShape(Rectangle())
        .onTapGesture(count: 2) { vm.handleDoubleTap(item) }
        .onTapGesture(count: 1) { vm.toggleSelection(item) }
        .draggable(item.id)
        .dropDestination(for: String.self) { paths, _ in
            guard item.isDirectory else { return false }
            for path in paths { vm.moveItem(withPath: path, to: item.url) }
            return true
        } isTargeted: { targeted in
            isDropTarget = targeted && item.isDirectory
        }
    }
}

// MARK: - Vista Colonne (Miller columns, come "Colonne" su macOS)
struct FinderColumnsView: View {
    @ObservedObject var vm: FinderViewModel

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            columnsContent
                .frame(maxHeight: .infinity)
        }
    }

    @ViewBuilder
    private var columnsContent: some View {
        HStack(spacing: 0) {
            ForEach(Array(vm.columnPath.enumerated()), id: \.offset) { index, _ in
                let items: [FinderItem] = vm.columnItems.indices.contains(index) ? vm.columnItems[index] : []
                let selectedURL: URL? = vm.columnPath.indices.contains(index + 1) ? vm.columnPath[index + 1] : nil
                FinderColumnPane(vm: vm, items: items, selectedURL: selectedURL)
                    .frame(width: 220, maxHeight: .infinity)

                if index < vm.columnPath.count - 1 {
                    Rectangle().fill(.white.opacity(0.08)).frame(width: 1)
                }
            }
        }
    }
}

private struct FinderColumnPane: View {
    @ObservedObject var vm: FinderViewModel
    let items: [FinderItem]
    let selectedURL: URL?

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 1) {
                ForEach(items) { item in
                    let isSelected = selectedURL?.path == item.url.path || vm.selection.contains(item.id)
                    HStack(spacing: 7) {
                        Image(systemName: item.symbol)
                            .font(.system(size: 13))
                            .foregroundStyle(item.tint)
                            .frame(width: 16)
                        Text(item.name)
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.9))
                            .lineLimit(1)
                        Spacer(minLength: 4)
                        if item.isDirectory {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.white.opacity(0.3))
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(isSelected ? Color(red: 0.2, green: 0.47, blue: 0.98).opacity(0.35) : Color.clear)
                    .contentShape(Rectangle())
                    .onTapGesture { vm.selectInColumn(item) }
                    .finderContextMenu(vm: vm, item: item)
                    .draggable(item.id)
                }
            }
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .frame(maxHeight: .infinity)
        .background(Color.white.opacity(0.02))
    }
}
