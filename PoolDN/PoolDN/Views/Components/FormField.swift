import SwiftUI

struct FormField: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""
    var isSecure: Bool = false
    var icon: String? = nil
    var onDark: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(onDark ? Color.white.opacity(0.7) : Color.theme.textSecondary)

            HStack(spacing: 10) {
                if let icon {
                    Image(systemName: icon)
                        .font(.subheadline)
                        .foregroundColor(onDark ? Color.white.opacity(0.4) : Color.theme.textTertiary)
                        .frame(width: 20)
                }

                if isSecure {
                    SecureField(placeholder, text: $text)
                        .textFieldStyle(.plain)
                        .foregroundColor(onDark ? .white : Color.theme.textPrimary)
                } else {
                    TextField(placeholder, text: $text)
                        .textFieldStyle(.plain)
                        .foregroundColor(onDark ? .white : Color.theme.textPrimary)
                }
            }
            .padding(.horizontal, 14)
            .frame(height: 48)
            .background(onDark ? Color.white.opacity(0.08) : Color.theme.surfaceLight)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(onDark ? Color.white.opacity(0.12) : Color.theme.border, lineWidth: 0.5)
            )
        }
    }
}
