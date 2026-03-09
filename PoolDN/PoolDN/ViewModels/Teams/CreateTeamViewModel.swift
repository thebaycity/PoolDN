import Foundation

@Observable
class CreateTeamViewModel {
    var name = ""
    var city = ""
    var country = ""
    var homeVenue = ""
    var isLoading = false
    var errorMessage: String?

    func create() async -> Team? {
        guard !name.isEmpty else {
            errorMessage = "Team name is required"
            return nil
        }
        isLoading = true
        errorMessage = nil
        do {
            let team = try await TeamService.createTeam(
                name: name,
                city: city.isEmpty ? nil : city,
                homeVenue: homeVenue.isEmpty ? nil : homeVenue
            )
            isLoading = false
            return team
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            return nil
        }
    }
}
