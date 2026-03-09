import SwiftUI

struct CompetitionRow: View {
    let competition: Competition

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(competition.name)
                        .font(.headline)
                        .foregroundColor(Color.theme.textPrimary)
                        .lineLimit(1)

                    if let gameType = competition.gameType {
                        HStack(spacing: 6) {
                            Text(gameType)
                            if let format = competition.tournamentType?.replacingOccurrences(of: "_", with: " ").capitalized {
                                Text("·")
                                Text(format)
                            }
                        }
                        .font(.caption)
                        .foregroundColor(Color.theme.textSecondary)
                    }
                }

                Spacer()
                StatusBadge.forCompetition(competition.status)
            }

            if let desc = competition.description, !desc.isEmpty {
                Text(desc)
                    .font(.caption)
                    .foregroundColor(Color.theme.textSecondary)
                    .lineLimit(2)
            }

            HStack(spacing: 14) {
                if let startDate = competition.startDate {
                    Label(startDate.displayDate, systemImage: "calendar")
                        .font(.caption)
                        .foregroundColor(Color.theme.textSecondary)
                }
                if let city = competition.city {
                    Label(city, systemImage: "mappin")
                        .font(.caption)
                        .foregroundColor(Color.theme.textSecondary)
                }
                if let prize = competition.prize, prize > 0 {
                    Label("$\(Int(prize))", systemImage: "dollarsign.circle")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(Color.theme.accentGreen)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundColor(Color.theme.textTertiary)
            }
        }
        .padding(14)
        .background(Color.theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.theme.border, lineWidth: 0.5)
        )
    }
}
