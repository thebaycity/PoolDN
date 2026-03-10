import SwiftUI

struct CompetitionRow: View {
    let competition: Competition

    private var statusColor: Color {
        switch competition.status {
        case .draft:     return Color.theme.textTertiary
        case .upcoming:  return Color.theme.accentYellow
        case .active:    return Color.theme.accentGreen
        case .completed: return Color.theme.accentPurple
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            // Status accent strip
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(statusColor)
                .frame(width: 4)
                .padding(.vertical, 6)

            VStack(alignment: .leading, spacing: 10) {
                // Top row: name + status badge
                HStack(alignment: .top, spacing: 8) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(competition.name)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.theme.textPrimary)
                            .lineLimit(1)

                        if let gameType = competition.gameType {
                            HStack(spacing: 4) {
                                Text(gameType)
                                if let format = competition.tournamentType?
                                    .replacingOccurrences(of: "_", with: " ")
                                    .capitalized {
                                    Text("·")
                                    Text(format)
                                }
                            }
                            .font(.caption)
                            .foregroundColor(Color.theme.textSecondary)
                        }
                    }

                    Spacer(minLength: 4)
                    StatusBadge.forCompetition(competition.status)
                }

                // Description
                if let desc = competition.description, !desc.isEmpty {
                    Text(desc)
                        .font(.caption)
                        .foregroundColor(Color.theme.textSecondary)
                        .lineLimit(2)
                }

                // Bottom meta row
                HStack(spacing: 0) {
                    if let startDate = competition.startDate {
                        metaChip(icon: "calendar", text: startDate.displayDate, color: Color.theme.textSecondary)
                    }
                    if let city = competition.city {
                        metaChip(icon: "mappin", text: city, color: Color.theme.textSecondary)
                    }
                    if let prize = competition.prize, prize > 0 {
                        metaChip(icon: "trophy.fill", text: "$\(Int(prize))", color: Color.theme.accentGreen)
                    }

                    Spacer()

                    // Team size pill
                    if let min = competition.teamSizeMin, let max = competition.teamSizeMax {
                        HStack(spacing: 3) {
                            Image(systemName: "person.2")
                                .font(.caption2)
                            Text("\(min)–\(max)")
                                .font(.caption2)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(Color.theme.accent)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .background(Color.theme.accent.opacity(0.1))
                        .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
        }
        .background(Color.theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.theme.border, lineWidth: 0.5)
        )
    }

    private func metaChip(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.caption2)
            Text(text)
                .font(.caption)
        }
        .foregroundColor(color)
        .padding(.trailing, 10)
    }
}
