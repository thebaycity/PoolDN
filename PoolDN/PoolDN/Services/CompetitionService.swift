import Foundation

enum CompetitionService {
    static func listCompetitions(limit: Int = 20, offset: Int = 0) async throws -> PaginatedResponse<Competition> {
        try await APIClient.shared.get("/competitions?limit=\(limit)&offset=\(offset)")
    }

    static func getCompetition(_ id: String) async throws -> Competition {
        try await APIClient.shared.get("/competitions/\(id)")
    }

    static func createCompetition(name: String, description: String? = nil, gameType: String? = nil, startDate: String? = nil, prize: Double? = nil, city: String? = nil, country: String? = nil) async throws -> Competition {
        struct Body: Encodable {
            let name: String
            let description: String?
            let gameType: String?
            let startDate: String?
            let prize: Double?
            let city: String?
            let country: String?
        }
        return try await APIClient.shared.post("/competitions", body: Body(name: name, description: description, gameType: gameType, startDate: startDate, prize: prize, city: city, country: country))
    }

    static func updateCompetition(_ id: String, data: UpdateCompetitionData) async throws -> Competition {
        try await APIClient.shared.put("/competitions/\(id)", body: data)
    }

    static func publish(_ id: String) async throws -> Competition {
        try await APIClient.shared.post("/competitions/\(id)/publish")
    }

    static func apply(competitionId: String, teamId: String) async throws -> TeamParticipation {
        struct Body: Encodable {
            let teamId: String
        }
        return try await APIClient.shared.post("/competitions/\(competitionId)/apply", body: Body(teamId: teamId))
    }

    static func handleApplication(competitionId: String, teamId: String, action: String) async throws -> TeamParticipation {
        struct Body: Encodable {
            let action: String
        }
        return try await APIClient.shared.put("/competitions/\(competitionId)/applications/\(teamId)", body: Body(action: action))
    }

    static func closeApplications(_ id: String) async throws -> Competition {
        try await APIClient.shared.post("/competitions/\(id)/close-applications")
    }

    static func generateMatches(_ id: String) async throws -> [Match] {
        try await APIClient.shared.post("/competitions/\(id)/generate-matches")
    }

    static func completeCompetition(_ id: String) async throws -> Competition {
        try await APIClient.shared.post("/competitions/\(id)/complete")
    }

    static func getParticipations(_ competitionId: String, limit: Int = 20, offset: Int = 0) async throws -> PaginatedResponse<TeamParticipation> {
        try await APIClient.shared.get("/competitions/\(competitionId)/participations?limit=\(limit)&offset=\(offset)")
    }

    static func inviteTeam(competitionId: String, teamId: String) async throws -> TeamParticipation {
        struct Body: Encodable {
            let teamId: String
        }
        return try await APIClient.shared.post("/competitions/\(competitionId)/invite", body: Body(teamId: teamId))
    }

    static func respondToInvitation(competitionId: String, teamId: String, accept: Bool) async throws -> TeamParticipation {
        struct Body: Encodable {
            let accept: Bool
        }
        return try await APIClient.shared.post("/competitions/\(competitionId)/invitations/\(teamId)/respond", body: Body(accept: accept))
    }

    static func withdrawInvitation(competitionId: String, teamId: String) async throws {
        try await APIClient.shared.delete("/competitions/\(competitionId)/invitations/\(teamId)")
    }

    static func removeTeam(competitionId: String, teamId: String) async throws {
        try await APIClient.shared.delete("/competitions/\(competitionId)/teams/\(teamId)")
    }

    static func getCompetitionInvitations() async throws -> [CompetitionInvitation] {
        try await APIClient.shared.get("/competition-invitations")
    }
}

struct UpdateCompetitionData: Encodable {
    var name: String?
    var description: String?
    var gameType: String?
    var startDate: String?
    var prize: Double?
    var city: String?
    var country: String?
    var teamSizeMin: Int?
    var teamSizeMax: Int?
    var gameStructure: [GameDefinition]?
    var scheduleConfig: ScheduleConfig?
}
