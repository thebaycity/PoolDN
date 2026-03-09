import Foundation

@Observable
class TeamListViewModel {
    var myTeams: [Team] = []
    var allTeams: [Team] = []
    var isLoading = false
    var isLoadingMore = false
    var hasMore = false
    var errorMessage: String?

    private var offset = 0
    private let pageSize = 20

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
}
