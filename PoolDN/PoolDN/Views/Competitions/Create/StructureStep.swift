import SwiftUI

struct StructureStep: View {
    @Bindable var viewModel: CompetitionCreateViewModel
    @State private var newGameLabel = ""
    @FocusState private var fieldFocused: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Game Structure card
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("Match Structure", systemImage: "list.bullet.rectangle")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(Color.theme.accent)
                            .textCase(.uppercase)
                            .tracking(0.4)

                        Spacer()

                        if !viewModel.gameStructure.isEmpty {
                            Text("\(viewModel.gameStructure.count) items")
                                .font(.caption)
                                .foregroundColor(Color.theme.textTertiary)
                        }
                    }

                    if viewModel.gameStructure.isEmpty {
                        HStack(spacing: 10) {
                            Image(systemName: "plus.square.dashed")
                                .font(.title3)
                                .foregroundColor(Color.theme.textTertiary)
                            Text("Add games and breaks below to define one match.")
                                .font(.caption)
                                .foregroundColor(Color.theme.textSecondary)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.theme.surfaceLight)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    } else {
                        VStack(spacing: 0) {
                            ForEach(Array(viewModel.gameStructure.enumerated()), id: \.offset) { idx, item in
                                HStack(spacing: 10) {
                                    // Order badge
                                    Text("\(idx + 1)")
                                        .font(.caption2.monospacedDigit())
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .frame(width: 20, height: 20)
                                        .background(item.type == "game" ? Color.theme.accent : Color.theme.textTertiary)
                                        .clipShape(Circle())

                                    Image(systemName: item.type == "game" ? "circle.fill" : "pause.circle.fill")
                                        .font(.caption2)
                                        .foregroundColor(item.type == "game" ? Color.theme.accent : Color.theme.textTertiary)

                                    Text(item.label)
                                        .font(.subheadline)
                                        .foregroundColor(Color.theme.textPrimary)

                                    Spacer()

                                    Text(item.type == "game" ? "Game" : "Break")
                                        .font(.caption2.weight(.semibold))
                                        .foregroundColor(item.type == "game" ? Color.theme.accent : Color.theme.textSecondary)
                                        .padding(.horizontal, 7)
                                        .padding(.vertical, 3)
                                        .background(item.type == "game" ? Color.theme.accent.opacity(0.1) : Color.theme.surfaceLight)
                                        .clipShape(Capsule())

                                    Button {
                                        viewModel.gameStructure.remove(at: idx)
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.body)
                                            .foregroundColor(Color.theme.textTertiary)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.vertical, 10)
                                .padding(.horizontal, 2)

                                if idx < viewModel.gameStructure.count - 1 {
                                    Divider().overlay(Color.theme.separator)
                                }
                            }
                        }
                    }
                }
                .padding(14)
                .background(Color.theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color.theme.border, lineWidth: 0.5)
                )

                // Add Item card
                VStack(alignment: .leading, spacing: 12) {
                    Label("Add Item", systemImage: "plus.circle")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(Color.theme.accent)
                        .textCase(.uppercase)
                        .tracking(0.4)

                    HStack(spacing: 10) {
                        Image(systemName: "tag")
                            .font(.subheadline)
                            .foregroundColor(Color.theme.accent)
                            .frame(width: 20)

                        TextField("e.g. 8-Ball Singles, Break", text: $newGameLabel)
                            .font(.subheadline)
                            .foregroundColor(Color.theme.textPrimary)
                            .focused($fieldFocused)
                            .submitLabel(.done)
                            .onSubmit {
                                addGame()
                            }
                    }
                    .padding(12)
                    .background(Color.theme.surfaceLight)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                    HStack(spacing: 10) {
                        Button {
                            addGame()
                        } label: {
                            Label("Add Game", systemImage: "circle.fill")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 11)
                                .background(newGameLabel.isEmpty ? Color.theme.textTertiary : Color.theme.accent)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        .disabled(newGameLabel.isEmpty)
                        .buttonStyle(.plain)

                        Button {
                            guard !newGameLabel.isEmpty else { return }
                            viewModel.addBreak(label: newGameLabel)
                            newGameLabel = ""
                            fieldFocused = false
                        } label: {
                            Label("Break", systemImage: "pause.fill")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(newGameLabel.isEmpty ? Color.theme.textTertiary : Color.theme.textSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 11)
                                .background(Color.theme.surfaceLight)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .strokeBorder(Color.theme.border, lineWidth: 1)
                                )
                        }
                        .disabled(newGameLabel.isEmpty)
                        .buttonStyle(.plain)
                    }
                }
                .padding(14)
                .background(Color.theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color.theme.border, lineWidth: 0.5)
                )

                Spacer(minLength: 32)
            }
            .padding(16)
        }
    }

    private func addGame() {
        guard !newGameLabel.isEmpty else { return }
        viewModel.addGame(label: newGameLabel)
        newGameLabel = ""
        fieldFocused = false
    }
}
