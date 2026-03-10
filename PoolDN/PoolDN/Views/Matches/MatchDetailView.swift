import SwiftUI

struct MatchDetailView: View {
    let match: Match
    @Bindable var appState: AppState
    var gameStructure: [GameDefinition]? = nil
    var participations: [TeamParticipation] = []
    @State private var showSubmitSheet = false

    private var userId: String? { appState.currentUser?.id }
    private var isOrganizer: Bool { appState.currentUser?.role == "organizer" || appState.currentUser?.role == "admin" }

    private var hasHomeSubmission: Bool { match.homeSubmission != nil }
    private var hasAwaySubmission: Bool { match.awaySubmission != nil }
    private var showSubmissions: Bool {
        hasHomeSubmission || hasAwaySubmission || match.status == .pendingReview
    }

    private var submitButtonTitle: String {
        if isOrganizer && match.status == .pendingReview {
            return "Confirm Result"
        }
        // Captain who already submitted
        if hasHomeSubmission || hasAwaySubmission {
            return "Update Score"
        }
        return "Submit Result"
    }

    private var homeRoster: [RosterPlayer] {
        participations.first(where: { $0.teamId == match.homeTeamId })?.roster ?? []
    }

    private var awayRoster: [RosterPlayer] {
        participations.first(where: { $0.teamId == match.awayTeamId })?.roster ?? []
    }

    private var canSubmit: Bool {
        match.status != .completed
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Score Card
                VStack(spacing: 16) {
                    StatusBadge.forMatch(match.status)

                    HStack(spacing: 0) {
                        VStack(spacing: 6) {
                            ZStack {
                                Circle()
                                    .fill(Color.theme.accent.opacity(0.15))
                                    .frame(width: 48, height: 48)
                                Text(String(match.homeTeamName.prefix(2)).uppercased())
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color.theme.accent)
                            }
                            Text(match.homeTeamName)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(Color.theme.textPrimary)
                                .lineLimit(1)
                            Text("Home")
                                .font(.caption2)
                                .foregroundColor(Color.theme.textTertiary)
                        }
                        .frame(maxWidth: .infinity)

                        VStack(spacing: 4) {
                            Text("\(match.homeScore) – \(match.awayScore)")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(Color.theme.textPrimary)
                            if match.status != .completed {
                                Text("Not final")
                                    .font(.caption2)
                                    .foregroundColor(Color.theme.textTertiary)
                            }
                        }

                        VStack(spacing: 6) {
                            ZStack {
                                Circle()
                                    .fill(Color.theme.accentOrange.opacity(0.15))
                                    .frame(width: 48, height: 48)
                                Text(String(match.awayTeamName.prefix(2)).uppercased())
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color.theme.accentOrange)
                            }
                            Text(match.awayTeamName)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(Color.theme.textPrimary)
                                .lineLimit(1)
                            Text("Away")
                                .font(.caption2)
                                .foregroundColor(Color.theme.textTertiary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .cardStyle()

                // Submissions Card
                if showSubmissions {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Submissions")
                            .font(.headline)
                            .foregroundColor(Color.theme.textPrimary)

                        Divider().overlay(Color.theme.separator)

                        submissionRow(
                            label: "Home",
                            teamName: match.homeTeamName,
                            submission: match.homeSubmission,
                            isDisputed: match.status == .pendingReview && hasHomeSubmission && hasAwaySubmission
                        )

                        submissionRow(
                            label: "Away",
                            teamName: match.awayTeamName,
                            submission: match.awaySubmission,
                            isDisputed: match.status == .pendingReview && hasHomeSubmission && hasAwaySubmission
                        )
                    }
                    .cardStyle()
                }

                // Match Info
                VStack(alignment: .leading, spacing: 14) {
                    Text("Match Info")
                        .font(.headline)
                        .foregroundColor(Color.theme.textPrimary)

                    Divider().overlay(Color.theme.separator)

                    if let date = match.scheduledDate {
                        infoRow(icon: "calendar", label: "Date", value: date.displayDate)
                    }
                    infoRow(icon: "number", label: "Round", value: "\(match.round)")
                    infoRow(icon: "list.number", label: "Matchday", value: "\(match.matchday)")
                    if let venue = match.venue {
                        infoRow(icon: "mappin.and.ellipse", label: "Venue", value: venue)
                    }
                }
                .cardStyle()

                // Individual Games
                if let games = match.games, !games.isEmpty {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Games")
                            .font(.headline)
                            .foregroundColor(Color.theme.textPrimary)

                        Divider().overlay(Color.theme.separator)

                        ForEach(games, id: \.gameOrder) { game in
                            HStack {
                                Text(game.homePlayerName ?? "TBD")
                                    .font(.subheadline)
                                    .foregroundColor(Color.theme.textPrimary)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                                    .lineLimit(1)

                                Text("\(game.homeScore) – \(game.awayScore)")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color.theme.textPrimary)
                                    .frame(width: 56, alignment: .center)
                                    .padding(.vertical, 4)
                                    .background(Color.theme.surfaceLight)
                                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

                                Text(game.awayPlayerName ?? "TBD")
                                    .font(.subheadline)
                                    .foregroundColor(Color.theme.textPrimary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .lineLimit(1)
                            }
                        }
                    }
                    .cardStyle()
                }

                // Submit button
                if canSubmit {
                    Button {
                        showSubmitSheet = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                            Text(submitButtonTitle)
                        }
                        .primaryButton()
                    }
                }
            }
            .padding()
        }
        .background(Color.theme.background)
        .navigationTitle("Match Details")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showSubmitSheet) {
            SubmitResultSheet(
                match: match,
                gameStructure: gameStructure,
                homeRoster: homeRoster,
                awayRoster: awayRoster
            )
        }
    }

    private func submissionRow(label: String, teamName: String, submission: ScoreSubmission?, isDisputed: Bool) -> some View {
        HStack(spacing: 12) {
            if let sub = submission {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(isDisputed ? Color.theme.accentYellow : Color.theme.accentGreen)
                    .font(.subheadline)

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(label) submitted: \(sub.homeScore)–\(sub.awayScore)")
                        .font(.subheadline)
                        .foregroundColor(Color.theme.textPrimary)
                }

                Spacer()
            } else {
                Image(systemName: "clock")
                    .foregroundColor(Color.theme.textTertiary)
                    .font(.subheadline)

                Text("Awaiting \(label.lowercased()) submission")
                    .font(.subheadline)
                    .foregroundColor(Color.theme.textSecondary)

                Spacer()
            }
        }
    }

    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(Color.theme.accent)
                .frame(width: 22)
            Text(label)
                .font(.subheadline)
                .foregroundColor(Color.theme.textSecondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(Color.theme.textPrimary)
        }
    }
}
