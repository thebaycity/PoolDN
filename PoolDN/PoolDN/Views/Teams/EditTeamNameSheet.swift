import SwiftUI

struct EditTeamNameSheet: View {
    @Bindable var viewModel: TeamDetailViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var isSaving = false
    @FocusState private var focused: Bool

    private var isValid: Bool {
        let t = name.trimmingCharacters(in: .whitespaces)
        return !t.isEmpty && t.count >= 2 && t != viewModel.team?.name
    }

    private var nameError: String? {
        let t = name.trimmingCharacters(in: .whitespaces)
        if t.isEmpty { return nil }
        if t.count < 2 { return "Name must be at least 2 characters" }
        return nil
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(spacing: 20) {
                    // Team initials preview — updates live
                    ZStack {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.theme.accent.opacity(0.12))
                            .frame(width: 64, height: 64)
                        Text(String((name.isEmpty ? (viewModel.team?.name ?? "?") : name).prefix(2)).uppercased())
                            .font(.title2.bold())
                            .foregroundColor(Color.theme.accent)
                    }
                    .animation(.easeInOut(duration: 0.15), value: name)
                    .padding(.top, 24)

                    // Field card
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Team Name", systemImage: "person.3")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(Color.theme.accent)
                            .textCase(.uppercase)
                            .tracking(0.4)

                        TextField("Enter team name", text: $name)
                            .font(.body)
                            .foregroundColor(Color.theme.textPrimary)
                            .focused($focused)
                            .submitLabel(.done)
                            .onSubmit {
                                if isValid { Task { await save() } }
                            }

                        if let err = nameError {
                            Text(err)
                                .font(.caption2)
                                .foregroundColor(Color.theme.accentRed)
                                .transition(.opacity)
                        }
                    }
                    .padding(14)
                    .background(Color.theme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(
                                focused ? Color.theme.accent.opacity(0.5) : Color.theme.border,
                                lineWidth: focused ? 1.5 : 0.5
                            )
                            .animation(.easeInOut(duration: 0.18), value: focused)
                    )
                    .padding(.horizontal, 16)
                    .animation(.easeInOut(duration: 0.15), value: nameError)

                    // Save button
                    Button {
                        Task { await save() }
                    } label: {
                        Group {
                            if isSaving {
                                ProgressView().tint(.white)
                            } else {
                                Text("Save Name")
                                    .font(.subheadline.weight(.semibold))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(isValid ? Color.theme.accent : Color.theme.accent.opacity(0.35))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .disabled(!isValid || isSaving)
                    .buttonStyle(.plain)
                    .padding(.horizontal, 16)

                    Spacer()
                }
            }
            .background(Color.theme.background)
            .navigationTitle("Edit Team Name")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                name = viewModel.team?.name ?? ""
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    focused = true
                }
            }
        }
        .presentationDetents([.height(360)])
        .presentationDragIndicator(.visible)
    }

    private func save() async {
        isSaving = true
        let success = await viewModel.updateTeamName(name)
        isSaving = false
        if success { dismiss() }
    }
}

