import SwiftUI

struct AuthView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var desktopVM: DesktopViewModel
    @EnvironmentObject var settingsVM: SettingsViewModel
    @State private var password = ""
    @State private var setupUsername = ""
    @State private var setupPassword = ""
    @State private var selectedColor: Color = .blue
    @State private var appear = false
    @FocusState private var passwordFocused: Bool

    private let avatarColors: [Color] = [.blue, .purple, .pink, .orange, .green, .cyan, .indigo]

    private var isSetup: Bool { !authVM.hasRegisteredAccount }

    var body: some View {
        ZStack {
            DesktopWallpaper()
                .blur(radius: settingsVM.blurIntensity)
                .overlay(Color.black.opacity(0.18))

            VStack(spacing: 0) {
                Spacer()

                if isSetup {
                    setupContent
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                } else {
                    signInContent
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                }

                Spacer()

                bottomBar
                    .padding(.horizontal, 44)
                    .padding(.bottom, 40)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            authVM.prepareAuthScreen()
            selectedColor = authVM.avatarColor
            withAnimation(.spring(duration: 0.65, bounce: 0.1).delay(0.1)) { appear = true }
            if !isSetup {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { passwordFocused = true }
            }
        }
    }

    // MARK: - Bottom bar: clock + power

    private var bottomBar: some View {
        HStack(alignment: .bottom) {
            clockPanel
            Spacer()
            powerButtons
        }
        .opacity(appear ? 1 : 0)
    }

    private var powerButtons: some View {
        HStack(spacing: 10) {
            glassIconButton(icon: "arrow.counterclockwise", label: "Riavvia") {
                desktopVM.restart(authVM: authVM)
            }
            glassIconButton(icon: "power", label: "Spegni", tint: .red.opacity(0.85)) {
                desktopVM.shutdown()
            }
        }
    }

    // MARK: - Sign-in

    private var signInContent: some View {
        VStack(spacing: 22) {
            userAvatar(size: 100, initial: userInitial, color: authVM.avatarColor)

            Text(authVM.username)
                .font(.system(size: 24, weight: .regular, design: .rounded))
                .foregroundStyle(.white)

            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    SecureField("Password", text: $password)
                        .font(.system(size: 16, design: .rounded))
                        .foregroundStyle(.white)
                        .tint(.white)
                        .focused($passwordFocused)
                        .onSubmit { submitSignIn() }

                    Button(action: submitSignIn) {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .background(.ultraThinMaterial)
                            .environment(\.colorScheme, .dark)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(.white.opacity(0.25), lineWidth: 0.5))
                    }
                    .buttonStyle(.plain)
                    .disabled(password.isEmpty)
                    .opacity(password.isEmpty ? 0.5 : 1)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                if let err = authVM.error {
                    Text(err)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.red.opacity(0.9))
                }
            }
            .frame(width: 320)
            .glassPanel(cornerRadius: 20)
        }
        .opacity(appear ? 1 : 0)
        .offset(y: appear ? 0 : 12)
    }

    // MARK: - Setup

    private var setupContent: some View {
        VStack(spacing: 20) {
            userAvatar(size: 88, initial: setupInitial, color: selectedColor)

            Text("Configura AppleDesk")
                .font(.system(size: 22, weight: .regular, design: .rounded))
                .foregroundStyle(.white)

            VStack(spacing: 18) {
                setupField("Nome utente", text: $setupUsername, secure: false)
                setupField("Password", text: $setupPassword, secure: true)

                HStack(spacing: 10) {
                    ForEach(avatarColors, id: \.self) { color in
                        Circle()
                            .fill(color)
                            .frame(width: 26, height: 26)
                            .overlay(
                                Circle()
                                    .stroke(.white, lineWidth: selectedColor == color ? 2 : 0)
                                    .padding(-3)
                            )
                            .onTapGesture { selectedColor = color }
                    }
                }
                .padding(.top, 4)

                if let err = authVM.error {
                    Text(err)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.red.opacity(0.9))
                }

                Button(action: submitSetup) {
                    Text("Continua")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(.ultraThinMaterial)
                        .environment(\.colorScheme, .dark)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(.white.opacity(0.22), lineWidth: 0.5)
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(24)
            .frame(width: 340)
            .glassPanel(cornerRadius: 24)
        }
        .opacity(appear ? 1 : 0)
        .offset(y: appear ? 0 : 12)
    }

    // MARK: - Clock

    private var clockPanel: some View {
        TimelineView(.periodic(from: .now, by: 1)) { ctx in
            VStack(alignment: .leading, spacing: 2) {
                Text(ctx.date, format: .dateTime.hour().minute())
                    .font(.system(size: 64, weight: .thin, design: .rounded))
                    .foregroundStyle(.white)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                Text(ctx.date, format: .dateTime.weekday(.wide).day().month(.wide))
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundStyle(.white.opacity(0.55))
            }
        }
    }

    // MARK: - Helpers

    private func glassIconButton(icon: String, label: String, tint: Color = .white,
                                 action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                Text(label)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
            }
            .foregroundStyle(tint)
            .padding(.horizontal, 16)
            .padding(.vertical, 11)
            .background(.ultraThinMaterial)
            .environment(\.colorScheme, .dark)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(.white.opacity(0.2), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }

    private func userAvatar(size: CGFloat, initial: String, color: Color) -> some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.35))
                .frame(width: size, height: size)
                .overlay(Circle().stroke(.white.opacity(0.2), lineWidth: 1))
            Text(initial)
                .font(.system(size: size * 0.38, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
        }
        .shadow(color: .black.opacity(0.2), radius: 12, y: 6)
    }

    private func setupField(_ placeholder: String, text: Binding<String>, secure: Bool) -> some View {
        Group {
            if secure {
                SecureField(placeholder, text: text)
            } else {
                TextField(placeholder, text: text)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
        }
        .font(.system(size: 15, design: .rounded))
        .foregroundStyle(.white)
        .tint(.white)
        .multilineTextAlignment(.center)
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(.white.opacity(0.12), lineWidth: 0.5)
        )
    }

    private var userInitial: String {
        guard let first = authVM.username.first else { return "?" }
        return String(first).uppercased()
    }

    private var setupInitial: String {
        let t = setupUsername.trimmingCharacters(in: .whitespaces)
        guard let first = t.first else { return "?" }
        return String(first).uppercased()
    }

    private func submitSignIn() {
        authVM.login(password: password)
        if authVM.error != nil { password = "" }
    }

    private func submitSetup() {
        authVM.register(username: setupUsername, password: setupPassword, color: selectedColor)
    }
}

// MARK: - Glass panel modifier

private extension View {
    func glassPanel(cornerRadius: CGFloat) -> some View {
        self
            .background(.ultraThinMaterial)
            .environment(\.colorScheme, .dark)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.28), .white.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            )
            .shadow(color: .black.opacity(0.25), radius: 24, y: 12)
    }
}
