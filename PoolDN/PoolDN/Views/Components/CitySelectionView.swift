import SwiftUI

/// Reusable City Selection component with country filtering
/// Default country: Vietnam
/// Can be used across the entire app
struct CitySelectionView: View {
    let label: String
    @Binding var selectedCity: String
    @Binding var selectedCountry: String
    var placeholder: String = "Select city"
    var isOptional: Bool = false

    @State private var showPicker = false
    @State private var searchText = ""
    @State private var cities: [City] = []
    @State private var countries: [Country] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let defaultCountry = "VN"
    private let defaultCountryName = "Vietnam"

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !label.isEmpty {
                HStack(spacing: 4) {
                    Text(label)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Color.theme.textPrimary)
                    if !isOptional {
                        Text("*")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(Color.theme.accentRed)
                    } else {
                        Text("(Optional)")
                            .font(.caption)
                            .foregroundColor(Color.theme.textTertiary)
                    }
                }
            }

            Button {
                showPicker = true
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Country")
                            .font(.caption)
                            .foregroundColor(Color.theme.textTertiary)
                        Text(selectedCountry.isEmpty ? defaultCountryName : (countries.first { $0.code == selectedCountry }?.name ?? selectedCountry))
                            .font(.subheadline)
                            .foregroundColor(Color.theme.textPrimary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("City")
                            .font(.caption)
                            .foregroundColor(Color.theme.textTertiary)
                        Text(selectedCity.isEmpty ? placeholder : selectedCity)
                            .font(.subheadline)
                            .foregroundColor(selectedCity.isEmpty ? Color.theme.textTertiary : Color.theme.accent)
                    }

                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundColor(Color.theme.textTertiary)
                }
                .padding(12)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color.theme.border, lineWidth: 0.5)
            )

            if let error = errorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(Color.theme.accentRed)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(Color.theme.accentRed)
                }
            }
        }
        .sheet(isPresented: $showPicker) {
            CityPickerView(
                searchText: $searchText,
                selectedCity: $selectedCity,
                selectedCountry: $selectedCountry,
                cities: $cities,
                countries: $countries,
                isLoading: $isLoading,
                errorMessage: $errorMessage,
                onDismiss: { showPicker = false }
            )
            .onAppear {
                if selectedCountry.isEmpty {
                    selectedCountry = defaultCountry
                }
                Task {
                    await loadCountries()
                    await loadCities(for: selectedCountry)
                }
            }
        }
    }

    private func loadCountries() async {
        do {
            countries = try await CityService.listCountries()
        } catch {
            errorMessage = "Failed to load countries"
        }
    }

    private func loadCities(for countryCode: String) async {
        isLoading = true
        errorMessage = nil
        do {
            cities = try await CityService.searchCities(country: countryCode)
        } catch {
            errorMessage = "Failed to load cities"
            cities = []
        }
        isLoading = false
    }
}

/// Internal picker component for city selection
struct CityPickerView: View {
    @Binding var searchText: String
    @Binding var selectedCity: String
    @Binding var selectedCountry: String
    @Binding var cities: [City]
    @Binding var countries: [Country]
    @Binding var isLoading: Bool
    @Binding var errorMessage: String?
    var onDismiss: () -> Void

    @Environment(\.dismiss) private var dismiss

    private var filteredCities: [City] {
        if searchText.isEmpty {
            return cities
        }
        return cities.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                if isLoading {
                    ProgressView()
                        .tint(Color.theme.accent)
                } else if let error = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(Color.theme.accentRed)
                        Text("Error Loading Cities")
                            .font(.headline)
                            .foregroundColor(Color.theme.textPrimary)
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(Color.theme.textSecondary)
                            .multilineTextAlignment(.center)
                        Button(action: {
                            Task {
                                errorMessage = nil
                                isLoading = true
                                do {
                                    cities = try await CityService.searchCities(country: selectedCountry)
                                } catch {
                                    errorMessage = error.localizedDescription
                                }
                                isLoading = false
                            }
                        }) {
                            Text("Try Again")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(12)
                                .background(Color.theme.accent)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    .padding(24)
                } else {
                    List {
                        Section("Country") {
                            Picker("Select Country", selection: $selectedCountry) {
                                ForEach(countries) { country in
                                    Text(country.name)
                                        .tag(country.code)
                                }
                            }
                            .pickerStyle(.automatic)
                            .onChange(of: selectedCountry) { _, newCountry in
                                Task {
                                    isLoading = true
                                    do {
                                        cities = try await CityService.searchCities(country: newCountry)
                                        selectedCity = ""
                                        errorMessage = nil
                                    } catch {
                                        errorMessage = "Failed to load cities"
                                        cities = []
                                    }
                                    isLoading = false
                                }
                            }
                        }

                        Section("Cities") {
                            if filteredCities.isEmpty {
                                VStack(alignment: .center, spacing: 8) {
                                    Image(systemName: "magnifyingglass")
                                        .font(.title3)
                                        .foregroundColor(Color.theme.textTertiary)
                                    Text(searchText.isEmpty ? "No cities available" : "No cities found")
                                        .font(.subheadline)
                                        .foregroundColor(Color.theme.textSecondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .center)
                                .listRowInsets(EdgeInsets())
                            } else {
                                ForEach(filteredCities) { city in
                                    Button(action: {
                                        selectedCity = city.name
                                        selectedCountry = city.countryCode
                                        onDismiss()
                                        dismiss()
                                    }) {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(city.name)
                                                    .font(.subheadline)
                                                    .foregroundColor(Color.theme.textPrimary)
                                                if let countryName = city.countryName {
                                                    Text(countryName)
                                                        .font(.caption)
                                                        .foregroundColor(Color.theme.textSecondary)
                                                }
                                            }
                                            Spacer()
                                            if city.name == selectedCity {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .font(.body)
                                                    .foregroundColor(Color.theme.accent)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Select City")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search cities")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onDismiss()
                        dismiss()
                    }
                }
                if !selectedCity.isEmpty {
                    ToolbarItem(placement: .destructiveAction) {
                        Button("Clear") {
                            selectedCity = ""
                            searchText = ""
                        }
                        .foregroundColor(Color.theme.accentRed)
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview {
    @State var city = ""
    @State var country = ""

    return VStack(spacing: 24) {
        CitySelectionView(
            label: "City",
            selectedCity: $city,
            selectedCountry: $country,
            isOptional: false
        )

        CitySelectionView(
            label: "Home City (Optional)",
            selectedCity: $city,
            selectedCountry: $country,
            isOptional: true
        )

        Spacer()
    }
    .padding(16)
    .background(Color.theme.background)
}

