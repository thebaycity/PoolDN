import SwiftUI

struct ParticipantsStep: View {
    @Bindable var viewModel: CompetitionCreateViewModel

    var body: some View {
        Form {
            Section {
                Stepper("\(viewModel.teamSizeMin) players", value: $viewModel.teamSizeMin, in: 1...10)
            } header: {
                Text("Minimum Team Size")
            }

            Section {
                Stepper("\(viewModel.teamSizeMax) players", value: $viewModel.teamSizeMax, in: 1...20)
            } header: {
                Text("Maximum Team Size")
            }

            Section {
                Label("Teams can apply once the competition is published.", systemImage: "info.circle")
                    .font(.caption)
                    .foregroundColor(Color.theme.textSecondary)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.theme.background)
    }
}
