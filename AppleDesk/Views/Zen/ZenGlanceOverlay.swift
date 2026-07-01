import SwiftUI

struct ZenGlanceOverlay: View {
    @ObservedObject var vm: ZenViewModel
    @StateObject private var glanceTab = ZenTabModel()

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture { vm.closeGlance() }

            VStack(spacing: 0) {
                glanceHeader
                ZenWebView(tab: glanceTab, vm: vm, isGlance: true)
            }
            .frame(width: 640, height: 440)
            .zenGlass(radius: 14)
            .shadow(color: .black.opacity(0.4), radius: 24, y: 10)
        }
        .onAppear { loadGlanceURL() }
        .onChange(of: vm.glanceURL) { _, _ in loadGlanceURL() }
    }

    private var glanceHeader: some View {
        HStack(spacing: 12) {
            Image(systemName: "eye")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(ZenPalette.textSecondary)
            Text("Zen Glance")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(ZenPalette.textPrimary)
            Spacer()
            Button("Apri in scheda") { vm.promoteGlanceToTab() }
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(ZenPalette.accent)
                .buttonStyle(.plain)
            Button { vm.closeGlance() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(ZenPalette.textTertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .environment(\.colorScheme, .dark)
    }

    private func loadGlanceURL() {
        guard let url = vm.glanceURL else { return }
        glanceTab.loadedURL = url
        glanceTab.urlText = url.absoluteString
        glanceTab.title = url.host ?? "Anteprima"
    }
}
