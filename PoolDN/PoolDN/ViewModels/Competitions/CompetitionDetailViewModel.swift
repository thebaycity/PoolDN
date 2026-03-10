import Foundation

@Observable
class CompetitionDetailViewModel {
    var competition: Competition?
    var participations: [TeamParticipation] = []
    var matches: [Match] = []
    var standings: [Standing] = []
    var playerRatings: [PlayerRating] = []
    var isLoading = false
    var errorMessage: String?
    var actionMessage: String?

    // Matches pagination
    var isLoadingMoreMatches = false
    var hasMoreMatches = false
    private var matchOffset = 0
    private let matchPageSize = 20

    // Participations pagination
    var isLoadingMoreParticipations = false
    var hasMoreParticipations = false
    private var participationOffset = 0
    private let participationPageSize = 20

    func load(_ id: String) async {
        isLoading = true
        errorMessage = nil
        matchOffset = 0
        participationOffset = 0
        do {
            competition = try await CompetitionService.getCompetition(id)
            let participationPage = try await CompetitionService.getParticipations(id, limit: participationPageSize, offset: 0)
            participations = participationPage.data
            hasMoreParticipations = participationPage.hasMore
            participationOffset = participationPage.data.count

            if competition?.status == .active || competition?.status == .completed {
                let matchPage = try await MatchService.getCompetitionMatches(id, limit: matchPageSize, offset: 0)
                matches = matchPage.data
                hasMoreMatches = matchPage.hasMore
                matchOffset = matchPage.data.count
                standings = try await StandingsService.getStandings(id)
                playerRatings = try await PlayerRatingService.getPlayerRatings(id)
            }
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }

    func loadMoreMatches() async {
        guard !isLoadingMoreMatches, hasMoreMatches, let id = competition?.id else { return }
        isLoadingMoreMatches = true
        do {
            let page = try await MatchService.getCompetitionMatches(id, limit: matchPageSize, offset: matchOffset)
            matches.append(contentsOf: page.data)
            hasMoreMatches = page.hasMore
            matchOffset += page.data.count
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoadingMoreMatches = false
    }

    func loadMoreParticipations() async {
        guard !isLoadingMoreParticipations, hasMoreParticipations, let id = competition?.id else { return }
        isLoadingMoreParticipations = true
        do {
            let page = try await CompetitionService.getParticipations(id, limit: participationPageSize, offset: participationOffset)
            participations.append(contentsOf: page.data)
            hasMoreParticipations = page.hasMore
            participationOffset += page.data.count
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoadingMoreParticipations = false
    }

    func publish() async {
        guard let id = competition?.id else { return }
        do {
            competition = try await CompetitionService.publish(id)
            actionMessage = "Competition published!"
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func apply(teamId: String) async {
        guard let id = competition?.id else { return }
        do {
            _ = try await CompetitionService.apply(competitionId: id, teamId: teamId)
            actionMessage = "Application submitted!"
            await load(id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func handleApplication(teamId: String, accept: Bool) async {
        guard let id = competition?.id else { return }
        do {
            _ = try await CompetitionService.handleApplication(competitionId: id, teamId: teamId, action: accept ? "accept" : "reject")
            await load(id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func respondToInvitation(teamId: String, accept: Bool) async {
        guard let id = competition?.id else { return }
        do {
            _ = try await CompetitionService.respondToInvitation(competitionId: id, teamId: teamId, accept: accept)
            actionMessage = accept ? "Invitation accepted!" : "Invitation declined."
            await load(id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func inviteTeam(teamId: String) async {
        guard let id = competition?.id else { return }
        do {
            _ = try await CompetitionService.inviteTeam(competitionId: id, teamId: teamId)
            actionMessage = "Team invited!"
            await load(id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func withdrawApplication(teamId: String) async {
        guard let id = competition?.id else { return }
        do {
            try await CompetitionService.withdrawApplication(competitionId: id, teamId: teamId)
            actionMessage = "Application withdrawn"
            await load(id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func withdrawInvitation(teamId: String) async {
        guard let id = competition?.id else { return }
        do {
            try await CompetitionService.withdrawInvitation(competitionId: id, teamId: teamId)
            actionMessage = "Invitation withdrawn"
            await load(id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func removeTeam(teamId: String) async {
        guard let id = competition?.id else { return }
        do {
            try await CompetitionService.removeTeam(competitionId: id, teamId: teamId)
            actionMessage = "Team removed"
            await load(id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func completeCompetition() async {
        guard let id = competition?.id else { return }
        do {
            competition = try await CompetitionService.completeCompetition(id)
            actionMessage = "Competition completed!"
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func closeAndGenerate() async {
        guard let id = competition?.id else { return }
        do {
            competition = try await CompetitionService.closeApplications(id)
            matches = try await CompetitionService.generateMatches(id)
            await load(id)
            actionMessage = "Matches generated!"
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

enum StandingsService {
    static func getStandings(_ competitionId: String) async throws -> [Standing] {
        try await APIClient.shared.get("/competitions/\(competitionId)/standings")
    }
}

enum PlayerRatingService {
    static func getPlayerRatings(_ competitionId: String) async throws -> [PlayerRating] {
        try await APIClient.shared.get("/competitions/\(competitionId)/player-ratings")
    }
}
