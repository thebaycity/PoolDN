import Foundation

enum NotificationService {
    static func getNotifications(limit: Int = 20, offset: Int = 0) async throws -> PaginatedResponse<AppNotification> {
        try await APIClient.shared.get("/notifications?limit=\(limit)&offset=\(offset)")
    }

    static func markRead(_ id: String) async throws -> AppNotification {
        try await APIClient.shared.put("/notifications/\(id)/read")
    }
}
