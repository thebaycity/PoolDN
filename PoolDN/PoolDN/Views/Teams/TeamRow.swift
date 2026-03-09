import SwiftUI

struct TeamRow: View {
    let team: Team
    var currentPlayerId: String?
    var compact: Bool = false

    private var isCaptain: Bool { team.captainId == currentPlayerId }
    private var isMember: Bool { team.members.contains { $0.playerId == currentPlayerId } }

    // Deterministic accent color from team name
    private var teamColor: Color {
        let palette: [Color] = [.blue, .purple, .pink, .orange, .teal, .indigo, .mint, .cyan]
        let index = abs(team.name.hashValue) % palette.count
        return palette[index]
    }

    var body: some View {
        HStack(spacing: 12) {
            // Team initials
            ZStack {
                RoundedRectangle(cornerRadius: compact ? 10 : 12, style: .continuous)
                    .fill(teamColor.opacity(0.15))
                    .frame(width: compact ? 38 : 44, height: compact ? 38 : 44)
                Text(String(team.name.prefix(2)).uppercased())
                    .font(compact ? .caption.bold() : .subheadline.bold())
                    .foregroundColor(teamColor)
            }

            // Content
            VStack(alignment: .leading, spacing: 3) {
                // Name + role badge
                HStack(spacing: 6) {
                    Text(team.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Color.theme.textPrimary)
                        .lineLimit(1)

                    if isCaptain {
                        Label("Captain", systemImage: "star.fill")
                            .font(.caption2.weight(.bold))
                            .foregroundColor(Color.theme.accentYellow)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.theme.accentYellow.opacity(0.15))
                            .clipShape(Capsule())
                            .fixedSize()
                    } else if isMember {
                        Text("Member")
                            .font(.caption2.weight(.semibold))
                            .foregroundColor(Color.theme.accentGreen)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.theme.accentGreen.opacity(0.12))
                            .clipShape(Capsule())
                            .fixedSize()
                    }
                }

                // Meta line — single Text for proper truncation
                metaText
                    .font(.caption)
                    .foregroundColor(Color.theme.textSecondary)
                    .lineLimit(1)
            }
            .layoutPriority(1)

            Image(systemName: "chevron.right")
                .font(.caption2.weight(.semibold))
                .foregroundColor(Color.theme.textTertiary)
        }
        .padding(compact ? 10 : 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(
                    isCaptain ? teamColor.opacity(0.35) : Color.theme.border,
                    lineWidth: isCaptain ? 1 : 0.5
                )
        )
    }

    // Single Text for proper truncation — no HStack overflow
    private var metaText: Text {
        let count = team.members.count
        let city = (team.city ?? "").isEmpty ? nil : team.city
        let venue = (!compact && !(team.homeVenue ?? "").isEmpty) ? team.homeVenue : nil

        switch (city, venue) {
        case let (c?, v?):
            return Text("\(Image(systemName: "person.2.fill")) \(count)  ·  \(Image(systemName: "mappin")) \(c)  ·  \(Image(systemName: "building.2")) \(v)")
        case let (c?, nil):
            return Text("\(Image(systemName: "person.2.fill")) \(count)  ·  \(Image(systemName: "mappin")) \(c)")
        case let (nil, v?):
            return Text("\(Image(systemName: "person.2.fill")) \(count)  ·  \(Image(systemName: "building.2")) \(v)")
        case (nil, nil):
            return Text("\(Image(systemName: "person.2.fill")) \(count)")
        }
    }
}
