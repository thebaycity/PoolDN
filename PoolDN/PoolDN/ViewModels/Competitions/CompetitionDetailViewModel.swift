import Foundation

@Observable
class CompetitionDetailViewModel {
    var competition: Competition?
    var participations: [TeamParticipation] = []
    var matches: [Match] = []
    var standings: [Standing] = []
    var isLoading = false
    var errorMessage: String?
    var actionMessage: String?

    func load(_ id: String) async {
        isLoading = true
        errorMessage = nil
        do {
            competition = try await CompetitionService.getCompetition(id)
            participations = try await CompetitionService.getParticipations(id)

            if competition?.status == .active || competition?.status == .completed {
                matches = try await MatchService.getCompetitionMatches(id)
                standings = try await StandingsService.getStandings(id)
            }
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
        }
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
