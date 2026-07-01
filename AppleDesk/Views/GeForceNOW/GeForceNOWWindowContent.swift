import SwiftUI

struct GeForceNOWWindowContent: View {
    @EnvironmentObject var desktopVM: DesktopViewModel
    @StateObject private var browserVM = GFNBrowserViewModel(startURL: GFNLinks.hub)

    var body: some View {
        VStack(spacing: 0) {
            hubHeader
            GFNGamepadBanner()
            browserArea
        }
        .background(GFNPalette.background)
    }

    private var hubHeader: some View {
        HStack(spacing: 14) {
            HStack(spacing: 10) {
                Image("geforcenow_icon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                VStack(alignment: .leading, spacing: 1) {
                    Text("GeForce NOW")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(GFNPalette.textPrimary)
                    Text("Cloud Gaming NVIDIA")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(GFNPalette.textSecondary)
                }
            }

            Spacer()

            HStack(spacing: 8) {
                ForEach(GFNGame.featured) { game in
                    Button {
                        desktopVM.openApp(appItem(for: game))
                    } label: {
                        HStack(spacing: 6) {
                            Image(game.id == "cs2" ? "cs2_icon" : "geforcenow_icon")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 18, height: 18)
                            Text(game.name)
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .lineLimit(1)
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(GFNPalette.nvidiaGreen.opacity(0.22))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(GFNPalette.nvidiaGreen.opacity(0.45), lineWidth: 0.5)
                        )
                    }
                    .buttonStyle(.plain)
                }

                if browserVM.canGoBack {
                    GFNToolbarButton(icon: "chevron.left", action: browserVM.goBack)
                }
                GFNToolbarButton(icon: "person.crop.circle.fill", label: "Accedi", accent: true) {
                    browserVM.openLogin()
                }
                GFNToolbarButton(icon: "arrow.clockwise", action: browserVM.reload)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            LinearGradient(
                colors: [GFNPalette.surface, GFNPalette.background],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .overlay(alignment: .bottom) {
            Rectangle().fill(GFNPalette.stroke).frame(height: 0.5)
        }
    }

    private var browserArea: some View {
        ZStack {
            GFNWebView(vm: browserVM)
            overlay
        }
    }

    @ViewBuilder
    private var overlay: some View {
        switch browserVM.loadState {
        case .loading:
            loadingOverlay
        case .error(let message):
            errorOverlay(message)
        case .ready:
            EmptyView()
        }
    }

    private var loadingOverlay: some View {
        ZStack {
            GFNPalette.background.opacity(0.94)
            VStack(spacing: 14) {
                ProgressView()
                    .tint(GFNPalette.nvidiaGreenBright)
                    .scaleEffect(1.15)
                Text("Connessione a GeForce NOW…")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(GFNPalette.textSecondary)
            }
        }
    }

    private func errorOverlay(_ message: String) -> some View {
        ZStack {
            GFNPalette.background.opacity(0.96)
            VStack(spacing: 14) {
                Image(systemName: "cloud.slash")
                    .font(.system(size: 36, weight: .light))
                    .foregroundStyle(GFNPalette.nvidiaGreen)
                Text("Impossibile caricare GeForce NOW")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                Text(message)
                    .font(.system(size: 12))
                    .foregroundStyle(GFNPalette.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                Button("Riprova", action: browserVM.reload)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 8)
                    .background(GFNPalette.nvidiaGreenBright)
                    .clipShape(Capsule())
                    .buttonStyle(.plain)
            }
        }
    }

    private func appItem(for game: GFNGame) -> AppItem {
        AppItem.allApps.first { $0.id == game.id }
            ?? AppItem(id: game.id, name: game.name, icon: "gamecontroller.fill", iconAsset: nil, color: .green)
    }
}
