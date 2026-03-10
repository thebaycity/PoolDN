import SwiftUI

struct CompetitionPlayersTab: View {
    let playerRatings: [PlayerRating]
    var currentPlayerId: String? = nil

    var body: some View {
        ScrollView {
            if playerRatings.isEmpty {
                EmptyStateView(
                    icon: "person.text.rectangle",
                    title: "No Player Ratings",
                    message: "Player ratings will appear after game-level results are submitted"
                )
            } else {
                VStack(spacing: 0) {
                    // Header
                    HStack(spacing: 0) {
                        Text("#")
                            .frame(width: 28, alignment: .center)
                        Text("Player")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 8)
                        Text("Team")
                            .frame(width: 60, alignment: .center)
                        Text("GP")
                            .frame(width: 28, alignment: .center)
                        Text("W")
                            .frame(width: 28, alignment: .center)
                        Text("L")
                            .frame(width: 28, alignment: .center)
                        Text("Rtg")
                            .frame(width: 40, alignment: .trailing)
                    }
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(Color.theme.textSecondary)
                    .textCase(.uppercase)
                    .tracking(0.3)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color.theme.surfaceLight)

                    ForEach(Array(playerRatings.enumerated()), id: \.element.playerId) { index, player in
                        let isMe = player.playerId == currentPlayerId
                        HStack(spacing: 0) {
                            // Rank
                            ZStack {
                                if index < 3 {
                                    Circle()
                                        .fill(medalColor(for: index))
                                        .frame(width: 22, height: 22)
                                    Text("\(index + 1)")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                } else {
                                    Text("\(index + 1)")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(Color.theme.textSecondary)
                                }
                            }
                            .frame(width: 28)

                            // Player name
                            Text(player.playerName)
                                .font(.subheadline)
                                .fontWeight(index < 3 || isMe ? .semibold : .regular)
                                .foregroundColor(Color.theme.textPrimary)
                                .lineLimit(1)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.leading, 8)

                            // Team
                            Text(teamInitials(player.teamName))
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(Color.theme.accent)
                                .frame(width: 60, alignment: .center)

                            // Games played
                            Text("\(player.gamesPlayed)")
                                .frame(width: 28, alignment: .center)
                                .foregroundColor(Color.theme.textPrimary)

                            // Wins (singles + doubles)
                            Text("\(player.singlesWon + player.doublesWon)")
                                .frame(width: 28, alignment: .center)
                                .foregroundColor(Color.theme.accentGreen)

                            // Losses
                            Text("\(player.singlesLost + player.doublesLost)")
                                .frame(width: 28, alignment: .center)
                                .foregroundColor(Color.theme.accentRed)

                            // Rating
                            Text(String(format: "%.1f", player.rating))
                                .frame(width: 40, alignment: .trailing)
                                .fontWeight(.bold)
                                .foregroundColor(Color.theme.accent)
                        }
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            isMe
                                ? Color.theme.accent.opacity(0.08)
                                : (index % 2 == 0 ? Color.theme.surface : Color.theme.surface.opacity(0.6))
                        )
                        .overlay(alignment: .leading) {
                            if isMe {
                                Rectangle()
                                    .fill(Color.theme.accent)
                                    .frame(width: 3)
                            }
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color.theme.border, lineWidth: 0.5)
                )
                .padding()
            }
        }
    }

    private func medalColor(for index: Int) -> Color {
        switch index {
        case 0: return Color.theme.accentYellow
        case 1: return Color(white: 0.65)
        case 2: return Color.theme.accentOrange
        default: return Color.theme.textSecondary
        }
    }

    private func teamInitials(_ name: String) -> String {
        let words = name.split(separator: " ")
        if words.count >= 2 {
            return String(words[0].prefix(1) + words[1].prefix(1)).uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }
}
