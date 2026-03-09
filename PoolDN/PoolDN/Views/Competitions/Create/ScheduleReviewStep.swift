import SwiftUI

struct ScheduleReviewStep: View {
    @Bindable var viewModel: CompetitionCreateViewModel

    private let weekdayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    var body: some View {
        Form {
            Section("Venue") {
                Picker("Venue Type", selection: $viewModel.venueType) {
                    Text("Central Venue").tag("central")
                    Text("Team Venues").tag("team_venues")
                }
                .pickerStyle(.segmented)

                if viewModel.venueType == "central" {
                    TextField("Venue Name", text: $viewModel.centralVenue)
                }
            }

            Section("Matchups") {
                Picker("Games per Opponent", selection: $viewModel.gamesPerOpponent) {
                    Text("1 (Single)").tag(1)
                    Text("2 (Home & Away)").tag(2)
                }
                .pickerStyle(.segmented)
            }

            Section("Scheduling") {
                Picker("Type", selection: $viewModel.schedulingType) {
                    Text("Weekly Rounds").tag("weekly_rounds")
                    Text("Fixed Matchdays").tag("fixed_matchdays")
                }
                .pickerStyle(.segmented)

                if viewModel.schedulingType == "weekly_rounds" {
                    HStack(spacing: 6) {
                        ForEach(0..<7) { day in
                            let isSelected = viewModel.selectedWeekdays.contains(day)
                            Button {
                                if isSelected {
                                    viewModel.selectedWeekdays.remove(day)
                                } else {
                                    viewModel.selectedWeekdays.insert(day)
                                }
                            } label: {
                                Text(weekdayNames[day])
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(isSelected ? Color.theme.accent : Color.theme.surfaceLight)
                                    .foregroundColor(isSelected ? .white : Color.theme.textSecondary)
                                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
            }

            Section("Summary") {
                summaryRow(label: "Name", value: viewModel.name.isEmpty ? "—" : viewModel.name)
                if !viewModel.gameType.isEmpty {
                    summaryRow(label: "Game", value: viewModel.gameType)
                }
                summaryRow(label: "Team Size", value: "\(viewModel.teamSizeMin) – \(viewModel.teamSizeMax)")
                summaryRow(label: "Match Games", value: "\(viewModel.gameStructure.count)")
                summaryRow(label: "Venue", value: viewModel.venueType == "central" ? "Central" : "Team Venues")
                summaryRow(label: "Games/Opponent", value: "\(viewModel.gamesPerOpponent)")
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.theme.background)
    }

    private func summaryRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundColor(Color.theme.textSecondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
                .foregroundColor(Color.theme.textPrimary)
        }
        .font(.subheadline)
    }
}
