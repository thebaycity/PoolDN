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
    let actioned: Bool
    let referenceId: String?
    let referenceType: String?
    let metadata: String?
    let createdAt: Int
    let updatedAt: Int

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        type = try container.decode(String.self, forKey: .type)
        title = try container.decode(String.self, forKey: .title)
        message = try container.decode(String.self, forKey: .message)
        read = try container.decode(Bool.self, forKey: .read)
        actioned = try container.decodeIfPresent(Bool.self, forKey: .actioned) ?? false
        referenceId = try container.decodeIfPresent(String.self, forKey: .referenceId)
        referenceType = try container.decodeIfPresent(String.self, forKey: .referenceType)
        metadata = try container.decodeIfPresent(String.self, forKey: .metadata)
        createdAt = try container.decode(Int.self, forKey: .createdAt)
        updatedAt = try container.decode(Int.self, forKey: .updatedAt)
    }

    var decodedMetadata: NotificationMetadata? {
        guard let metadata, let data = metadata.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(NotificationMetadata.self, from: data)
    }

    var isActionable: Bool {
        guard !actioned else { return false }
        switch type {
        case "competition_invitation", "score_submitted", "score_disputed":
            return true
        default:
            return false
        }
    }
}
