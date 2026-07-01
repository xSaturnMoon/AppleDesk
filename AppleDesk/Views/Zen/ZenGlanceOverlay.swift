import SwiftUI

struct ZenGlanceOverlay: View {
    @ObservedObject var vm: ZenViewModel
    @StateObject private var glanceTab = ZenTabModel()

    var body: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture { vm.closeGlance() }

            VStack(spacing: 0) {
                glanceHeader
                ZenWebView(tab: glanceTab, vm: vm, isGlance: true)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(width: 620, height: 420)
            .zenGlass(cornerRadius: 16)
            .shadow(color: .black.opacity(0.45), radius: 30, y: 12)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.96)))
        .onAppear {
            if let url = vm.glanceURL {
                glanceTab.loadedURL = url
                glanceTab.urlText = url.absoluteString
                glanceTab.title = url.host ?? "Anteprima"
            }
        }
        .onChange(of: vm.glanceURL) { _, newURL in
            if let url = newURL {
                glanceTab.loadedURL = url
                glanceTab.urlText = url.absoluteString
                glanceTab.title = url.host ?? "Anteprima"
            }
        }
    }

    private var glanceHeader: some View {
        HStack(spacing: 10) {
            Image(systemName: "eye.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(vm.theme.accent)
            Text("Zen Glance")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Spacer()
            Button { vm.promoteGlanceToTab() } label: {
                Label("Apri in scheda", systemImage: "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.8))
            }
            .buttonStyle(.plain)
            Button { vm.closeGlance() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.white.opacity(0.45))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .environment(\.colorScheme, .dark)
    }
}
