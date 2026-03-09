import Foundation

@Observable
class CompetitionListViewModel {
    var competitions: [Competition] = []
    var isLoading = false
    var isLoadingMore = false
    var hasMore = false
    var errorMessage: String?

    var publicCompetitions: [Competition] {
        competitions.filter { $0.status != .draft }
    }

    var myCompetitions: [Competition] = []

    private var offset = 0
    private let pageSize = 20

    func load(myPlayerId: String?) async {
        isLoading = true
        errorMessage = nil
        offset = 0
        do {
            let response = try await CompetitionService.listCompetitions(limit: pageSize, offset: 0)
            competitions = response.data
            hasMore = response.hasMore
            offset = response.data.count
            if let pid = myPlayerId {
                myCompetitions = competitions.filter { $0.organizerId == pid }
            }
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }

    func loadMore(myPlayerId: String?) async {
        guard !isLoadingMore && hasMore else { return }
        isLoadingMore = true
        do {
            let response = try await CompetitionService.listCompetitions(limit: pageSize, offset: offset)
            competitions.append(contentsOf: response.data)
            hasMore = response.hasMore
            offset += response.data.count
            if let pid = myPlayerId {
                myCompetitions = competitions.filter { $0.organizerId == pid }
            }
            isLoadingMore = false
        } catch {
            isLoadingMore = false
        }
    }
}
