import Foundation

@Observable
class CreateTeamViewModel {
    var name = ""
    var city = ""
    var country = ""
    var homeVenue = ""
    var isLoading = false
    var errorMessage: String?

    // MARK: - Validation

    var nameError: String? {
        let t = name.trimmingCharacters(in: .whitespaces)
        if t.isEmpty { return nil }          // no error while still empty (don't nag on open)
        if t.count < 2 { return "Name must be at least 2 characters" }
        if t.count > 50 { return "Name must be 50 characters or less" }
        return nil
    }

    /// True only when all required fields are filled and valid
    var isValid: Bool {
        let t = name.trimmingCharacters(in: .whitespaces)
        return t.count >= 2 && t.count <= 50
    }

    // MARK: - Create

    func create() async -> Team? {
        let t = name.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else {
            errorMessage = "Team name is required"
            return nil
        }
        isLoading = true
        errorMessage = nil
        do {
            let team = try await TeamService.createTeam(
                name: t,
                city: city.isEmpty ? nil : city,
                homeVenue: homeVenue.isEmpty ? nil : homeVenue
            )
            isLoading = false
            return team
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            return nil
        }
    }
}
