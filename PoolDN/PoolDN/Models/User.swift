import Foundation

struct User: Codable, Identifiable {
    let id: String
    let email: String
    let role: String
    let name: String
    let nickname: String?
    let avatarUrl: String?
    let createdAt: Int
    let updatedAt: Int
}

struct UserSummary: Codable {
    let id: String
    let email: String
    let name: String
    let nickname: String?
    let role: String
}

struct UserStats: Codable {
    let totalMatches: Int
    let wins: Int
    let losses: Int
    let draws: Int
    let teamsCount: Int
}
