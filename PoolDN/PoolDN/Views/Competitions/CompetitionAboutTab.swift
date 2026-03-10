import SwiftUI

struct CompetitionAboutTab: View {
    let competition: Competition
    let isOrganizer: Bool
    @Bindable var viewModel: CompetitionDetailViewModel
    @Bindable var appState: AppState
    @State private var showCompleteConfirmation = false
    @State private var showPublishConfirmation = false
    @State private var showEditSheet = false

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
                        VStack(alignment: .trailing, spacing: 8) {
                            StatusBadge.forCompetition(competition.status)
                            if isOrganizer && (competition.status == .draft || competition.status == .upcoming) {
                                Button {
                                    showEditSheet = true
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                        .font(.caption.weight(.semibold))
                                        .foregroundColor(Color.theme.accent)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Color.theme.accent.opacity(0.1))
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
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

                // Organizer Management
                if isOrganizer {
                    organizerManagementSection
                }
            }
            .padding()
        }
        .sheet(isPresented: $showEditSheet) {
            EditCompetitionView(competition: competition, detailViewModel: viewModel)
        }
    }

    @ViewBuilder
    private var organizerManagementSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Management")
                .font(.headline)
                .foregroundColor(Color.theme.textPrimary)

            Divider().overlay(Color.theme.separator)

            switch competition.status {
            case .draft:
                Label("This competition is in draft. Publish it to start accepting teams.", systemImage: "doc.text")
                    .font(.subheadline)
                    .foregroundColor(Color.theme.textSecondary)

                Button {
                    showPublishConfirmation = true
                } label: {
                    Text("Publish Competition")
                        .primaryButton()
                }
                .confirmationDialog("Publish Competition?", isPresented: $showPublishConfirmation, titleVisibility: .visible) {
                    Button("Publish") {
                        Task { await viewModel.publish() }
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("This will make the competition visible and open for team registration.")
                }

            case .upcoming:
                Label("Open for registration. Manage teams from the Teams tab.", systemImage: "person.3")
                    .font(.subheadline)
                    .foregroundColor(Color.theme.textSecondary)

            case .active:
                Label("Competition is in progress. Complete it when all matches are finished.", systemImage: "sportscourt")
                    .font(.subheadline)
                    .foregroundColor(Color.theme.textSecondary)

                Button {
                    showCompleteConfirmation = true
                } label: {
                    Text("Complete Competition")
                        .primaryButton()
                }
                .confirmationDialog("Complete Competition?", isPresented: $showCompleteConfirmation, titleVisibility: .visible) {
                    Button("Complete", role: .destructive) {
                        Task { await viewModel.completeCompetition() }
                    }
                } message: {
                    Text("This will mark the competition as completed. This action cannot be undone.")
                }

            case .completed:
                Label("This competition has been completed.", systemImage: "trophy")
                    .font(.subheadline)
                    .foregroundColor(Color.theme.accent)

            default:
                EmptyView()
            }
        }
        .cardStyle()
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
