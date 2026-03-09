import Foundation

@Observable
class TeamListViewModel {
    // Data
    var myTeams: [Team] = []
    var allTeams: [Team] = []

    // Search
    var searchQuery = ""
    var searchResults: [Team] = []
    var isSearching = false

    // Pagination
    var isLoading = false
    var isLoadingMore = false
    var hasMore = false
    var errorMessage: String?

    private var offset = 0
    private let pageSize = 20
    private var searchTask: Task<Void, Never>?

    func onQueryChanged(_ query: String) {
        searchQuery = query
        searchTask?.cancel()

        guard query.trimmingCharacters(in: CharacterSet.whitespaces).count >= 2 else {
            searchResults = []
            isSearching = false
            return
        }
        isSearching = true
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 280_000_000)
            guard !Task.isCancelled else { return }
            await performSearch(query: query)
        }
    }

    private func performSearch(query: String) async {
        do {
            let results = try await TeamService.searchTeams(query: query)
            guard !Task.isCancelled else { return }
            searchResults = results
            isSearching = false
        } catch {
            guard !Task.isCancelled else { return }
            isSearching = false
        }
    }

    func load(playerId: String) async {
        isLoading = true
        errorMessage = nil
        offset = 0
        do {
            async let fetchMy = TeamService.getPlayerTeams(playerId: playerId)
            async let fetchAll = TeamService.listTeams(limit: pageSize, offset: 0)
            let (my, allResponse) = try await (fetchMy, fetchAll)
            myTeams = my
            allTeams = allResponse.data
            hasMore = allResponse.hasMore
            offset = allResponse.data.count
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }

    func loadMore() async {
        guard !isLoadingMore && hasMore else { return }
        isLoadingMore = true
        do {
            let response = try await TeamService.listTeams(limit: pageSize, offset: offset)
            allTeams.append(contentsOf: response.data)
            hasMore = response.hasMore
            offset += response.data.count
            isLoadingMore = false
        } catch {
            isLoadingMore = false
        }
    }

    func clearSearch() {
        searchTask?.cancel()
        searchQuery = ""
        searchResults = []
        isSearching = false
    }
}
