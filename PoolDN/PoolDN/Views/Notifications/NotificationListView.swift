import SwiftUI

struct NotificationListView: View {
    @Bindable var appState: AppState
    @State private var viewModel = NotificationsViewModel()
    @State private var selectedMatchId: String?
    @State private var loadedMatch: Match?
    @State private var showMatchDetail = false
    @State private var selectedNotification: AppNotification?
    @State private var selectedTeamInvitation: TeamInvitation?

    var body: some View {
        ScrollView {
            if viewModel.pendingInvitations.isEmpty && viewModel.competitionInvitations.isEmpty && viewModel.notifications.isEmpty && !viewModel.isLoading {
                EmptyStateView(
                    icon: "bell.slash",
                    title: "No Notifications",
                    message: "You're all caught up!"
                )
            } else {
                VStack(spacing: 16) {
                    // Team invitations
                    if !viewModel.pendingInvitations.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Team Invitations")
                                .sectionHeader()
                                .padding(.horizontal, 4)

                            VStack(spacing: 2) {
                                ForEach(viewModel.pendingInvitations) { invitation in
                                    Button {
                                        selectedTeamInvitation = invitation
                                    } label: {
                                        HStack(spacing: 12) {
                                            ZStack {
                                                Circle()
                                                    .fill(Color.theme.accent.opacity(0.15))
                                                    .frame(width: 36, height: 36)
                                                Image(systemName: "person.badge.plus")
                                                    .font(.caption)
                                                    .foregroundColor(Color.theme.accent)
                                            }

                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(invitation.teamName)
                                                    .font(.subheadline.weight(.semibold))
                                                    .foregroundColor(Color.theme.textPrimary)
                                                Text("You've been invited to join this team")
                                                    .font(.caption)
                                                    .foregroundColor(Color.theme.textSecondary)
                                            }

                                            Spacer()

                                            Image(systemName: "chevron.right")
                                                .font(.caption)
                                                .foregroundColor(Color.theme.textTertiary)
                                        }
                                        .padding(14)
                                        .background(Color.theme.surface)
                                    }
                                }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .strokeBorder(Color.theme.border, lineWidth: 0.5)
                            )
                        }
                    }

                    // Competition invitations
                    if !viewModel.competitionInvitations.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Competition Invitations")
                                .sectionHeader()
                                .padding(.horizontal, 4)

                            VStack(spacing: 2) {
                                ForEach(viewModel.competitionInvitations) { invitation in
                                    HStack(spacing: 12) {
                                        ZStack {
                                            Circle()
                                                .fill(Color.theme.accentYellow.opacity(0.15))
                                                .frame(width: 36, height: 36)
                                            Image(systemName: "trophy")
                                                .font(.caption)
                                                .foregroundColor(Color.theme.accentYellow)
                                        }

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(invitation.competitionName)
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundColor(Color.theme.textPrimary)
                                            Text("Team: \(invitation.teamName)")
                                                .font(.caption)
                                                .foregroundColor(Color.theme.textSecondary)
                                        }

                                        Spacer()

                                        HStack(spacing: 8) {
                                            Button {
                                                Task { await viewModel.respondToCompetitionInvitation(competitionId: invitation.competitionId, teamId: invitation.teamId, accept: false) }
                                            } label: {
                                                Text("Decline")
                                                    .font(.caption.weight(.medium))
                                                    .foregroundColor(Color.theme.accentRed)
                                                    .padding(.horizontal, 12)
                                                    .padding(.vertical, 6)
                                                    .background(Color.theme.accentRed.opacity(0.12))
                                                    .clipShape(Capsule())
                                            }

                                            Button {
                                                Task { await viewModel.respondToCompetitionInvitation(competitionId: invitation.competitionId, teamId: invitation.teamId, accept: true) }
                                            } label: {
                                                Text("Accept")
                                                    .font(.caption.weight(.medium))
                                                    .foregroundColor(.white)
                                                    .padding(.horizontal, 12)
                                                    .padding(.vertical, 6)
                                                    .background(Color.theme.accentGreen)
                                                    .clipShape(Capsule())
                                            }
                                        }
                                    }
                                    .padding(14)
                                    .background(Color.theme.surface)
                                }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .strokeBorder(Color.theme.border, lineWidth: 0.5)
                            )
                        }
                    }

                    if !viewModel.notifications.isEmpty {
                        LazyVStack(spacing: 2) {
                            ForEach(viewModel.notifications) { notification in
                                notificationRow(notification)
                                    .onAppear {
                                        if notification.id == viewModel.notifications.last?.id {
                                            Task { await viewModel.loadMore() }
                                        }
                                    }
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(Color.theme.border, lineWidth: 0.5)
                        )

                        if viewModel.isLoadingMore {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                    }
                }
                .padding()
            }
        }
        .background(Color.theme.background)
        .navigationTitle("Notifications")
        .navigationDestination(for: String.self) { id in
            CompetitionDetailView(competitionId: id, appState: appState)
        }
        .sheet(isPresented: $showMatchDetail) {
            if let match = loadedMatch {
                NavigationStack {
                    MatchDetailView(match: match, appState: appState)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Close") { showMatchDetail = false }
                            }
                        }
                }
            }
        }
        .sheet(item: $selectedNotification) { notification in
            NotificationDetailView(notification: notification) {
                selectedNotification = nil
                Task { await viewModel.load() }
            }
        }
        .sheet(item: $selectedTeamInvitation) { invitation in
            TeamInvitationDetailView(invitation: invitation) {
                selectedTeamInvitation = nil
                Task { await viewModel.load() }
            } onRespond: { id, accept in
                await viewModel.respondToInvitation(id, accept: accept)
            }
        }
        .overlay {
            if viewModel.isLoading && viewModel.notifications.isEmpty && viewModel.pendingInvitations.isEmpty {
                LoadingView()
            }
        }
        .refreshable {
            await viewModel.load()
        }
        .task {
            await viewModel.load()
        }
    }

    @ViewBuilder
    private func notificationRow(_ notification: AppNotification) -> some View {
        if notification.isActionable {
            Button {
                markReadIfNeeded(notification)
                selectedNotification = notification
            } label: {
                notificationContent(notification)
            }
        } else if notification.referenceType == "competition", let refId = notification.referenceId {
            NavigationLink(value: refId) {
                notificationContent(notification)
            }
            .simultaneousGesture(TapGesture().onEnded {
                markReadIfNeeded(notification)
            })
        } else if notification.referenceType == "match", let refId = notification.referenceId {
            Button {
                markReadIfNeeded(notification)
                Task {
                    do {
                        loadedMatch = try await MatchService.getMatch(refId)
                        showMatchDetail = true
                    } catch {}
                }
            } label: {
                notificationContent(notification)
            }
        } else {
            Button {
                markReadIfNeeded(notification)
            } label: {
                notificationContent(notification)
            }
        }
    }

    private func notificationContent(_ notification: AppNotification) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(notification.read ? Color.theme.surfaceLight : iconColor(notification.type).opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: iconForType(notification.type))
                    .font(.caption)
                    .foregroundColor(notification.read ? Color.theme.textTertiary : iconColor(notification.type))
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(notification.title)
                        .font(.subheadline)
                        .fontWeight(notification.read ? .regular : .semibold)
                        .foregroundColor(Color.theme.textPrimary)
                        .lineLimit(1)
                    Spacer()
                    if !notification.read {
                        Circle()
                            .fill(Color.theme.accent)
                            .frame(width: 8, height: 8)
                    }
                }

                Text(notification.message)
                    .font(.caption)
                    .foregroundColor(Color.theme.textSecondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Text(notification.createdAt.displayDate)
                    .font(.caption2)
                    .foregroundColor(Color.theme.textTertiary)
            }
        }
        .padding(14)
        .background(notification.read ? Color.theme.surface : Color.theme.surface.opacity(0.8))
    }

    private func markReadIfNeeded(_ notification: AppNotification) {
        if !notification.read {
            Task { await viewModel.markRead(notification.id) }
        }
    }

    private func iconForType(_ type: String) -> String {
        switch type {
        case "team_invitation": return "person.badge.plus"
        case "competition_update": return "trophy"
        case "competition_invitation": return "envelope.badge"
        case "match_result": return "sportscourt"
        case "match_scheduled": return "calendar"
        case "application_accepted": return "checkmark.circle"
        case "score_submitted": return "arrow.up.doc"
        case "score_disputed": return "exclamationmark.triangle"
        case "score_confirmed": return "checkmark.seal"
        default: return "bell.fill"
        }
    }

    private func iconColor(_ type: String) -> Color {
        switch type {
        case "score_submitted": return Color.theme.accentYellow
        case "score_disputed": return Color.theme.accentOrange
        case "score_confirmed": return Color.theme.accentGreen
        case "competition_invitation": return Color.theme.accent
        default: return Color.theme.accent
        }
    }
}
