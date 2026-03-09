import SwiftUI

struct InvitePlayerSheet: View {
    @Bindable var viewModel: TeamDetailViewModel
    @State private var email = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 6) {
                    Image(systemName: "envelope.badge.person.crop")
                        .font(.largeTitle)
                        .foregroundStyle(Color.theme.accent)
                    Text("Invite a Player")
                        .font(.headline)
                        .foregroundColor(Color.theme.textPrimary)
                    Text("Enter their email to send an invitation")
                        .font(.subheadline)
                        .foregroundColor(Color.theme.textSecondary)
                }
                .padding(.top, 8)

                FormField(label: "Email", text: $email, placeholder: "player@example.com", icon: "envelope")
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

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
                        await viewModel.invitePlayer(email: email)
                        dismiss()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "paperplane.fill")
                        Text("Send Invitation")
                    }
                    .primaryButton()
                }
                .disabled(email.isEmpty)

                Spacer()
            }
            .padding(20)
            .background(Color.theme.background)
            .navigationTitle("Invite Player")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
