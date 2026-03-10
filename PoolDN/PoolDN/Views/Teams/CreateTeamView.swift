import SwiftUI

struct CreateTeamView: View {
    @Bindable var appState: AppState
    @State private var viewModel = CreateTeamViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Create a Team")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(Color.theme.textPrimary)
                    Text("You'll be the captain of this team")
                        .font(.subheadline)
                        .foregroundColor(Color.theme.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(spacing: 16) {
                    // Team Name with inline validation
                    VStack(alignment: .leading, spacing: 6) {
                        FormField(
                            label: "Team Name *",
                            text: $viewModel.name,
                            placeholder: "e.g. Pool Sharks",
                            icon: "person.3"
                        )
                        if let err = viewModel.nameError {
                            Label(err, systemImage: "exclamationmark.triangle.fill")
                                .font(.caption2)
                                .foregroundColor(Color.theme.accentRed)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .animation(.easeInOut(duration: 0.18), value: viewModel.nameError)

                    CitySelectionView(
                        label: "City",
                        selectedCity: $viewModel.city,
                        selectedCountry: $viewModel.country,
                        isOptional: true
                    )

                    FormField(label: "Home Venue (optional)", text: $viewModel.homeVenue, placeholder: "e.g. City Pool Hall", icon: "building.2")
                }

                // API error
                if let error = viewModel.errorMessage {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.caption)
                        Text(error)
                            .font(.caption)
                    }
                    .foregroundColor(Color.theme.accentRed)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button {
                    Task {
                        if let _ = await viewModel.create() {
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
                                Text("Create Team")
                            }
                        }
                    }
                    .primaryButton()
                }
                .disabled(!viewModel.isValid || viewModel.isLoading)
                .opacity(!viewModel.isValid ? 0.5 : 1)
                .animation(.easeInOut(duration: 0.18), value: viewModel.isValid)
            }
            .padding(20)
        }
        .background(Color.theme.background)
        .navigationTitle("Create Team")
        .navigationBarTitleDisplayMode(.inline)
    }
}
