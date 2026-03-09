import Foundation

struct RosterPlayer: Codable {
    let playerId: String
    let name: String
}

struct TeamParticipation: Codable, Identifiable {
    let id: String
    let competitionId: String
    let teamId: String
    let teamName: String
    let status: String // "pending", "accepted", "rejected", "invited", "declined"
    let roster: [RosterPlayer]?
    let homeVenue: String?
    let createdAt: Int
    let updatedAt: Int
}

struct CompetitionInvitation: Codable, Identifiable {
    let id: String
    let competitionId: String
    let teamId: String
    let teamName: String
    let competitionName: String
    let status: String
    let homeVenue: String?
    let createdAt: Int
    let updatedAt: Int
}
