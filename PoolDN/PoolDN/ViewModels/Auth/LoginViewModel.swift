import Foundation

@Observable
class LoginViewModel {
    #if DEBUG
    var email = "toan@thebay.city"
    var password = "password123"
    #else
    var email = ""
    var password = ""
    #endif
    var isLoading = false
    var errorMessage: String?

    func login() async -> AuthResponse? {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields"
            return nil
        }
        isLoading = true
        errorMessage = nil
        do {
            let response = try await AuthService.login(email: email, password: password)
            isLoading = false
            return response
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            return nil
        }
    }
}
