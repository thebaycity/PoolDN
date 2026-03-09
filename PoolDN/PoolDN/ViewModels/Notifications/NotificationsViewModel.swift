import Foundation

@Observable
class NotificationsViewModel {
    var notifications: [AppNotification] = []
    var pendingInvitations: [TeamInvitation] = []
    var competitionInvitations: [CompetitionInvitation] = []
    var isLoading = false
    var isLoadingMore = false
    var hasMore = false
    var errorMessage: String?

    private var offset = 0
    private let pageSize = 20

    var unreadCount: Int {
        notifications.filter { !$0.read }.count
    }

    func load() async {
        isLoading = true
        offset = 0
        do {
            async let notifs = NotificationService.getNotifications(limit: pageSize, offset: 0)
            async let invites = TeamService.getPendingInvitations()
            async let compInvites = CompetitionService.getCompetitionInvitations()
            let (notifsResult, invitesResult, compInvitesResult) = try await (notifs, invites, compInvites)
            notifications = notifsResult.data
            hasMore = notifsResult.hasMore
            offset = notifsResult.data.count
            pendingInvitations = invitesResult
            competitionInvitations = compInvitesResult
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
            let response = try await NotificationService.getNotifications(limit: pageSize, offset: offset)
            notifications.append(contentsOf: response.data)
            hasMore = response.hasMore
            offset += response.data.count
            isLoadingMore = false
        } catch {
            isLoadingMore = false
        }
    }

    func markRead(_ id: String) async {
        do {
            _ = try await NotificationService.markRead(id)
            if let index = notifications.firstIndex(where: { $0.id == id }) {
                await load()
                _ = index
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func respondToInvitation(_ id: String, accept: Bool) async {
        do {
            _ = try await TeamService.respondToInvitation(invitationId: id, accept: accept)
            pendingInvitations.removeAll { $0.id == id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func respondToCompetitionInvitation(competitionId: String, teamId: String, accept: Bool) async {
        do {
            _ = try await CompetitionService.respondToInvitation(competitionId: competitionId, teamId: teamId, accept: accept)
            competitionInvitations.removeAll { $0.competitionId == competitionId && $0.teamId == teamId }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
