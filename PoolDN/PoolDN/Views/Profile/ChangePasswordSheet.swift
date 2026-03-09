import SwiftUI

struct ChangePasswordSheet: View {
    @Bindable var viewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss

    @FocusState private var focusedField: Field?
    @State private var showCurrent = false
    @State private var showNew = false
    @State private var showConfirm = false
    @State private var didSucceed = false

    private enum Field { case current, new, confirm }

    // Password strength computed from new password
    private var strength: PasswordStrength {
        PasswordStrength(password: viewModel.newPassword)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    headerSection
                    fieldsSection
                    strengthSection
                    errorSection
                    actionButton
                }
                .padding(20)
            }
            .background(Color.theme.background)
            .navigationTitle("Change Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.resetPasswordFields()
                        dismiss()
                    }
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    focusedField = .current
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.theme.accent.opacity(0.12))
                    .frame(width: 48, height: 48)
                Image(systemName: "lock.rotation")
                    .font(.title3)
                    .foregroundColor(Color.theme.accent)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text("Update your password")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Color.theme.textPrimary)
                Text("Choose a strong password at least 6 characters long.")
                    .font(.caption)
                    .foregroundColor(Color.theme.textSecondary)
            }
            Spacer()
        }
        .padding(14)
        .background(Color.theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.theme.border, lineWidth: 0.5)
        )
    }

    // MARK: - Fields

    private var fieldsSection: some View {
        VStack(spacing: 0) {
            passwordField(
                label: "Current Password",
                icon: "lock",
                text: $viewModel.currentPassword,
                show: $showCurrent,
                field: .current,
                next: .new
            )

            Divider()
                .overlay(Color.theme.separator)
                .padding(.leading, 46)

            passwordField(
                label: "New Password",
                icon: "lock.open",
                text: $viewModel.newPassword,
                show: $showNew,
                field: .new,
                next: .confirm
            )

            Divider()
                .overlay(Color.theme.separator)
                .padding(.leading, 46)

            passwordField(
                label: "Confirm New Password",
                icon: "lock.open",
                text: $viewModel.confirmPassword,
                show: $showConfirm,
                field: .confirm,
                next: nil,
                isLast: true
            )
        }
        .background(Color.theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(
                    confirmMismatch ? Color.theme.accentRed.opacity(0.4) : Color.theme.border,
                    lineWidth: 0.5
                )
        )
    }

    private func passwordField(
        label: String,
        icon: String,
        text: Binding<String>,
        show: Binding<Bool>,
        field: Field,
        next: Field?,
        isLast: Bool = false
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(focusedField == field ? Color.theme.accent : Color.theme.textTertiary)
                .frame(width: 22)
                .animation(.easeInOut(duration: 0.2), value: focusedField)

            VStack(alignment: .leading, spacing: 3) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(Color.theme.textTertiary)

                Group {
                    if show.wrappedValue {
                        TextField("", text: text)
                    } else {
                        SecureField("", text: text)
                    }
                }
                .font(.subheadline)
                .foregroundColor(Color.theme.textPrimary)
                .focused($focusedField, equals: field)
                .submitLabel(isLast ? .done : .next)
                .onSubmit {
                    if let next {
                        focusedField = next
                    } else {
                        focusedField = nil
                        Task { await submit() }
                    }
                }
            }

            Spacer()

            // Match indicator for confirm field
            if field == .confirm && !viewModel.confirmPassword.isEmpty {
                Image(systemName: confirmMismatch ? "xmark.circle.fill" : "checkmark.circle.fill")
                    .font(.body)
                    .foregroundColor(confirmMismatch ? Color.theme.accentRed : Color.theme.accentGreen)
                    .transition(.scale.combined(with: .opacity))
            }

            Button {
                show.wrappedValue.toggle()
            } label: {
                Image(systemName: show.wrappedValue ? "eye.slash" : "eye")
                    .font(.subheadline)
                    .foregroundColor(Color.theme.textTertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
    }

    // MARK: - Strength Meter

    @ViewBuilder
    private var strengthSection: some View {
        if !viewModel.newPassword.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Password Strength")
                        .font(.caption)
                        .foregroundColor(Color.theme.textSecondary)
                    Spacer()
                    Text(strength.label)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(strength.color)
                }

                // Bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.theme.surfaceLight)
                            .frame(height: 6)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(strength.color)
                            .frame(width: geo.size.width * strength.fraction, height: 6)
                            .animation(.easeInOut(duration: 0.3), value: strength.fraction)
                    }
                }
                .frame(height: 6)

                // Tips
                if strength.tips.count > 0 {
                    VStack(alignment: .leading, spacing: 3) {
                        ForEach(strength.tips, id: \.self) { tip in
                            HStack(spacing: 5) {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 4))
                                    .foregroundColor(Color.theme.textTertiary)
                                Text(tip)
                                    .font(.caption)
                                    .foregroundColor(Color.theme.textSecondary)
                            }
                        }
                    }
                }
            }
            .padding(14)
            .background(Color.theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.theme.border, lineWidth: 0.5)
            )
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    // MARK: - Error

    @ViewBuilder
    private var errorSection: some View {
        if let error = viewModel.passwordErrorMessage {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(Color.theme.accentRed)
                Text(error)
                    .font(.subheadline)
                    .foregroundColor(Color.theme.accentRed)
                Spacer()
            }
            .padding(14)
            .background(Color.theme.accentRed.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color.theme.accentRed.opacity(0.25), lineWidth: 1)
            )
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    // MARK: - Action Button

    private var actionButton: some View {
        Button {
            Task { await submit() }
        } label: {
            Group {
                if viewModel.isChangingPassword {
                    ProgressView().tint(.white)
                } else {
                    Label("Update Password", systemImage: "lock.fill")
                }
            }
            .primaryButton()
        }
        .disabled(isSubmitDisabled)
        .opacity(isSubmitDisabled ? 0.5 : 1)
        .animation(.easeInOut(duration: 0.2), value: isSubmitDisabled)
    }

    // MARK: - Helpers

    private var confirmMismatch: Bool {
        !viewModel.confirmPassword.isEmpty &&
        !viewModel.newPassword.isEmpty &&
        viewModel.newPassword != viewModel.confirmPassword
    }

    private var isSubmitDisabled: Bool {
        viewModel.isChangingPassword ||
        viewModel.currentPassword.isEmpty ||
        viewModel.newPassword.isEmpty ||
        viewModel.confirmPassword.isEmpty
    }

    private func submit() async {
        focusedField = nil
        withAnimation {
            viewModel.passwordErrorMessage = nil
        }
        if await viewModel.changePassword() {
            dismiss()
        }
    }
}

