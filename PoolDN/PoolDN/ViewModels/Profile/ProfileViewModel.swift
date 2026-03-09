import Foundation

@Observable
class ProfileViewModel {
    var user: User?
    var stats: UserStats?
    var myTeams: [Team] = []
    var isLoading = false
    var isUploading = false
    var errorMessage: String?

    // Edit fields
    var editName = ""
    var editNickname = ""

    func load(_ userId: String) async {
        isLoading = true
        do {
            async let fetchUser = AuthService.getMe()
            async let fetchStats = UserService.getUserStats(userId)
            async let fetchTeams = UserService.getUserTeams(userId)

            let (u, s, t) = try await (fetchUser, fetchStats, fetchTeams)
            user = u
            stats = s
            myTeams = t
            editName = u.name
            editNickname = u.nickname ?? ""
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }

    func save() async -> Bool {
        guard let userId = user?.id else { return false }
        isLoading = true
        do {
            struct Body: Encodable {
                let name: String?
                let nickname: String?
            }
            let body = Body(
                name: editName.isEmpty ? nil : editName,
                nickname: editNickname.isEmpty ? nil : editNickname
            )
            user = try await APIClient.shared.put("/users/\(userId)", body: body)
            isLoading = false
            return true
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            return false
        }
    }

    func uploadAvatar(_ imageData: Data) async -> Bool {
        guard let userId = user?.id else { return false }
        isUploading = true
        do {
            user = try await UserService.uploadAvatar(userId: userId, imageData: imageData)
            isUploading = false
            return true
        } catch {
            isUploading = false
            errorMessage = error.localizedDescription
            return false
        }
    }
}
