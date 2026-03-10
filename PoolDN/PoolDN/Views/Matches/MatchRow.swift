import SwiftUI

struct MatchRow: View {
    let match: Match

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                VStack(spacing: 2) {
                    Text(match.homeTeamName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.theme.textPrimary)
                        .lineLimit(1)
                    Text("Home")
                        .font(.caption2)
                        .foregroundColor(Color.theme.textTertiary)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)

                ZStack {
                    if match.status == .completed {
                        Text("\(match.homeScore) – \(match.awayScore)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(Color.theme.textPrimary)
                    } else if match.status == .pendingReview,
                              let sub = match.homeSubmission ?? match.awaySubmission {
                        VStack(spacing: 1) {
                            Text("\(sub.homeScore) – \(sub.awayScore)")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(Color.theme.accentYellow)
                            Text("Proposed")
                                .font(.system(size: 8, weight: .medium))
                                .foregroundColor(Color.theme.accentYellow.opacity(0.7))
                        }
                    } else {
                        Text("vs")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(Color.theme.textTertiary)
                    }
                }
                .frame(width: 70)

                VStack(spacing: 2) {
                    Text(match.awayTeamName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.theme.textPrimary)
                        .lineLimit(1)
                    Text("Away")
                        .font(.caption2)
                        .foregroundColor(Color.theme.textTertiary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack {
                if let date = match.scheduledDate {
                    Label(date.displayDate, systemImage: "calendar")
                        .font(.caption2)
                        .foregroundColor(Color.theme.textSecondary)
                }
                Spacer()
                StatusBadge.forMatch(match.status)
            }
        }
        .padding(14)
        .background(Color.theme.surface)
    }
}
