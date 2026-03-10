import Foundation

enum MatchService {
    static func getCompetitionMatches(_ competitionId: String, limit: Int = 30, offset: Int = 0) async throws -> PaginatedResponse<Match> {
        try await APIClient.shared.get("/competitions/\(competitionId)/matches?limit=\(limit)&offset=\(offset)")
    }

    static func getMatch(_ id: String) async throws -> Match {
        try await APIClient.shared.get("/matches/\(id)")
    }

    static func submitResult(matchId: String, homeScore: Int, awayScore: Int, games: [GameResult]? = nil) async throws -> Match {
        struct Body: Encodable {
            let homeScore: Int
            let awayScore: Int
            let games: [GameResult]?
        }
        return try await APIClient.shared.post("/matches/\(matchId)/result", body: Body(homeScore: homeScore, awayScore: awayScore, games: games))
    }

    static func confirmResult(matchId: String, homeScore: Int, awayScore: Int, games: [GameResult]? = nil) async throws -> Match {
        struct Body: Encodable {
            let homeScore: Int
            let awayScore: Int
            let games: [GameResult]?
        }
        return try await APIClient.shared.post("/matches/\(matchId)/confirm", body: Body(homeScore: homeScore, awayScore: awayScore, games: games))
    }
}
