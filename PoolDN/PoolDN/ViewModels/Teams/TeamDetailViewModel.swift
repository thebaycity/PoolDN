import Foundation

@Observable
class TeamDetailViewModel {
    var team: Team?
    var sentInvitations: [TeamInvitation] = []
    var isLoading = false
    var isDeleted = false
    var errorMessage: String?

    func load(_ id: String) async {
        isLoading = true
        do {
            team = try await TeamService.getTeam(id)
            sentInvitations = (try? await TeamService.getSentInvitations(teamId: id)) ?? []
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

    func updateTeamName(_ newName: String) async -> Bool {
        guard let teamId = team?.id else { return false }
        let trimmed = newName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return false }
        do {
            let updated = try await TeamService.updateTeam(teamId, name: trimmed)
            team = updated
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func deleteTeam() async -> Bool {
        guard let teamId = team?.id else { return false }
        do {
            try await TeamService.deleteTeam(teamId)
            isDeleted = true
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
