import SwiftUI

struct TeamRow: View {
    let team: Team
    var currentPlayerId: String?

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.theme.accent.opacity(0.15))
                    .frame(width: 44, height: 44)
                Text(String(team.name.prefix(2)).uppercased())
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(Color.theme.accent)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(team.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.theme.textPrimary)
                        .lineLimit(1)

                    if team.captainId == currentPlayerId {
                        Text("Captain")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.theme.accentYellow.opacity(0.2))
                            .foregroundColor(Color.theme.accentYellow)
                            .clipShape(Capsule())
                    }
                }

                HStack(spacing: 12) {
                    Label("\(team.members.count)", systemImage: "person.2.fill")
                        .font(.caption)
                        .foregroundColor(Color.theme.textSecondary)
                    if let city = team.city {
                        Label(city, systemImage: "mappin")
                            .font(.caption)
                            .foregroundColor(Color.theme.textSecondary)
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundColor(Color.theme.textTertiary)
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
