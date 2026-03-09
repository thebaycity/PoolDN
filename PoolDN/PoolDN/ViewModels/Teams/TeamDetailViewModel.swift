import Foundation

@Observable
class TeamDetailViewModel {
    var team: Team?
    var isLoading = false
    var errorMessage: String?

    func load(_ id: String) async {
        isLoading = true
        do {
            team = try await TeamService.getTeam(id)
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }

    func invitePlayer(email: String) async {
        guard let teamId = team?.id else { return }
        do {
            _ = try await TeamService.invitePlayer(teamId: teamId, email: email)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
