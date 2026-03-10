import Foundation

enum AuthService {
    static func register(email: String, password: String, name: String, nickname: String? = nil, role: String = "player") async throws -> AuthResponse {
        struct RegisterBody: Encodable {
            let email: String
            let password: String
            let name: String
            let nickname: String?
            let role: String
        }
        let body = RegisterBody(email: email, password: password, name: name, nickname: nickname, role: role)
        let response: AuthResponse = try await APIClient.shared.post("/auth/register", body: body, authenticated: false)
        KeychainHelper.save(response.token, forKey: AppConfig.tokenKey)
        return response
    }

    static func login(email: String, password: String) async throws -> AuthResponse {
        struct LoginBody: Encodable {
            let email: String
            let password: String
        }
        let body = LoginBody(email: email, password: password)
        let response: AuthResponse = try await APIClient.shared.post("/auth/login", body: body, authenticated: false)
        KeychainHelper.save(response.token, forKey: AppConfig.tokenKey)
        return response
    }

    static func getMe() async throws -> User {
        try await APIClient.shared.get("/auth/me")
    }

    static func changePassword(currentPassword: String, newPassword: String) async throws {
        struct Body: Encodable {
            let currentPassword: String
            let newPassword: String
        }
        let _: MessageResponse = try await APIClient.shared.post(
            "/auth/change-password",
            body: Body(currentPassword: currentPassword, newPassword: newPassword)
        )
    }

    static func logout() {
        KeychainHelper.delete(forKey: AppConfig.tokenKey)
    }

    static var isAuthenticated: Bool {
        KeychainHelper.load(forKey: AppConfig.tokenKey) != nil
    }
}
