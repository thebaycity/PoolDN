import Foundation

@Observable
class UserProfileViewModel {
    var user: User?
    var stats: UserStats?
    var teams: [Team] = []
    var isLoading = false
    var errorMessage: String?

    func load(_ userId: String) async {
        isLoading = true
        do {
            async let fetchUser = UserService.getUser(userId)
            async let fetchStats = UserService.getUserStats(userId)
            async let fetchTeams = UserService.getUserTeams(userId)

            let (u, s, t) = try await (fetchUser, fetchStats, fetchTeams)
            user = u
            stats = s
            teams = t
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }
}
