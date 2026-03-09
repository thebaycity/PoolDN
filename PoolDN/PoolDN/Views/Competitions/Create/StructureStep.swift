import SwiftUI

struct StructureStep: View {
    @Bindable var viewModel: CompetitionCreateViewModel
    @State private var newGameLabel = ""

    var body: some View {
        Form {
            Section {
                if viewModel.gameStructure.isEmpty {
                    Label("No games added yet. Add games below.", systemImage: "info.circle")
                        .font(.caption)
                        .foregroundColor(Color.theme.textSecondary)
                } else {
                    ForEach(Array(viewModel.gameStructure.enumerated()), id: \.offset) { _, item in
                        HStack {
                            Image(systemName: item.type == "game" ? "circle.fill" : "pause.fill")
                                .font(.caption2)
                                .foregroundColor(item.type == "game" ? Color.theme.accent : Color.theme.textTertiary)
                            Text(item.label)
                            Spacer()
                            Text(item.type.capitalized)
                                .font(.caption2)
                                .foregroundColor(Color.theme.textSecondary)
                        }
                    }
                }
            } header: {
                Text("Match Structure")
            } footer: {
                Text("Define individual games and breaks within a match.")
            }

            Section("Add Item") {
                TextField("e.g. 8-Ball Singles", text: $newGameLabel)
                HStack(spacing: 12) {
                    Button {
                        guard !newGameLabel.isEmpty else { return }
                        viewModel.addGame(label: newGameLabel)
                        newGameLabel = ""
                    } label: {
                        Label("Add Game", systemImage: "plus.circle.fill")
                    }
                    .disabled(newGameLabel.isEmpty)

                    Spacer()

                    Button {
                        guard !newGameLabel.isEmpty else { return }
                        viewModel.addBreak(label: newGameLabel)
                        newGameLabel = ""
                    } label: {
                        Label("Add Break", systemImage: "pause.circle.fill")
                    }
                    .foregroundColor(Color.theme.textSecondary)
                    .disabled(newGameLabel.isEmpty)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.theme.background)
    }
}
