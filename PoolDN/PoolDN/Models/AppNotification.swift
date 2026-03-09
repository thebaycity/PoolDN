import Foundation

struct NotificationMetadata: Codable {
    let teamId: String?
    let teamName: String?
    let competitionName: String?
    let matchId: String?
    let homeTeamName: String?
    let awayTeamName: String?
    let homeScore: Int?
    let awayScore: Int?
    let submitterName: String?
    let homeSubmission: ScoreSubmissionSummary?
    let awaySubmission: ScoreSubmissionSummary?

    struct ScoreSubmissionSummary: Codable {
        let homeScore: Int
        let awayScore: Int
    }
}

struct AppNotification: Codable, Identifiable {
    let id: String
    let userId: String
    let type: String
    let title: String
    let message: String
    let read: Bool
    let referenceId: String?
    let referenceType: String?
    let metadata: String?
    let createdAt: Int
    let updatedAt: Int

    var decodedMetadata: NotificationMetadata? {
        guard let metadata, let data = metadata.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(NotificationMetadata.self, from: data)
    }

    var isActionable: Bool {
        switch type {
        case "competition_invitation", "score_submitted", "score_disputed":
            return true
        default:
            return false
        }
    }
}
