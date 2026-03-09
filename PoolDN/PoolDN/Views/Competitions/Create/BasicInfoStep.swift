import SwiftUI

struct BasicInfoStep: View {
    @Bindable var viewModel: CompetitionCreateViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Basic Info card
                formCard {
                    sectionLabel("Basic Info", icon: "doc.text")

                    styledField("Competition Name", text: $viewModel.name, placeholder: "e.g. City 8-Ball League", icon: "trophy")
                    Divider().overlay(Color.theme.separator)
                    styledField("Game Type", text: $viewModel.gameType, placeholder: "e.g. 8-Ball, 9-Ball", icon: "circle.grid.3x3")
                    Divider().overlay(Color.theme.separator)
                    styledTextEditor("Description (optional)", text: $viewModel.description, placeholder: "Describe the competition format, rules…")
                }

                // Location card
                formCard {
                    sectionLabel("Location", icon: "mappin.circle")
                    CitySelectionView(
                        label: "",
                        selectedCity: $viewModel.city,
                        selectedCountry: $viewModel.country,
                        placeholder: "Select host city",
                        isOptional: true
                    )
                }

                // Date & Prize card
                formCard {
                    sectionLabel("Date & Prize", icon: "calendar")

                    HStack {
                        Label("Start Date", systemImage: "calendar")
                            .font(.subheadline)
                            .foregroundColor(Color.theme.textSecondary)
                        Spacer()
                        DatePicker("", selection: $viewModel.startDate, displayedComponents: .date)
                            .labelsHidden()
                            .tint(Color.theme.accent)
                    }

                    Divider().overlay(Color.theme.separator)

                    HStack {
                        Label("Prize Pool", systemImage: "dollarsign.circle")
                            .font(.subheadline)
                            .foregroundColor(Color.theme.textSecondary)
                        Spacer()
                        HStack(spacing: 4) {
                            Text("$").foregroundColor(Color.theme.textSecondary)
                            TextField("0", text: $viewModel.prize)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                        }
                        .font(.subheadline)
                        .foregroundColor(Color.theme.textPrimary)
                    }
                }

                Spacer(minLength: 32)
            }
            .padding(16)
        }
    }

    // MARK: - Helpers

    private func formCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            content()
        }
        .padding(14)
        .background(Color.theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.theme.border, lineWidth: 0.5)
        )
    }

    private func sectionLabel(_ title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.caption.weight(.semibold))
            .foregroundColor(Color.theme.accent)
            .textCase(.uppercase)
            .tracking(0.4)
    }

    private func styledField(_ label: String, text: Binding<String>, placeholder: String, icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(Color.theme.accent)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(Color.theme.textTertiary)
                TextField(placeholder, text: text)
                    .font(.subheadline)
                    .foregroundColor(Color.theme.textPrimary)
            }
        }
    }

    private func styledTextEditor(_ label: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption)
                .foregroundColor(Color.theme.textTertiary)
            ZStack(alignment: .topLeading) {
                if text.wrappedValue.isEmpty {
                    Text(placeholder)
                        .font(.subheadline)
                        .foregroundColor(Color.theme.textTertiary)
                        .padding(.top, 8)
                        .padding(.leading, 4)
                }
                TextEditor(text: text)
                    .font(.subheadline)
                    .foregroundColor(Color.theme.textPrimary)
                    .frame(minHeight: 70)
                    .scrollContentBackground(.hidden)
            }
        }
    }
}
