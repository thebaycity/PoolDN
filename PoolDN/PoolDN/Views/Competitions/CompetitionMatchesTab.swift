import SwiftUI

struct CompetitionMatchesTab: View {
    let competitionId: String
    let matches: [Match]
    let hasMore: Bool
    let isLoadingMore: Bool
    @Bindable var appState: AppState
    var onLoadMore: (() async -> Void)? = nil

    var matchesByRound: [(round: Int, matches: [Match])] {
        let grouped = Dictionary(grouping: matches) { $0.round }
        return grouped.keys.sorted().map { (round: $0, matches: grouped[$0]!) }
    }

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
                    ForEach(matchesByRound, id: \.round) { roundData in
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
                                        MatchDetailView(match: match, appState: appState)
                                    } label: {
                                        MatchRow(match: match)
                                    }
                                    // Trigger load-more when last match appears
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

                    // Load more indicator
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
                .padding()
            }
        }
    }
}
