import Foundation

enum CompetitionStatus: String, Codable {
    case draft
    case upcoming
    case active
    case completed
}

struct GameDefinition: Codable {
    let order: Int
    let label: String
    let type: String // "game" or "break"
}

struct ScheduleConfig: Codable {
    let venueType: String // "central" or "team_venues"
    let centralVenue: String?
    let gamesPerOpponent: Int?
    let schedulingType: String // "weekly_rounds" or "fixed_matchdays"
    let weekdays: [Int]?
    let fixedDates: [String]?
}

struct Competition: Codable, Identifiable {
    let id: String
    let name: String
    let organizerId: String
    let description: String?
    let gameType: String?
    let format: String?
    let tournamentType: String?
    let startDate: String?
    let prize: Double?
    let city: String?
    let country: String?
    let status: CompetitionStatus
    let teamSizeMin: Int?
    let teamSizeMax: Int?
    let gameStructure: [GameDefinition]?
    let scheduleConfig: ScheduleConfig?
    let createdAt: Int
    let updatedAt: Int
}
