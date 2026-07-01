import SwiftUI
import Combine

@MainActor
class AuthViewModel: ObservableObject {
    @Published var phase: AppPhase = .boot
    @Published var username: String = ""
    @Published var avatarColor: Color = .blue
    @Published var error: String? = nil

    private let usernameKey = "appledesk_username"
    private let passwordKey = "appledesk_password"
    private let colorKey    = "appledesk_avatarColor"
    private let loggedInKey = "appledesk_loggedIn"

    /// Account già configurato sul dispositivo (username + password salvati).
    var hasRegisteredAccount: Bool {
        let user = UserDefaults.standard.string(forKey: usernameKey) ?? ""
        let pass = UserDefaults.standard.string(forKey: passwordKey) ?? ""
        return !user.isEmpty && !pass.isEmpty
    }

    func prepareAuthScreen() {
        error = nil
        if hasRegisteredAccount {
            username = UserDefaults.standard.string(forKey: usernameKey) ?? ""
            loadAvatarColor()
        }
    }

    // MARK: Boot → sempre schermata di accesso
    func finishBoot() {
        UserDefaults.standard.set(false, forKey: loggedInKey)
        prepareAuthScreen()
        withAnimation { phase = .auth }
    }

    // MARK: Register (solo prima configurazione)
    func register(username: String, password: String, color: Color) {
        let name = username.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { error = "Scegli un nome utente"; return }
        guard password.count >= 4 else { error = "Password minimo 4 caratteri"; return }

        UserDefaults.standard.set(name, forKey: usernameKey)
        UserDefaults.standard.set(password, forKey: passwordKey)
        UserDefaults.standard.set(true, forKey: loggedInKey)
        saveColor(color)
        self.username = name
        self.avatarColor = color
        error = nil
        withAnimation { phase = .desktop }
    }

    // MARK: Login (solo password, come Windows 11)
    func login(password: String) {
        guard hasRegisteredAccount else {
            error = "Nessun account configurato"; return
        }
        let savedPass = UserDefaults.standard.string(forKey: passwordKey) ?? ""
        guard password == savedPass else {
            error = "Password errata"; return
        }
        username = UserDefaults.standard.string(forKey: usernameKey) ?? ""
        loadAvatarColor()
        UserDefaults.standard.set(true, forKey: loggedInKey)
        error = nil
        withAnimation { phase = .desktop }
    }

    // MARK: Logout
    func logout() {
        UserDefaults.standard.set(false, forKey: loggedInKey)
        prepareAuthScreen()
        withAnimation { phase = .auth }
    }

    func updateAvatarColor(_ color: Color) {
        saveColor(color)
        avatarColor = color
    }

    @discardableResult
    func changePassword(new: String, confirm: String) -> Bool {
        guard hasRegisteredAccount else { error = "Nessun account"; return false }
        guard new.count >= 4 else { error = "Minimo 4 caratteri"; return false }
        guard new == confirm else { error = "Le password non coincidono"; return false }
        UserDefaults.standard.set(new, forKey: passwordKey)
        error = nil
        return true
    }

    // MARK: Color persistence
    private func saveColor(_ color: Color) {
        if let data = try? NSKeyedArchiver.archivedData(withRootObject: UIColor(color), requiringSecureCoding: false) {
            UserDefaults.standard.set(data, forKey: colorKey)
        }
    }

    private func loadAvatarColor() {
        if let data = UserDefaults.standard.data(forKey: colorKey),
           let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: data) {
            avatarColor = Color(uiColor)
        }
    }
}
