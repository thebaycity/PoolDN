import SwiftUI

struct StandingsView: View {
    let standings: [Standing]
    var currentPlayerTeamIds: [String] = []

    var body: some View {
        ScrollView {
            if standings.isEmpty {
                EmptyStateView(
                    icon: "list.number",
                    title: "No Standings",
                    message: "Standings will appear after matches are completed"
                )
            } else {
                VStack(spacing: 0) {
                    // Header
                    HStack(spacing: 0) {
                        Text("#")
                            .frame(width: 28, alignment: .center)
                        Text("Team")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 8)
                        Text("Form")
                            .frame(width: 56, alignment: .center)
                        Group {
                            Text("P").frame(width: 26)
                            Text("W").frame(width: 26)
                            Text("D").frame(width: 26)
                            Text("L").frame(width: 26)
                            Text("GD").frame(width: 32)
                            Text("Pts").frame(width: 32)
                        }
                    }
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(Color.theme.textSecondary)
                    .textCase(.uppercase)
                    .tracking(0.3)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color.theme.surfaceLight)

                    ForEach(Array(standings.enumerated()), id: \.element.teamId) { index, entry in
                        let isMyTeam = currentPlayerTeamIds.contains(entry.teamId)
                        HStack(spacing: 0) {
                            // Position with medal
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

                            // Team avatar + name
                            HStack(spacing: 8) {
                                ZStack {
                                    Circle()
                                        .fill(Color.theme.accent.opacity(0.15))
                                        .frame(width: 28, height: 28)
                                    Text(teamInitials(entry.teamName))
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(Color.theme.accent)
                                }

                                Text(entry.teamName)
                                    .font(.subheadline)
                                    .fontWeight(index < 3 || isMyTeam ? .semibold : .regular)
                                    .foregroundColor(Color.theme.textPrimary)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            // Form guide
                            formGuide(entry.form ?? [])
                                .frame(width: 56)

                            Group {
                                Text("\(entry.played)")
                                    .frame(width: 26)
                                    .foregroundColor(Color.theme.textPrimary)
                                Text("\(entry.won)")
                                    .frame(width: 26)
                                    .foregroundColor(Color.theme.accentGreen)
                                Text("\(entry.drawn)")
                                    .frame(width: 26)
                                    .foregroundColor(Color.theme.textSecondary)
                                Text("\(entry.lost)")
                                    .frame(width: 26)
                                    .foregroundColor(Color.theme.accentRed)
                                Text("\(entry.gameDifference > 0 ? "+" : "")\(entry.gameDifference)")
                                    .frame(width: 32)
                                    .foregroundColor(Color.theme.textSecondary)
                                Text("\(entry.points)")
                                    .frame(width: 32)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color.theme.accent)
                            }
                            .font(.caption)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            isMyTeam
                                ? Color.theme.accent.opacity(0.08)
                                : (index % 2 == 0 ? Color.theme.surface : Color.theme.surface.opacity(0.6))
                        )
                        .overlay(alignment: .leading) {
                            if isMyTeam {
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

    private func formGuide(_ form: [String]) -> some View {
        HStack(spacing: 3) {
            ForEach(Array(form.enumerated()), id: \.offset) { _, result in
                Circle()
                    .fill(formColor(result))
                    .frame(width: 8, height: 8)
            }
        }
    }

    private func formColor(_ result: String) -> Color {
        switch result {
        case "W": return Color.theme.accentGreen
        case "L": return Color.theme.accentRed
        case "D": return Color.theme.textSecondary
        default: return Color.theme.textTertiary
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
