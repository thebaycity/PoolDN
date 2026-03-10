import Foundation

struct TeamMember: Codable, Hashable {
    let playerId: String
    let role: String
    let joinedAt: String
    let name: String?
    let nickname: String?
    let avatarUrl: String?
}

struct Team: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let captainId: String
    let city: String?
    let homeVenue: String?
    let logoUrl: String?
    let members: [TeamMember]
    let createdAt: Int
    let updatedAt: Int
}
