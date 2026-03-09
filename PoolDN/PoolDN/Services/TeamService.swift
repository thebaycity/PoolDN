import Foundation

enum TeamService {
    static func listTeams(limit: Int = 20, offset: Int = 0) async throws -> PaginatedResponse<Team> {
        try await APIClient.shared.get("/teams?limit=\(limit)&offset=\(offset)")
    }

    static func getTeam(_ id: String) async throws -> Team {
        try await APIClient.shared.get("/teams/\(id)")
    }

    static func createTeam(name: String, city: String? = nil, homeVenue: String? = nil) async throws -> Team {
        struct Body: Encodable {
            let name: String
            let city: String?
            let homeVenue: String?
        }
        return try await APIClient.shared.post("/teams", body: Body(name: name, city: city, homeVenue: homeVenue))
    }

    static func updateTeam(_ id: String, name: String? = nil, city: String? = nil, homeVenue: String? = nil) async throws -> Team {
        struct Body: Encodable {
            let name: String?
            let city: String?
            let homeVenue: String?
        }
        return try await APIClient.shared.put("/teams/\(id)", body: Body(name: name, city: city, homeVenue: homeVenue))
    }

    static func invitePlayer(teamId: String, email: String) async throws -> TeamInvitation {
        struct Body: Encodable {
            let email: String
        }
        return try await APIClient.shared.post("/teams/\(teamId)/invite", body: Body(email: email))
    }

    static func getPendingInvitations() async throws -> [TeamInvitation] {
        try await APIClient.shared.get("/team-invitations/pending")
    }

    static func respondToInvitation(invitationId: String, accept: Bool) async throws -> TeamInvitation {
        struct Body: Encodable {
            let accept: Bool
        }
        return try await APIClient.shared.post("/team-invitations/\(invitationId)/respond", body: Body(accept: accept))
    }

    static func getPlayerTeams(playerId: String) async throws -> [Team] {
        try await APIClient.shared.get("/users/\(playerId)/teams")
    }
}
