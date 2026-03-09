import SwiftUI

struct CompetitionMatchesTab: View {
    let competitionId: String
    let matches: [Match]
    @Bindable var appState: AppState

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
                                Text("\(roundData.matches.count) matches")
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
                                }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .strokeBorder(Color.theme.border, lineWidth: 0.5)
                            )
                        }
                    }
                }
                .padding()
            }
        }
    }
}
