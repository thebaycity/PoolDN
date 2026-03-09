import Foundation

@Observable
class StandingsViewModel {
    var standings: [Standing] = []
    var isLoading = false
    var errorMessage: String?

    func load(competitionId: String) async {
        isLoading = true
        do {
            standings = try await StandingsService.getStandings(competitionId)
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }
}
