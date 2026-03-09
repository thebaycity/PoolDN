import Foundation

@Observable
class CompetitionCreateViewModel {
    // Step 1: Basic Info
    var name = ""
    var description = ""
    var gameType = ""
    var startDate = Date()
    var prize = ""
    var city = ""
    var country = ""

    // Step 2: Participants
    var teamSizeMin = 2
    var teamSizeMax = 5

    // Step 3: Structure
    var gameStructure: [GameDefinition] = []

    // Step 4: Schedule
    var venueType = "central"
    var centralVenue = ""
    var gamesPerOpponent = 1
    var schedulingType = "weekly_rounds"
    var selectedWeekdays: Set<Int> = []

    var currentStep = 0
    var isLoading = false
    var errorMessage: String?
    var createdCompetition: Competition?

    func createAndPublish() async -> Competition? {
        isLoading = true
        errorMessage = nil
        do {
            let comp = try await CompetitionService.createCompetition(
                name: name,
                description: description.isEmpty ? nil : description,
                gameType: gameType.isEmpty ? nil : gameType,
                startDate: startDate.dateOnlyString,
                prize: Double(prize),
                city: city.isEmpty ? nil : city,
                country: country.isEmpty ? nil : country
            )

            let scheduleConfig = ScheduleConfig(
                venueType: venueType,
                centralVenue: venueType == "central" ? (centralVenue.isEmpty ? nil : centralVenue) : nil,
                gamesPerOpponent: gamesPerOpponent,
                schedulingType: schedulingType,
                weekdays: schedulingType == "weekly_rounds" ? Array(selectedWeekdays) : nil,
                fixedDates: nil
            )

            _ = try await CompetitionService.updateCompetition(comp.id, data: UpdateCompetitionData(
                teamSizeMin: teamSizeMin,
                teamSizeMax: teamSizeMax,
                gameStructure: gameStructure.isEmpty ? nil : gameStructure,
                scheduleConfig: scheduleConfig
            ))

            let published = try await CompetitionService.publish(comp.id)
            createdCompetition = published
            isLoading = false
            return published
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            return nil
        }
    }

    func addGame(label: String) {
        let order = gameStructure.count + 1
        gameStructure.append(GameDefinition(order: order, label: label, type: "game"))
    }

    func addBreak(label: String) {
        let order = gameStructure.count + 1
        gameStructure.append(GameDefinition(order: order, label: label, type: "break"))
    }
}
