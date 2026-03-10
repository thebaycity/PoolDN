import SwiftUI

struct CompetitionMatchesTab: View {
    let competitionId: String
    let matches: [Match]
    let hasMore: Bool
    let isLoadingMore: Bool
    @Bindable var appState: AppState
    var gameStructure: [GameDefinition]? = nil
    var participations: [TeamParticipation] = []
    var onLoadMore: (() async -> Void)? = nil

    @State private var selectedSegment = 0

    // MARK: - Computed Properties

    private var upcomingMatches: [Match] {
        matches.filter { $0.status == .scheduled || $0.status == .inProgress }
    }

    private var reviewMatches: [Match] {
        matches.filter { $0.status == .pendingReview }
    }

    private var completedMatches: [Match] {
        matches.filter { $0.status == .completed }
    }

    private func groupedByRound(_ items: [Match]) -> [(round: Int, matches: [Match])] {
        let grouped = Dictionary(grouping: items) { $0.round }
        return grouped.keys.sorted().map { (round: $0, matches: grouped[$0]!) }
    }

    private func isDisputed(_ match: Match) -> Bool {
        guard let home = match.homeSubmission, let away = match.awaySubmission else {
            return false
        }
        return home.homeScore != away.homeScore || home.awayScore != away.awayScore
    }

