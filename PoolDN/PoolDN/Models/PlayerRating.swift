import Foundation

struct PlayerRating: Codable, Identifiable {
    var id: String { playerId }
    let playerId: String
    let playerName: String
    let teamId: String
    let teamName: String
    let gamesPlayed: Int
    let singlesWon: Int
    let singlesLost: Int
    let doublesWon: Int
    let doublesLost: Int
    let pointsEarned: Int
    let pointsAvailable: Int
    let rating: Double
}
