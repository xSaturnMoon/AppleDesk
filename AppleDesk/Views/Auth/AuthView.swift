import SwiftUI

struct AuthView: View {
    @EnvironmentObject var authVM: AuthViewModel
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
                .blur(radius: 28)
                .overlay(Color.black.opacity(0.12))

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

                clockPanel
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 48)
                    .padding(.bottom, 44)
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

    // MARK: - Windows 11 sign-in (solo password)

    private var signInContent: some View {
        VStack(spacing: 20) {
            userAvatar(size: 96, initial: userInitial, color: authVM.avatarColor)

            Text(authVM.username)
                .font(.system(size: 22, weight: .regular, design: .rounded))
                .foregroundStyle(.white)

            VStack(spacing: 10) {
                HStack(spacing: 12) {
                    SecureField("Password", text: $password)
                        .font(.system(size: 15, design: .rounded))
                        .foregroundStyle(.white)
                        .tint(.white)
                        .focused($passwordFocused)
                        .onSubmit { submitSignIn() }

                    Button(action: submitSignIn) {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(.white.opacity(password.isEmpty ? 0.12 : 0.22))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .disabled(password.isEmpty)
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 10)
                .frame(width: 280)
                .overlay(alignment: .bottom) {
                    Rectangle().fill(.white.opacity(0.35)).frame(height: 1)
                }

                if let err = authVM.error {
                    Text(err)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.red.opacity(0.9))
                }
            }
        }
        .opacity(appear ? 1 : 0)
        .offset(y: appear ? 0 : 12)
    }

    // MARK: - Prima configurazione (una tantum)

    private var setupContent: some View {
        VStack(spacing: 22) {
            userAvatar(size: 80, initial: setupInitial, color: selectedColor)

            Text("Configura AppleDesk")
                .font(.system(size: 20, weight: .regular, design: .rounded))
                .foregroundStyle(.white.opacity(0.9))

            VStack(spacing: 16) {
                setupField("Nome utente", text: $setupUsername, secure: false)
                setupField("Password", text: $setupPassword, secure: true)

                HStack(spacing: 10) {
                    ForEach(avatarColors, id: \.self) { color in
                        Circle()
                            .fill(color)
                            .frame(width: 24, height: 24)
                            .overlay(
                                Circle()
                                    .stroke(.white, lineWidth: selectedColor == color ? 2 : 0)
                                    .padding(-3)
                            )
                            .onTapGesture { selectedColor = color }
                    }
                }

                if let err = authVM.error {
                    Text(err)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.red.opacity(0.9))
                }

                Button(action: submitSetup) {
                    Text("Continua")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 10)
                        .background(.white.opacity(0.16))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .frame(width: 300)
        }
        .opacity(appear ? 1 : 0)
        .offset(y: appear ? 0 : 12)
    }

    // MARK: - Clock (bottom-left, Windows 11)

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
        .opacity(appear ? 1 : 0)
    }

    // MARK: - Helpers

    private func userAvatar(size: CGFloat, initial: String, color: Color) -> some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.35))
                .frame(width: size, height: size)
            Text(initial)
                .font(.system(size: size * 0.38, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
        }
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
        .overlay(alignment: .bottom) {
            Rectangle().fill(.white.opacity(0.25)).frame(height: 1)
        }
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
