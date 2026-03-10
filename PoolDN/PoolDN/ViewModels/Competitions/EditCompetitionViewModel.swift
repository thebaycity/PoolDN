import Foundation

@Observable
class EditCompetitionViewModel {
    var name = ""
    var description = ""
    var gameType = ""
    var startDate = Date()
    var prize = ""
    var city = ""
    var country = ""
    var teamSizeMin = 2
    var teamSizeMax = 5

    // Game structure
    var gameStructure: [GameDefinition] = []

    // Schedule config
    var venueType = "central"
    var centralVenue = ""
    var gamesPerOpponent = 1
    var schedulingType = "weekly_rounds"
    var selectedWeekdays: Set<Int> = []

    var isLoading = false
    var errorMessage: String?
    var successMessage: String?

    private var competitionId = ""
    private var competitionStatus: CompetitionStatus = .draft

    /// True when editing an upcoming competition — team size fields are locked
    var isUpcoming: Bool { competitionStatus == .upcoming }

    // MARK: - Populate from existing competition

    func load(from competition: Competition) {
        competitionId = competition.id
        competitionStatus = competition.status
        name = competition.name
        description = competition.description ?? ""
        gameType = competition.gameType ?? ""
        if let ds = competition.startDate, let date = DateFormatter.isoDate.date(from: ds) {
            startDate = date
        } else {
            startDate = Date().addingTimeInterval(86400)
        }
        prize = competition.prize.map { $0 > 0 ? String(Int($0)) : "" } ?? ""
        city = competition.city ?? ""
        country = competition.country ?? ""
        teamSizeMin = competition.teamSizeMin ?? 2
        teamSizeMax = competition.teamSizeMax ?? 5
        gameStructure = competition.gameStructure ?? []
        if let sc = competition.scheduleConfig {
            venueType = sc.venueType
            centralVenue = sc.centralVenue ?? ""
            gamesPerOpponent = sc.gamesPerOpponent ?? 1
            schedulingType = sc.schedulingType
            selectedWeekdays = Set(sc.weekdays ?? [])
        }
    }

    // MARK: - Game structure helpers

    func addGame(label: String) {
        let order = gameStructure.count + 1
        gameStructure.append(GameDefinition(order: order, label: label, type: "game"))
    }

    func addBreak(label: String) {
        let order = gameStructure.count + 1
        gameStructure.append(GameDefinition(order: order, label: label, type: "break"))
    }

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

    var teamSizeError: String? {
        teamSizeMax < teamSizeMin ? "Max team size must be ≥ min" : nil
    }

    var isValid: Bool {
        nameError == nil && gameTypeError == nil && (isUpcoming || teamSizeError == nil)
    }

    // MARK: - Save

    func save() async -> Competition? {
        guard isValid else {
            errorMessage = [nameError, gameTypeError, teamSizeError].compactMap { $0 }.first
            return nil
        }

        isLoading = true
        errorMessage = nil
        do {
            var data = UpdateCompetitionData(
                name: name.trimmingCharacters(in: .whitespaces),
                description: description.trimmingCharacters(in: .whitespaces).isEmpty ? nil : description,
                gameType: gameType.trimmingCharacters(in: .whitespaces).isEmpty ? nil : gameType,
                startDate: startDate.dateOnlyString,
                prize: Double(prize),
                city: city.isEmpty ? nil : city,
                country: country.isEmpty ? nil : country
            )
            if !isUpcoming {
                data.teamSizeMin = teamSizeMin
                data.teamSizeMax = teamSizeMax
                data.gameStructure = gameStructure
                data.scheduleConfig = ScheduleConfig(
                    venueType: venueType,
                    centralVenue: venueType == "central" ? (centralVenue.isEmpty ? nil : centralVenue) : nil,
                    gamesPerOpponent: gamesPerOpponent,
                    schedulingType: schedulingType,
                    weekdays: schedulingType == "weekly_rounds" ? Array(selectedWeekdays).sorted() : nil,
                    fixedDates: nil
                )
            }
            let updated = try await CompetitionService.updateCompetition(competitionId, data: data)
            isLoading = false
            successMessage = "Competition updated!"
            return updated
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            return nil
        }
    }
}

private extension DateFormatter {
    static let isoDate: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
}

