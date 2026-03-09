import Foundation

enum MatchStatus: String, Codable {
    case scheduled
    case inProgress = "in_progress"
    case pendingReview = "pending_review"
    case completed
}

struct GameResult: Codable {
    let gameOrder: Int
    let homePlayerName: String?
    let awayPlayerName: String?
    let homeScore: Int
    let awayScore: Int
}

struct ScoreSubmission: Codable {
    let homeScore: Int
    let awayScore: Int
    let games: [GameResult]?
    let submittedBy: String
    let submittedAt: Int
}

struct Match: Codable, Identifiable {
    let id: String
    let competitionId: String
    let round: Int
    let matchday: Int
    let homeTeamId: String
    let awayTeamId: String
    let homeTeamName: String
    let awayTeamName: String
    let scheduledDate: String?
    let venue: String?
    let status: MatchStatus
    let homeScore: Int
    let awayScore: Int
    let games: [GameResult]?
    let homeSubmission: ScoreSubmission?
    let awaySubmission: ScoreSubmission?
    let confirmedBy: String?
    let submittedBy: String?
    let createdAt: Int
    let updatedAt: Int
}
