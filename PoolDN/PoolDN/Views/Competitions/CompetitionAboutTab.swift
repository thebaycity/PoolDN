import SwiftUI

struct CompetitionAboutTab: View {
    let competition: Competition
    let isOrganizer: Bool
    @Bindable var viewModel: CompetitionDetailViewModel
    @Bindable var appState: AppState

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header Card
                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(competition.name)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(Color.theme.textPrimary)

                            if let gameType = competition.gameType {
                                Text(gameType)
                                    .font(.subheadline)
                                    .foregroundColor(Color.theme.textSecondary)
                            }
                        }
                        Spacer()
                        StatusBadge.forCompetition(competition.status)
                    }

                    Divider().overlay(Color.theme.separator)

                    infoRow(icon: "person.3", label: "Format", value: "Round Robin")
                    infoRow(icon: "person.2", label: "Team Size", value: "\(competition.teamSizeMin ?? 2) – \(competition.teamSizeMax ?? 5) players")

                    if let startDate = competition.startDate {
                        infoRow(icon: "calendar", label: "Start Date", value: startDate.displayDate)
                    }
                    if let prize = competition.prize, prize > 0 {
                        infoRow(icon: "dollarsign.circle", label: "Prize Pool", value: "$\(Int(prize))")
                    }
                    if let city = competition.city {
                        infoRow(icon: "mappin", label: "Location", value: city)
                    }
                }
                .cardStyle()

                // Description
                if let description = competition.description, !description.isEmpty {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("About")
                            .font(.headline)
                            .foregroundColor(Color.theme.textPrimary)

                        Divider().overlay(Color.theme.separator)

                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(Color.theme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .cardStyle()
                }

                // Schedule Config
                if let config = competition.scheduleConfig {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Schedule")
                            .font(.headline)
                            .foregroundColor(Color.theme.textPrimary)

                        Divider().overlay(Color.theme.separator)

                        infoRow(icon: "mappin.and.ellipse", label: "Venue", value: config.venueType == "central" ? "Central Venue" : "Team Venues")
                        infoRow(icon: "arrow.triangle.2.circlepath", label: "Games / Opponent", value: "\(config.gamesPerOpponent ?? 1)")
                    }
                    .cardStyle()
                }

                // Game Structure
                if let structure = competition.gameStructure, !structure.isEmpty {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Match Structure")
                            .font(.headline)
                            .foregroundColor(Color.theme.textPrimary)

                        Divider().overlay(Color.theme.separator)

                        ForEach(Array(structure.enumerated()), id: \.offset) { index, item in
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(item.type == "game" ? Color.theme.accent.opacity(0.15) : Color.theme.surfaceLight)
                                        .frame(width: 32, height: 32)
                                    Text("\(index + 1)")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(item.type == "game" ? Color.theme.accent : Color.theme.textSecondary)
                                }

                                Text(item.label)
                                    .font(.subheadline)
                                    .foregroundColor(Color.theme.textPrimary)

                                Spacer()

                                Text(item.type.capitalized)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(item.type == "game" ? Color.theme.accent : Color.theme.textSecondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(item.type == "game" ? Color.theme.accent.opacity(0.12) : Color.theme.surfaceLight)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .cardStyle()
                }

                // Organizer Actions
                if isOrganizer && competition.status == .draft {
                    Button {
                        Task { await viewModel.publish() }
                    } label: {
                        Text("Publish Competition")
                            .primaryButton()
                    }
                }
            }
            .padding()
        }
    }

    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(Color.theme.accent)
                .frame(width: 22)
            Text(label)
                .font(.subheadline)
                .foregroundColor(Color.theme.textSecondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(Color.theme.textPrimary)
        }
    }
}
