import SwiftUI

struct ZenHomePage: View {
    @ObservedObject var vm: ZenViewModel
    let tab: ZenTabModel
    let onSubmit: () -> Void

    @Binding var urlText: String

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                VStack(spacing: 14) {
                    Image("zen_icon")
                        .resizable().scaledToFit()
                        .frame(width: 56, height: 56)

                    Text(greeting)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text(vm.isPrivateSession ? "SESSIONE PRIVATA" : "ZEN BROWSER")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .kerning(2)
                        .foregroundStyle(vm.isPrivateSession ? vm.theme.accent : .white.opacity(0.4))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .zenGlass(cornerRadius: 20)
                }
                .padding(.top, 32)

                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white.opacity(0.4))
                    TextField("Cerca con \(vm.searchEngine)", text: $urlText)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.white)
                        .onSubmit(onSubmit)
                    Button(action: onSubmit) {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(vm.theme.accent)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .zenGlass(cornerRadius: 22)
                .frame(maxWidth: 420)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 80, maximum: 100))], spacing: 16) {
                    ForEach(vm.shortcuts) { shortcut in
                        Button {
                            vm.loadURL(shortcut.url, on: tab)
                        } label: {
                            VStack(spacing: 8) {
                                ZStack {
                                    Circle()
                                        .fill(LinearGradient(
                                            colors: [vm.theme.accent.opacity(0.35), vm.theme.accent.opacity(0.12)],
                                            startPoint: .topLeading, endPoint: .bottomTrailing
                                        ))
                                        .frame(width: 48, height: 48)
                                        .overlay(Circle().stroke(.white.opacity(0.1), lineWidth: 0.8))
                                    Image(systemName: "globe")
                                        .font(.system(size: 20, weight: .light))
                                        .foregroundStyle(.white.opacity(0.85))
                                }
                                Text(shortcut.name)
                                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.8))
                                    .lineLimit(1)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(maxWidth: 380)
                .padding(.bottom, 40)
            }
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(colors: vm.theme.gradient, startPoint: .top, endPoint: .bottom)
        )
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let base = hour < 13 ? "Buongiorno" : (hour < 18 ? "Buon pomeriggio" : "Buonasera")
        return "\(base), benvenuto su Zen"
    }
}
