import Foundation

enum UserService {
    static func getUser(_ id: String) async throws -> User {
        try await APIClient.shared.get("/users/\(id)")
    }

    static func searchUsers(query: String, role: String? = nil) async throws -> [User] {
        var parts: [String] = []
        if !query.isEmpty {
            let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
            parts.append("q=\(encoded)")
        }
        if let role {
            parts.append("role=\(role)")
        }
        let qs = parts.isEmpty ? "" : "?" + parts.joined(separator: "&")
        return try await APIClient.shared.get("/users/search\(qs)")
    }

    static func getUserTeams(_ id: String) async throws -> [Team] {
        try await APIClient.shared.get("/users/\(id)/teams")
    }

    static func getUserStats(_ id: String) async throws -> UserStats {
        try await APIClient.shared.get("/users/\(id)/stats")
    }

    static func uploadAvatar(userId: String, imageData: Data) async throws -> User {
        try await APIClient.shared.upload(
            path: "/users/\(userId)/avatar",
            imageData: imageData,
            filename: "avatar.jpg",
            mimeType: "image/jpeg"
        )
    }
}
