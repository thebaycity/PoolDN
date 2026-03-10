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

    // Change password fields
    var currentPassword = ""
    var newPassword = ""
    var confirmPassword = ""
    var isChangingPassword = false
    var passwordErrorMessage: String?

    /// Incremented after every successful avatar upload to bust AsyncImage cache
    var avatarVersion: Int = 0

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
            avatarVersion += 1
            isUploading = false
            return true
        } catch {
            isUploading = false
            errorMessage = error.localizedDescription
            return false
        }
    }

    func changePassword() async -> Bool {
        guard newPassword == confirmPassword else {
            passwordErrorMessage = "New passwords do not match"
            return false
        }
        guard newPassword.count >= 6 else {
            passwordErrorMessage = "New password must be at least 6 characters"
            return false
        }
        isChangingPassword = true
        passwordErrorMessage = nil
        do {
            try await AuthService.changePassword(
                currentPassword: currentPassword,
                newPassword: newPassword
            )
            // Clear fields on success
            currentPassword = ""
            newPassword = ""
            confirmPassword = ""
            isChangingPassword = false
            return true
        } catch {
            isChangingPassword = false
            passwordErrorMessage = error.localizedDescription
            return false
        }
    }

    func resetPasswordFields() {
        currentPassword = ""
        newPassword = ""
        confirmPassword = ""
        passwordErrorMessage = nil
    }
}
