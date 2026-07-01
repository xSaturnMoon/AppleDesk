import SwiftUI

struct FinderToolbar: View {
    @ObservedObject var vm: FinderViewModel

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                HStack(spacing: 2) {
                    Button { vm.goBack() } label: {
                        Image(systemName: "chevron.left")
                    }
                    .disabled(!vm.canGoBack)

                    Button { vm.goForward() } label: {
                        Image(systemName: "chevron.right")
                    }
                    .disabled(!vm.canGoForward)
                }
                .font(.system(size: 13, weight: .semibold))
                .buttonStyle(.plain)
                .foregroundStyle(.white.opacity(0.85))

                Text(vm.currentTitle)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Spacer()

                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.4))
                    TextField("Cerca", text: $vm.searchText)
                        .font(.system(size: 13))
                        .foregroundStyle(.white)
                        .textFieldStyle(.plain)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .frame(width: 160)
                .background(Color.white.opacity(0.08), in: Capsule())

                Button {
                    vm.showNewFolderPrompt = true
                } label: {
                    Image(systemName: "folder.badge.plus")
                }
                .buttonStyle(.plain)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.85))

                Picker("", selection: $vm.viewMode) {
                    ForEach(FinderViewMode.allCases, id: \.self) { mode in
                        Image(systemName: mode.symbol).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 110)
            }
            .padding(.horizontal, 16)
            .frame(height: 46)
            .background(.ultraThinMaterial)

            Rectangle().fill(.white.opacity(0.08)).frame(height: 1)

            // Breadcrumb ("barra percorso" di macOS)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 5) {
                    ForEach(Array(vm.breadcrumb.enumerated()), id: \.offset) { index, crumb in
                        Button {
                            vm.navigate(to: crumb.url)
                        } label: {
                            Text(crumb.name)
                                .font(.system(size: 11, weight: index == vm.breadcrumb.count - 1 ? .semibold : .regular))
                                .foregroundStyle(index == vm.breadcrumb.count - 1 ? .white.opacity(0.9) : .white.opacity(0.5))
                        }
                        .buttonStyle(.plain)

                        if index < vm.breadcrumb.count - 1 {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(.white.opacity(0.3))
                        }
                    }
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
            }
            .background(Color.black.opacity(0.15))

            Rectangle().fill(.white.opacity(0.06)).frame(height: 1)
        }
    }
}
