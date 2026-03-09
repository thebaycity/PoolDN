import Foundation

@Observable
class SubmitResultViewModel {
    var homeScore = 0
    var awayScore = 0
    var isLoading = false
    var errorMessage: String?

    func submit(matchId: String) async -> Match? {
        isLoading = true
        errorMessage = nil
        do {
            let match = try await MatchService.submitResult(
                matchId: matchId,
                homeScore: homeScore,
                awayScore: awayScore
            )
            isLoading = false
            return match
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            return nil
        }
    }
}
