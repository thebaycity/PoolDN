import Foundation

enum GameWinner: Equatable {
    case none
    case home
    case away
}

@Observable
class GameEntry: Identifiable {
    let id = UUID()
    let gameDefinition: GameDefinition
    var homePlayerIds: [String] = []
    var homePlayerNames: [String] = []
    var awayPlayerIds: [String] = []
    var awayPlayerNames: [String] = []
    var winner: GameWinner = .none

    var isDoubles: Bool {
        gameDefinition.label.localizedCaseInsensitiveContains("doubles")
    }

    var requiredPlayerCount: Int { isDoubles ? 2 : 1 }

    var isComplete: Bool {
        winner != .none
            && homePlayerIds.count == requiredPlayerCount
            && awayPlayerIds.count == requiredPlayerCount
    }

    init(gameDefinition: GameDefinition) {
        self.gameDefinition = gameDefinition
    }
}

@Observable
class SubmitResultViewModel {
    // Simple mode
    var homeScore = 0
    var awayScore = 0

    // Game-by-game mode
    var gameEntries: [GameEntry] = []
    var useGameMode = false

    var isLoading = false
    var errorMessage: String?

    var calculatedHomeScore: Int {
        gameEntries.filter { $0.winner == .home }.count
    }

    var calculatedAwayScore: Int {
        gameEntries.filter { $0.winner == .away }.count
    }

    var allGamesComplete: Bool {
        !gameEntries.isEmpty && gameEntries.allSatisfy(\.isComplete)
    }

    func setupGames(from structure: [GameDefinition]) {
        let games = structure.filter { $0.type == "game" }
        guard !games.isEmpty else { return }
        useGameMode = true
        gameEntries = games.map { GameEntry(gameDefinition: $0) }
    }

    func buildGameResults() -> [GameResult]? {
        guard useGameMode, !gameEntries.isEmpty else { return nil }
        return gameEntries.map { entry in
            let homeId = entry.homePlayerIds.joined(separator: " & ")
            let awayId = entry.awayPlayerIds.joined(separator: " & ")
            let homeName = entry.homePlayerNames.joined(separator: " & ")
            let awayName = entry.awayPlayerNames.joined(separator: " & ")
            return GameResult(
                gameOrder: entry.gameDefinition.order,
                homePlayerName: homeName.isEmpty ? nil : homeName,
                awayPlayerName: awayName.isEmpty ? nil : awayName,
                homePlayerId: homeId.isEmpty ? nil : homeId,
                awayPlayerId: awayId.isEmpty ? nil : awayId,
                homeScore: entry.winner == .home ? 1 : 0,
                awayScore: entry.winner == .away ? 1 : 0
            )
        }
    }

    func submit(matchId: String) async -> Match? {
        isLoading = true
        errorMessage = nil
        do {
            let finalHomeScore = useGameMode ? calculatedHomeScore : homeScore
            let finalAwayScore = useGameMode ? calculatedAwayScore : awayScore
            let games = buildGameResults()
            let match = try await MatchService.submitResult(
                matchId: matchId,
                homeScore: finalHomeScore,
                awayScore: finalAwayScore,
                games: games
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
