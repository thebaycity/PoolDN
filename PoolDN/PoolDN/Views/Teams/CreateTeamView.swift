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
                    FormField(label: "Team Name", text: $viewModel.name, placeholder: "e.g. Pool Sharks", icon: "person.3")

                    CitySelectionView(
                        label: "City",
                        selectedCity: $viewModel.city,
                        selectedCountry: $viewModel.country,
                        isOptional: true
                    )

                    FormField(label: "Home Venue (optional)", text: $viewModel.homeVenue, placeholder: "e.g. City Pool Hall", icon: "building.2")
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
                .disabled(viewModel.isLoading || viewModel.name.isEmpty)
            }
            .padding(20)
        }
        .background(Color.theme.background)
        .navigationTitle("Create Team")
        .navigationBarTitleDisplayMode(.inline)
    }
}
