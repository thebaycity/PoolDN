import Foundation

@Observable
class RegisterViewModel {
    var name = ""
    var email = ""
    var password = ""
    var confirmPassword = ""
    var nickname = ""
    var role = "player"
    var isLoading = false
    var errorMessage: String?

    func register() async -> AuthResponse? {
        guard !name.isEmpty, !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all required fields"
            return nil
        }
        guard password == confirmPassword else {
            errorMessage = "Passwords don't match"
            return nil
        }
        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"
            return nil
        }
        isLoading = true
        errorMessage = nil
        do {
            let response = try await AuthService.register(
                email: email,
                password: password,
                name: name,
                nickname: nickname.isEmpty ? nil : nickname,
                role: role
            )
            isLoading = false
            return response
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            return nil
        }
    }
}
