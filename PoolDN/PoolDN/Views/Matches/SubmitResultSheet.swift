import SwiftUI

struct SubmitResultSheet: View {
    let match: Match
    @State private var viewModel = SubmitResultViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Text("Submit Result")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color.theme.textPrimary)
                    .padding(.top, 8)

                // Home
                VStack(spacing: 10) {
                    Text(match.homeTeamName)
                        .font(.headline)
                        .foregroundColor(Color.theme.textPrimary)
                    Text("Home")
                        .font(.caption2)
                        .foregroundColor(Color.theme.textTertiary)

                    HStack(spacing: 24) {
                        Button {
                            if viewModel.homeScore > 0 { viewModel.homeScore -= 1 }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 36))
                                .foregroundColor(Color.theme.accentRed.opacity(0.8))
                        }

                        Text("\(viewModel.homeScore)")
                            .font(.system(size: 56, weight: .bold, design: .rounded))
                            .foregroundColor(Color.theme.textPrimary)
                            .frame(width: 80)

                        Button {
                            viewModel.homeScore += 1
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 36))
                                .foregroundColor(Color.theme.accentGreen.opacity(0.8))
                        }
                    }
                }

                Divider().overlay(Color.theme.separator).padding(.horizontal, 40)

                // Away
                VStack(spacing: 10) {
                    Text(match.awayTeamName)
                        .font(.headline)
                        .foregroundColor(Color.theme.textPrimary)
                    Text("Away")
                        .font(.caption2)
                        .foregroundColor(Color.theme.textTertiary)

                    HStack(spacing: 24) {
                        Button {
                            if viewModel.awayScore > 0 { viewModel.awayScore -= 1 }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 36))
                                .foregroundColor(Color.theme.accentRed.opacity(0.8))
                        }

                        Text("\(viewModel.awayScore)")
                            .font(.system(size: 56, weight: .bold, design: .rounded))
                            .foregroundColor(Color.theme.textPrimary)
                            .frame(width: 80)

                        Button {
                            viewModel.awayScore += 1
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 36))
                                .foregroundColor(Color.theme.accentGreen.opacity(0.8))
                        }
                    }
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

                Spacer()
            }
            .padding(20)
            .background(Color.theme.background)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
