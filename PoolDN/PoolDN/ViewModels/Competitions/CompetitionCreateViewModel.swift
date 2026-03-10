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

    // MARK: - Validation

    var nameError: String? {
        let t = name.trimmingCharacters(in: .whitespaces)
        if t.isEmpty { return "Competition name is required" }
        if t.count < 3 { return "Name must be at least 3 characters" }
        return nil
    }

    var gameTypeError: String? {
        gameType.trimmingCharacters(in: .whitespaces).isEmpty ? "Game type is required" : nil
    }

    var startDateError: String? {
        // Must be strictly in the future (at least tomorrow)
        let tomorrow = Calendar.current.startOfDay(for: Date().addingTimeInterval(86400))
        let chosen = Calendar.current.startOfDay(for: startDate)
        return chosen < tomorrow ? "Start date must be a future date" : nil
    }

    var teamSizeError: String? {
        teamSizeMin < 1 ? "Minimum team size must be at least 1" :
        teamSizeMax < teamSizeMin ? "Max size must be ≥ min size" : nil
    }

    /// Errors per step so the UI can block Next
    func validationErrors(for step: Int) -> [String] {
        switch step {
        case 0: return [nameError, gameTypeError, startDateError].compactMap { $0 }
        case 1: return [teamSizeError].compactMap { $0 }
        default: return []
        }
    }

    var canProceedFromCurrentStep: Bool {
        validationErrors(for: currentStep).isEmpty
    }

    /// All required steps are valid — enables the final Publish button
    var isReadyToPublish: Bool {
        (0...1).allSatisfy { validationErrors(for: $0).isEmpty }
    }

    // MARK: - Create

    func createAndPublish() async -> Competition? {
        // Final validation
        let allErrors = (0...1).flatMap { validationErrors(for: $0) }
        guard allErrors.isEmpty else {
            errorMessage = allErrors.first
            return nil
        }

        isLoading = true
        errorMessage = nil
        do {
            let comp = try await CompetitionService.createCompetition(
                name: name.trimmingCharacters(in: .whitespaces),
                description: description.trimmingCharacters(in: .whitespaces).isEmpty ? nil : description,
                gameType: gameType.trimmingCharacters(in: .whitespaces).isEmpty ? nil : gameType,
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
