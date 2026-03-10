import SwiftUI

struct ParticipantsStep: View {
    @Bindable var viewModel: CompetitionCreateViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Team Size card
                VStack(alignment: .leading, spacing: 16) {
                    Label("Team Size", systemImage: "person.2")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(Color.theme.accent)
                        .textCase(.uppercase)
                        .tracking(0.4)

                    HStack(spacing: 24) {
                        sizeControl(
                            label: "Minimum",
                            value: $viewModel.teamSizeMin,
                            range: 1...viewModel.teamSizeMax
                        )

                        Rectangle()
                            .fill(Color.theme.separator)
                            .frame(width: 1, height: 60)

                        sizeControl(
                            label: "Maximum",
                            value: $viewModel.teamSizeMax,
                            range: viewModel.teamSizeMin...20
                        )
                    }

                    // Visual range display
                    HStack(spacing: 6) {
                        Image(systemName: "info.circle")
                            .font(.caption)
                        Text("Teams must have between \(viewModel.teamSizeMin) and \(viewModel.teamSizeMax) registered players.")
                            .font(.caption)
                    }
                    .foregroundColor(Color.theme.textSecondary)
                    .padding(10)
                    .background(Color.theme.accent.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .padding(14)
                .background(Color.theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color.theme.border, lineWidth: 0.5)
                )

                // Info banner
                HStack(spacing: 12) {
                    Image(systemName: "person.badge.plus")
                        .font(.title3)
                        .foregroundColor(Color.theme.accent)
                        .frame(width: 40, height: 40)
                        .background(Color.theme.accent.opacity(0.1))
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Team Applications")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(Color.theme.textPrimary)
                        Text("Teams can apply to join once you publish this competition.")
                            .font(.caption)
                            .foregroundColor(Color.theme.textSecondary)
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

    private func sizeControl(label: String, value: Binding<Int>, range: ClosedRange<Int>) -> some View {
        VStack(spacing: 8) {
            Text(label)
                .font(.caption)
                .foregroundColor(Color.theme.textSecondary)

            HStack(spacing: 16) {
                Button {
                    if value.wrappedValue > range.lowerBound {
                        value.wrappedValue -= 1
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundColor(value.wrappedValue > range.lowerBound ? Color.theme.accent : Color.theme.textTertiary)
                }
                .buttonStyle(.plain)

                Text("\(value.wrappedValue)")
                    .font(.title.weight(.bold))
                    .foregroundColor(Color.theme.textPrimary)
                    .frame(minWidth: 36)
                    .monospacedDigit()

                Button {
                    if value.wrappedValue < range.upperBound {
                        value.wrappedValue += 1
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(value.wrappedValue < range.upperBound ? Color.theme.accent : Color.theme.textTertiary)
                }
                .buttonStyle(.plain)
            }

            Text("players")
                .font(.caption2)
                .foregroundColor(Color.theme.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }
}
