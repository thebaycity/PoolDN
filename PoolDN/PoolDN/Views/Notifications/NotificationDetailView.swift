import SwiftUI

struct NotificationDetailView: View {
    let notification: AppNotification
    let onDismiss: () -> Void
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var isCompleted = false

    private var meta: NotificationMetadata? { notification.decodedMetadata }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Type icon
                    ZStack {
                        Circle()
                            .fill(iconColor.opacity(0.15))
                            .frame(width: 56, height: 56)
                        Image(systemName: iconName)
                            .font(.title3)
                            .foregroundColor(iconColor)
                    }
                    .padding(.top, 8)

                    // Title & message
                    VStack(spacing: 8) {
                        Text(notification.title)
                            .font(.title3.weight(.bold))
                            .foregroundColor(Color.theme.textPrimary)
                            .multilineTextAlignment(.center)

                        Text(notification.message)
                            .font(.subheadline)
                            .foregroundColor(Color.theme.textSecondary)
                            .multilineTextAlignment(.center)
                    }

                    // Contextual card
                    contextCard

                    if let error = errorMessage {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.caption)
                            Text(error)
                                .font(.caption)
                        }
                        .foregroundColor(Color.theme.accentRed)
                    }

                    // Action buttons
                    if !isCompleted {
                        actionButtons
                    } else {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Done")
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Color.theme.accentGreen)
                    }

                    // Timestamp
                    Text(notification.createdAt.displayDate)
                        .font(.caption2)
                        .foregroundColor(Color.theme.textTertiary)

                    Spacer()
                }
                .padding()
            }
            .background(Color.theme.background)
            .navigationTitle("Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { onDismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private var contextCard: some View {
        switch notification.type {
        case "competition_invitation":
            competitionInvitationCard
        case "score_submitted":
            scoreSubmittedCard
        case "score_disputed":
            scoreDisputedCard
        default:
            EmptyView()
        }
    }

    private var competitionInvitationCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.theme.accent.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: "trophy")
                        .font(.subheadline)
                        .foregroundColor(Color.theme.accent)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(meta?.competitionName ?? "Competition")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Color.theme.textPrimary)
                    Text("Team: \(meta?.teamName ?? "Unknown")")
                        .font(.caption)
                        .foregroundColor(Color.theme.textSecondary)
                }
                Spacer()
            }
        }
        .cardStyle()
    }

    private var scoreSubmittedCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 0) {
                Text(meta?.homeTeamName ?? "Home")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Color.theme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .lineLimit(1)

                Text("\(meta?.homeScore ?? 0) – \(meta?.awayScore ?? 0)")
                    .font(.title2.weight(.bold))
                    .foregroundColor(Color.theme.textPrimary)
                    .frame(width: 80, alignment: .center)

                Text(meta?.awayTeamName ?? "Away")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Color.theme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(1)
            }

            if let submitter = meta?.submitterName {
                Text("Submitted by \(submitter)")
                    .font(.caption)
                    .foregroundColor(Color.theme.textSecondary)
            }
        }
        .cardStyle()
    }

    private var scoreDisputedCard: some View {
        VStack(spacing: 12) {
            Text("\(meta?.homeTeamName ?? "Home") vs \(meta?.awayTeamName ?? "Away")")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(Color.theme.textPrimary)

            HStack(spacing: 12) {
                // Home captain's submission
                VStack(spacing: 6) {
                    Text("Home Captain")
                        .font(.caption2)
                        .foregroundColor(Color.theme.textTertiary)
                    Text("\(meta?.homeSubmission?.homeScore ?? 0) – \(meta?.homeSubmission?.awayScore ?? 0)")
                        .font(.title3.weight(.bold))
                        .foregroundColor(Color.theme.textPrimary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.theme.surfaceLight)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                // Away captain's submission
                VStack(spacing: 6) {
                    Text("Away Captain")
                        .font(.caption2)
                        .foregroundColor(Color.theme.textTertiary)
                    Text("\(meta?.awaySubmission?.homeScore ?? 0) – \(meta?.awaySubmission?.awayScore ?? 0)")
                        .font(.title3.weight(.bold))
                        .foregroundColor(Color.theme.textPrimary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.theme.surfaceLight)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
        .cardStyle()
    }

    @ViewBuilder
    private var actionButtons: some View {
        switch notification.type {
        case "competition_invitation":
            HStack(spacing: 12) {
                Button {
                    respondToInvitation(accept: false)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "xmark")
                        Text("Decline")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Color.theme.accentRed)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.theme.accentRed.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                Button {
                    respondToInvitation(accept: true)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark")
                        Text("Accept")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.theme.accentGreen)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
            .disabled(isLoading)

        case "score_submitted":
            Button {
                confirmScore()
            } label: {
                Group {
                    if isLoading {
                        ProgressView().tint(.white)
                    } else {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.seal.fill")
                            Text("Confirm Result")
                        }
                    }
                }
                .primaryButton()
            }
            .disabled(isLoading)

        case "score_disputed":
            Button {
                confirmScore()
            } label: {
                Group {
                    if isLoading {
                        ProgressView().tint(.white)
                    } else {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.seal.fill")
                            Text("Confirm Result")
                        }
                    }
                }
                .primaryButton()
            }
            .disabled(isLoading)

        default:
            EmptyView()
        }
    }

    private var iconName: String {
        switch notification.type {
        case "competition_invitation": return "envelope.badge"
        case "score_submitted": return "arrow.up.doc"
        case "score_disputed": return "exclamationmark.triangle"
        case "score_confirmed": return "checkmark.seal"
        default: return "bell.fill"
        }
    }

    private var iconColor: Color {
        switch notification.type {
        case "competition_invitation": return Color.theme.accent
        case "score_submitted": return Color.theme.accentYellow
        case "score_disputed": return Color.theme.accentOrange
        case "score_confirmed": return Color.theme.accentGreen
        default: return Color.theme.accent
        }
    }

    private func respondToInvitation(accept: Bool) {
        guard let competitionId = notification.referenceId,
              let teamId = meta?.teamId else { return }
        isLoading = true
        errorMessage = nil
        Task {
            do {
                _ = try await CompetitionService.respondToInvitation(competitionId: competitionId, teamId: teamId, accept: accept)
                isCompleted = true
                isLoading = false
                try? await Task.sleep(for: .seconds(1))
                onDismiss()
            } catch {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }

    private func confirmScore() {
        guard let matchId = meta?.matchId else { return }
        let homeScore = meta?.homeScore ?? meta?.homeSubmission?.homeScore ?? 0
        let awayScore = meta?.awayScore ?? meta?.awaySubmission?.awayScore ?? 0
        isLoading = true
        errorMessage = nil
        Task {
            do {
                _ = try await MatchService.confirmResult(matchId: matchId, homeScore: homeScore, awayScore: awayScore)
                isCompleted = true
                isLoading = false
                try? await Task.sleep(for: .seconds(1))
                onDismiss()
            } catch {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
}