// MARK: - Password Strength Model

private struct PasswordStrength {
    let password: String

    private var score: Int {
        var s = 0
        if password.count >= 8  { s += 1 }
        if password.count >= 12 { s += 1 }
        if password.range(of: "[A-Z]", options: .regularExpression) != nil { s += 1 }
        if password.range(of: "[0-9]", options: .regularExpression) != nil { s += 1 }
        if password.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil { s += 1 }
        return s
    }

    var fraction: CGFloat {
        CGFloat(min(score, 4)) / 4.0
    }

    var label: String {
        switch score {
        case 0, 1: return "Weak"
        case 2:    return "Fair"
        case 3:    return "Good"
        default:   return "Strong"
        }
    }

    var color: Color {
        switch score {
        case 0, 1: return .red
        case 2:    return .orange
        case 3:    return .yellow
        default:   return .green
        }
    }

    var tips: [String] {
        var t: [String] = []
        if password.count < 8  { t.append("Use at least 8 characters") }
        if password.range(of: "[A-Z]", options: .regularExpression) == nil { t.append("Add uppercase letters") }
        if password.range(of: "[0-9]", options: .regularExpression) == nil { t.append("Include numbers") }
        if password.range(of: "[^A-Za-z0-9]", options: .regularExpression) == nil { t.append("Add special characters (!@#…)") }
        return t
    }
}

