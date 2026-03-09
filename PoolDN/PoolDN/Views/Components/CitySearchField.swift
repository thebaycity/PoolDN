import SwiftUI

/// Deprecated: Use CitySelectionView instead
/// This component is kept for backward compatibility
struct CitySearchField: View {
    let label: String
    @Binding var city: String
    @Binding var country: String
    var placeholder: String = "Select city"

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            CitySelectionView(
                label: label,
                selectedCity: $city,
                selectedCountry: $country,
                placeholder: placeholder,
                isOptional: true
            )
        }
    }
}
