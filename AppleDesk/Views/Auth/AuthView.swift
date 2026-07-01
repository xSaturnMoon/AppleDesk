import SwiftUI

struct AuthView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var mode: AuthMode = .login
    @State private var username = ""
    @State private var password = ""
    @State private var selectedColor: Color = .blue
    @State private var appear = false

    private let avatarColors: [Color] = [.blue, .purple, .pink, .orange, .green, .cyan, .indigo]

    enum AuthMode: String, CaseIterable {
        case login = "Accedi"
        case register = "Registrati"
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                background

                HStack(spacing: 0) {
                    brandingPanel
                        .frame(width: max(geo.size.width * 0.42, 320))

                    Spacer(minLength: 24)

                    authPanel
                        .frame(maxWidth: 400)
                        .padding(.trailing, max(48, geo.size.width * 0.08))
                }
                .padding(.vertical, 48)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.spring(duration: 0.7, bounce: 0.12).delay(0.15)) { appear = true }
        }
    }

    // MARK: - Background

    private var background: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.09, blue: 0.14),
                    Color(red: 0.04, green: 0.05, blue: 0.09),
                    Color(red: 0.06, green: 0.07, blue: 0.12)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(selectedColor.opacity(0.14))
                .frame(width: 420, height: 420)
                .blur(radius: 90)
                .offset(x: -180, y: -120)

            Circle()
                .fill(Color.white.opacity(0.04))
                .frame(width: 360, height: 360)
                .blur(radius: 70)
                .offset(x: 220, y: 200)
        }
        .ignoresSafeArea()
    }

    // MARK: - Left branding (Windows 11 / macOS lock screen)

    private var brandingPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()

            TimelineView(.periodic(from: .now, by: 1)) { ctx in
                VStack(alignment: .leading, spacing: 4) {
                    Text(ctx.date, format: .dateTime.hour().minute())
                        .font(.system(size: 72, weight: .thin, design: .rounded))
                        .foregroundStyle(.white)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                    Text(ctx.date, format: .dateTime.weekday(.wide).day().month(.wide))
                        .font(.system(size: 18, weight: .regular, design: .rounded))
                        .foregroundStyle(.white.opacity(0.55))
                }
            }
            .padding(.leading, 56)

            Spacer()

            HStack(spacing: 10) {
                Image(systemName: "laptopcomputer")
                    .font(.system(size: 15, weight: .medium))
                Text("AppleDesk")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(.white.opacity(0.4))
            .padding(.leading, 56)
            .padding(.bottom, 8)
        }
        .opacity(appear ? 1 : 0)
        .offset(x: appear ? 0 : -24)
    }

    // MARK: - Right auth panel

    private var authPanel: some View {
        VStack(spacing: 28) {
            avatarHeader

            Picker("Modalità", selection: $mode) {
                ForEach(AuthMode.allCases, id: \.self) { m in
                    Text(m.rawValue).tag(m)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: mode) { _, _ in authVM.error = nil }

            VStack(spacing: 14) {
                AuthField(placeholder: "Nome utente", text: $username, icon: "person.fill")
                AuthField(placeholder: "Password", text: $password, icon: "lock.fill", isSecure: true)
            }

            if mode == .register {
                avatarColorPicker
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            if let err = authVM.error {
                Text(err)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.red.opacity(0.9))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .transition(.opacity)
            }

            Button(action: submit) {
                Text(mode == .login ? "Accedi" : "Crea account")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(.white.opacity(0.14))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(.white.opacity(0.2), lineWidth: 0.5)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(36)
        .background(.ultraThinMaterial)
        .environment(\.colorScheme, .dark)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.22), .white.opacity(0.06)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.5
                )
        )
        .shadow(color: .black.opacity(0.35), radius: 40, y: 20)
        .scaleEffect(appear ? 1 : 0.96)
        .opacity(appear ? 1 : 0)
        .animation(.spring(duration: 0.45, bounce: 0.1), value: mode)
    }

    private var avatarHeader: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [selectedColor.opacity(0.55), selectedColor.opacity(0.25)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 76, height: 76)
                Text(avatarInitial)
                    .font(.system(size: 32, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
            }
            .animation(.spring(duration: 0.35, bounce: 0.2), value: username)

            Text(mode == .login ? "Bentornato" : "Nuovo account")
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
            Text("iPadOS 26 · AppleDesk")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.4))
        }
    }

    private var avatarColorPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Colore avatar")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.45))
            HStack(spacing: 12) {
                ForEach(avatarColors, id: \.self) { color in
                    Circle()
                        .fill(color)
                        .frame(width: 28, height: 28)
                        .overlay(
                            Circle()
                                .stroke(.white, lineWidth: selectedColor == color ? 2 : 0)
                                .padding(-3)
                        )
                        .scaleEffect(selectedColor == color ? 1.12 : 1)
                        .onTapGesture { withAnimation(.spring(duration: 0.3)) { selectedColor = color } }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var avatarInitial: String {
        let t = username.trimmingCharacters(in: .whitespaces)
        guard let first = t.first else { return "?" }
        return String(first).uppercased()
    }

    private func submit() {
        withAnimation(.spring(duration: 0.35, bounce: 0.15)) {
            switch mode {
            case .login:
                authVM.login(username: username, password: password)
            case .register:
                authVM.register(username: username, password: password, color: selectedColor)
            }
        }
    }
}

// MARK: - Auth field

private struct AuthField: View {
    let placeholder: String
    @Binding var text: String
    let icon: String
    var isSecure = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.4))
                .frame(width: 20)
            if isSecure {
                SecureField(placeholder, text: $text)
                    .font(.system(size: 15, design: .rounded))
                    .foregroundStyle(.white)
                    .tint(.white)
            } else {
                TextField(placeholder, text: $text)
                    .font(.system(size: 15, design: .rounded))
                    .foregroundStyle(.white)
                    .tint(.white)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(.white.opacity(0.1), lineWidth: 0.5)
        )
    }
}
