import SwiftUI

struct SubmitResultSheet: View {
    let match: Match
    var gameStructure: [GameDefinition]? = nil
    var homeRoster: [RosterPlayer] = []
    var awayRoster: [RosterPlayer] = []
    @State private var viewModel = SubmitResultViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if viewModel.useGameMode {
                        gameByGameContent
                    } else {
                        simpleScoreContent
                    }

                    if let error = viewModel.errorMessage {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.caption)
                            Text(error)
                                .font(.caption)
                        }
                        .foregroundColor(Color.theme.accentRed)
                    }

                    submitButton
                }
                .padding(20)
            }
            .background(Color.theme.background)
            .navigationTitle("Submit Result")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                if let structure = gameStructure, !structure.isEmpty {
                    viewModel.setupGames(from: structure)
                }
            }
        }
    }

    // MARK: - Game-by-game mode

    private var gameByGameContent: some View {
        VStack(spacing: 20) {
            // Auto-calculated score header
            HStack(spacing: 0) {
                VStack(spacing: 4) {
                    Text(match.homeTeamName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.theme.textPrimary)
                        .lineLimit(1)
                    Text("Home")
                        .font(.caption2)
                        .foregroundColor(Color.theme.textTertiary)
                }
                .frame(maxWidth: .infinity)

                Text("\(viewModel.calculatedHomeScore) – \(viewModel.calculatedAwayScore)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(Color.theme.textPrimary)

                VStack(spacing: 4) {
                    Text(match.awayTeamName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.theme.textPrimary)
                        .lineLimit(1)
                    Text("Away")
                        .font(.caption2)
                        .foregroundColor(Color.theme.textTertiary)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 8)

            ForEach(viewModel.gameEntries) { entry in
                gameEntryCard(entry)
            }
        }
    }

    private func gameEntryCard(_ entry: GameEntry) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(entry.gameDefinition.label)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(Color.theme.textPrimary)
                Spacer()
                if entry.isComplete {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color.theme.accentGreen)
                        .font(.subheadline)
                }
            }

            Divider().overlay(Color.theme.separator)

            // Player pickers
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Home")
                        .font(.caption2)
                        .foregroundColor(Color.theme.textTertiary)
                    playerPicker(
                        roster: homeRoster,
                        selectedIds: entry.homePlayerIds,
                        selectedNames: entry.homePlayerNames,
                        requiredCount: entry.requiredPlayerCount
                    ) { ids, names in
                        entry.homePlayerIds = ids
                        entry.homePlayerNames = names
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("vs")
                    .font(.caption)
                    .foregroundColor(Color.theme.textTertiary)

                VStack(alignment: .trailing, spacing: 6) {
                    Text("Away")
                        .font(.caption2)
                        .foregroundColor(Color.theme.textTertiary)
                    playerPicker(
                        roster: awayRoster,
                        selectedIds: entry.awayPlayerIds,
                        selectedNames: entry.awayPlayerNames,
                        requiredCount: entry.requiredPlayerCount
                    ) { ids, names in
                        entry.awayPlayerIds = ids
                        entry.awayPlayerNames = names
                    }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }

            // Winner toggle
            HStack(spacing: 8) {
                winnerButton(label: "Home Win", isSelected: entry.winner == .home) {
                    entry.winner = entry.winner == .home ? .none : .home
                }
                winnerButton(label: "Away Win", isSelected: entry.winner == .away) {
                    entry.winner = entry.winner == .away ? .none : .away
                }
            }
        }
        .cardStyle()
    }

    private func playerPicker(
        roster: [RosterPlayer],
        selectedIds: [String],
        selectedNames: [String],
        requiredCount: Int,
        onSelect: @escaping ([String], [String]) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(0..<requiredCount, id: \.self) { index in
                let currentId = index < selectedIds.count ? selectedIds[index] : nil
                let currentName = index < selectedNames.count ? selectedNames[index] : nil
                Menu {
                    ForEach(roster, id: \.playerId) { player in
                        Button(player.name) {
                            var ids = selectedIds
                            var names = selectedNames
                            // Pad arrays if needed
                            while ids.count <= index { ids.append("") }
                            while names.count <= index { names.append("") }
                            ids[index] = player.playerId
                            names[index] = player.name
                            onSelect(ids, names)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(currentName ?? (requiredCount > 1 ? "Player \(index + 1)" : "Select player"))
                            .font(.subheadline)
                            .foregroundColor(currentId != nil ? Color.theme.textPrimary : Color.theme.textTertiary)
                            .lineLimit(1)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption2)
                            .foregroundColor(Color.theme.textTertiary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.theme.surfaceLight)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }
        }
    }

    private func winnerButton(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : Color.theme.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(isSelected ? Color.theme.accent : Color.theme.surfaceLight)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Simple score mode (fallback)

    private var simpleScoreContent: some View {
        VStack(spacing: 32) {
            Text("Submit Result")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color.theme.textPrimary)
                .padding(.top, 8)

            scoreCounter(teamName: match.homeTeamName, label: "Home", score: $viewModel.homeScore)
            Divider().overlay(Color.theme.separator).padding(.horizontal, 40)
            scoreCounter(teamName: match.awayTeamName, label: "Away", score: $viewModel.awayScore)
        }
    }

    private func scoreCounter(teamName: String, label: String, score: Binding<Int>) -> some View {
        VStack(spacing: 10) {
            Text(teamName)
                .font(.headline)
                .foregroundColor(Color.theme.textPrimary)
            Text(label)
                .font(.caption2)
                .foregroundColor(Color.theme.textTertiary)

            HStack(spacing: 24) {
                Button {
                    if score.wrappedValue > 0 { score.wrappedValue -= 1 }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 36))
                        .foregroundColor(Color.theme.accentRed.opacity(0.8))
                }

                Text("\(score.wrappedValue)")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundColor(Color.theme.textPrimary)
                    .frame(width: 80)

                Button {
                    score.wrappedValue += 1
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 36))
                        .foregroundColor(Color.theme.accentGreen.opacity(0.8))
                }
            }
        }
    }

    // MARK: - Submit button

    private var submitButton: some View {
        Button {
            Task {
                if let _ = await viewModel.submit(matchId: match.id) {
                    dismiss()
                }
            }
        } label: {
            Group {
                if viewModel.isLoading {
                    ProgressView().tint(.white)
                } else {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Confirm Result")
                    }
                }
            }
            .primaryButton()
        }
        .disabled(viewModel.useGameMode && !viewModel.allGamesComplete)
        .opacity(viewModel.useGameMode && !viewModel.allGamesComplete ? 0.5 : 1)
    }
}
