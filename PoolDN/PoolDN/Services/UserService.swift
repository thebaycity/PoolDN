import Foundation

enum UserService {
    static func getUser(_ id: String) async throws -> User {
        try await APIClient.shared.get("/users/\(id)")
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
