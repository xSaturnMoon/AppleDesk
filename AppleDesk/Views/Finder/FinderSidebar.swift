import SwiftUI

struct FinderSidebar: View {
    @ObservedObject var vm: FinderViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Preferiti")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white.opacity(0.35))
                        .padding(.horizontal, 14)
                        .padding(.top, 14)
                        .padding(.bottom, 4)

                    row(for: FinderCategory.root)

                    ForEach(FinderCategory.all) { category in
                        row(for: category)
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .frame(maxHeight: .infinity)
        .background(.ultraThinMaterial)
    }

    private func row(for category: FinderCategory) -> some View {
        let isSelected = vm.currentURL.path == category.url.path

        return Button {
            vm.navigate(to: category.url)
        } label: {
            HStack(spacing: 9) {
                Image(systemName: category.symbol)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(isSelected ? .white : Color(red: 0.35, green: 0.68, blue: 0.98))
                    .frame(width: 18)
                Text(category.name)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? .white : .white.opacity(0.75))
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(isSelected ? Color(red: 0.2, green: 0.47, blue: 0.98).opacity(0.85) : Color.clear)
            )
            .padding(.horizontal, 6)
        }
        .buttonStyle(.plain)
        .dropDestination(for: String.self) { paths, _ in
            for path in paths { vm.moveItem(withPath: path, to: category.url) }
            return true
        } isTargeted: { _ in }
    }
}
