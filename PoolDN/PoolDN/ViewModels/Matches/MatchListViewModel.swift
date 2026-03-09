import Foundation

@Observable
class MatchListViewModel {
    var matches: [Match] = []
    var isLoading = false
    var errorMessage: String?

    var matchesByRound: [(round: Int, matches: [Match])] {
        let grouped = Dictionary(grouping: matches) { $0.round }
        return grouped.keys.sorted().map { (round: $0, matches: grouped[$0]!) }
    }

    func load(competitionId: String) async {
        isLoading = true
        do {
            matches = try await MatchService.getCompetitionMatches(competitionId)
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }
}
