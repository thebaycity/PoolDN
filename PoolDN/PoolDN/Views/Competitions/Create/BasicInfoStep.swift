import SwiftUI

struct BasicInfoStep: View {
    @Bindable var viewModel: CompetitionCreateViewModel

    var body: some View {
        Form {
            Section {
                TextField("Competition Name", text: $viewModel.name)
                TextField("Game Type (e.g. 8-Ball)", text: $viewModel.gameType)
                TextField("Description (optional)", text: $viewModel.description, axis: .vertical)
                    .lineLimit(2...4)
            } header: {
                Text("Basic Info")
            } footer: {
                Text("Name your competition and set key details.")
            }

            Section("Location") {
                CitySelectionView(
                    label: "City",
                    selectedCity: $viewModel.city,
                    selectedCountry: $viewModel.country,
                    isOptional: false
                )
            }

            Section("Date & Prize") {
                DatePicker("Start Date", selection: $viewModel.startDate, displayedComponents: .date)
                    .tint(Color.theme.accent)
                TextField("Prize Pool ($)", text: $viewModel.prize)
                    .keyboardType(.numberPad)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.theme.background)
    }
}
