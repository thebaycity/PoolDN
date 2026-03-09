import SwiftUI

struct EditProfileSheet: View {
    @Bindable var viewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Edit Profile")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(Color.theme.textPrimary)
                        Text("Update your personal information")
                            .font(.subheadline)
                            .foregroundColor(Color.theme.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(spacing: 16) {
                        FormField(label: "Name", text: $viewModel.editName, placeholder: "Your name", icon: "person")
                        FormField(label: "Nickname", text: $viewModel.editNickname, placeholder: "Optional", icon: "at")
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
                            if await viewModel.save() {
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
                                    Text("Save Changes")
                                }
                            }
                        }
                        .primaryButton()
                    }
                }
                .padding(20)
            }
            .background(Color.theme.background)
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
