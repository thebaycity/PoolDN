import Foundation

struct TeamInvitation: Codable, Identifiable {
    let id: String
    let teamId: String
    let teamName: String
    let invitedUserId: String?
    let invitedEmail: String?
    let invitedByUserId: String
    let status: String // "pending", "accepted", "rejected"
    let createdAt: Int
    let updatedAt: Int
}