    private func proposedScore(for match: Match) -> (home: Int, away: Int)? {
        guard let sub = match.homeSubmission ?? match.awaySubmission else { return nil }
        return (sub.homeScore, sub.awayScore)
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            if matches.isEmpty {
                EmptyStateView(
                    icon: "sportscourt",
                    title: "No Matches",
                    message: "Matches will appear once generated"
                )
            } else {
                LazyVStack(spacing: 16) {
                    // Segmented picker
                    Picker("Filter", selection: $selectedSegment) {
                        Text("Upcoming").tag(0)
                        Text("Results").tag(1)
                    }
                    .pickerStyle(.segmented)

                    if selectedSegment == 0 {
                        upcomingContent
                    } else {
                        resultsContent
                    }

                    paginationFooter
                }
                .padding()
            }
        }
    }

    // MARK: - Upcoming Segment

    @ViewBuilder
    private var upcomingContent: some View {
        let upcoming = upcomingMatches
        let reviews = reviewMatches

        if reviews.isEmpty && upcoming.isEmpty {
            EmptyStateView(
                icon: "calendar",
                title: "No Upcoming Matches",
                message: "All matches have been played"
            )
        } else {
            // Score Review section
            if !reviews.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 6) {
                        Text("Score Review")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(Color.theme.textPrimary)
                        Text("\(reviews.count)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(Color.theme.accentYellow)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.theme.accentYellow.opacity(0.15))
                            .clipShape(Capsule())
                        Spacer()
                    }
                    .padding(.horizontal, 4)

                    VStack(spacing: 10) {
                        ForEach(reviews) { match in
                            NavigationLink {
                                MatchDetailView(
                                    match: match,
                                    appState: appState,
                                    gameStructure: gameStructure,
                                    participations: participations
                                )
                            } label: {
                                scoreReviewCard(match)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            // Scheduled matches grouped by round
            if !upcoming.isEmpty {
                roundSections(for: upcoming)
            }
        }
    }

    // MARK: - Results Segment

    @ViewBuilder
    private var resultsContent: some View {
        let completed = completedMatches

        if completed.isEmpty {
            EmptyStateView(
                icon: "checkmark.circle",
                title: "No Results Yet",
                message: "Completed matches will appear here"
            )
        } else {
            roundSections(for: completed)
        }
    }

    // MARK: - Shared Helpers

    @ViewBuilder
    private func roundSections(for items: [Match]) -> some View {
        ForEach(groupedByRound(items), id: \.round) { roundData in
            roundSection(roundData)
        }
    }

    private func roundSection(_ roundData: (round: Int, matches: [Match])) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Round \(roundData.round)")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(Color.theme.textPrimary)
                Spacer()
                Text("\(roundData.matches.count) match\(roundData.matches.count == 1 ? "" : "es")")
                    .font(.caption)
                    .foregroundColor(Color.theme.textSecondary)
            }
            .padding(.horizontal, 4)

            VStack(spacing: 1) {
                ForEach(roundData.matches) { match in
                    NavigationLink {
                        MatchDetailView(
                            match: match,
                            appState: appState,
                            gameStructure: gameStructure,
                            participations: participations
                        )
                    } label: {
                        MatchRow(match: match)
                    }
                    .onAppear {
                        if match.id == matches.last?.id, hasMore {
                            Task { await onLoadMore?() }
                        }
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.theme.border, lineWidth: 0.5)
            )
        }
    }

    // MARK: - Score Review Card

    private func scoreReviewCard(_ match: Match) -> some View {
        let disputed = isDisputed(match)
        let score = proposedScore(for: match)

        return VStack(spacing: 0) {
            // Team names + proposed score
            HStack {
                Text(match.homeTeamName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.theme.textPrimary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                if let score {
                    Text("\(score.home) – \(score.away)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(disputed ? Color.theme.accentOrange : Color.theme.accentYellow)
                        .frame(width: 70)
                } else {
                    Text("–")
                        .font(.title3)
                        .foregroundColor(Color.theme.textTertiary)
                        .frame(width: 70)
                }

                Text(match.awayTeamName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.theme.textPrimary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)
            .padding(.bottom, 10)

            Divider()
                .overlay(Color.theme.border)

            // Submission status rows
            VStack(spacing: 6) {
                submissionStatusRow(
                    label: "Home Captain",
                    submission: match.homeSubmission,
                    isDisputed: disputed
                )
                submissionStatusRow(
                    label: "Away Captain",
                    submission: match.awaySubmission,
                    isDisputed: disputed
                )
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            Divider()
                .overlay(Color.theme.border)

            // Footer: date + status
            HStack {
                if let date = match.scheduledDate {
                    Label(date.displayDate, systemImage: "calendar")
                        .font(.caption2)
                        .foregroundColor(Color.theme.textSecondary)
                }
                Spacer()
                if disputed {
                    Text("DISPUTED")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(Color.theme.accentOrange)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.theme.accentOrange.opacity(0.12))
                        .clipShape(Capsule())
                } else {
                    StatusBadge.forMatch(match.status)
                }
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 12)
            .padding(.top, 8)
        }
        .background(Color.theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.theme.accentYellow.opacity(0.4), lineWidth: 1)
        )
    }

    private func submissionStatusRow(label: String, submission: ScoreSubmission?, isDisputed: Bool) -> some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.caption)
                .foregroundColor(Color.theme.textSecondary)
            Spacer()
            if let sub = submission {
                Text("\(sub.homeScore) – \(sub.awayScore)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(isDisputed ? Color.theme.accentOrange : Color.theme.textPrimary)
                Image(systemName: isDisputed ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                    .font(.caption2)
                    .foregroundColor(isDisputed ? Color.theme.accentOrange : Color.theme.accentGreen)
            } else {
                Text("Awaiting")
                    .font(.caption)
                    .foregroundColor(Color.theme.textTertiary)
                Image(systemName: "clock")
                    .font(.caption2)
                    .foregroundColor(Color.theme.textTertiary)
            }
        }
    }

    // MARK: - Pagination Footer

    @ViewBuilder
    private var paginationFooter: some View {
        if isLoadingMore {
            HStack(spacing: 10) {
                ProgressView()
                    .scaleEffect(0.85)
                    .tint(Color.theme.accent)
                Text("Loading more matches...")
                    .font(.caption)
                    .foregroundColor(Color.theme.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        } else if hasMore {
            Button {
                Task { await onLoadMore?() }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.down.circle")
                    Text("Load More Matches")
                }
                .font(.subheadline.weight(.medium))
                .foregroundColor(Color.theme.accent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.theme.surfaceLight)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }
}
