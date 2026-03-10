import Foundation

@Observable
class PlayerDirectoryViewModel {
    var results: [User] = []
    var query = ""
    var selectedRole: String? = nil   // nil = all, "player", "organizer"
    var isSearching = false
    var errorMessage: String?
    private(set) var isBrowsing = false  // true = show all users (no filter required)

    private var searchTask: Task<Void, Never>?

    // MARK: - Reactive triggers

    func onQueryChanged(_ newQuery: String) {
        query = newQuery
        scheduleSearch()
    }

    func onRoleChanged(_ role: String?) {
        selectedRole = role
        scheduleSearch()
    }

    // MARK: - Search scheduling

    private func scheduleSearch() {
        searchTask?.cancel()
        let q = query.trimmingCharacters(in: .whitespaces)
        // Need either a query of ≥2 chars, a role filter, or browse mode to fetch
        guard q.count >= 2 || selectedRole != nil || isBrowsing else {
            results = []
            isSearching = false
            return
        }
        isSearching = true
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 280_000_000) // 280ms debounce
            guard !Task.isCancelled else { return }
            await fetch(query: q, role: selectedRole)
        }
    }

    /// Browse all users — no query or role filter required
    func browse() {
        isBrowsing = true
        scheduleSearch()
    }

    private func fetch(query: String, role: String?) async {
        do {
            let users = try await UserService.searchUsers(query: query, role: role)
            guard !Task.isCancelled else { return }
            results = users
            isSearching = false
        } catch {
            guard !Task.isCancelled else { return }
            isSearching = false
            errorMessage = error.localizedDescription
        }
    }

    func clear() {
        searchTask?.cancel()
        query = ""
        selectedRole = nil
        results = []
        isSearching = false
        errorMessage = nil
    }
}
