import Foundation

struct Standing: Codable, Identifiable {
    var id: String { teamId }
    let teamId: String
    let teamName: String
    let played: Int
    let won: Int
    let drawn: Int
    let lost: Int
    let gamesWon: Int
    let gamesLost: Int
    let points: Int
    let form: [String]?

    var gameDifference: Int { gamesWon - gamesLost }
}
