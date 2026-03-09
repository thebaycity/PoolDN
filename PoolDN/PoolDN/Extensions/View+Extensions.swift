import SwiftUI

extension View {
    func cardStyle() -> some View {
        self
            .padding(16)
            .background(Color.theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.theme.border, lineWidth: 0.5)
            )
    }

    func primaryButton() -> some View {
        self
            .font(.subheadline.weight(.semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.accentColor)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    func secondaryButton() -> some View {
        self
            .font(.subheadline.weight(.semibold))
            .foregroundColor(Color.accentColor)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.accentColor.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.accentColor.opacity(0.25), lineWidth: 1)
            )
    }

    func destructiveButton() -> some View {
        self
            .font(.subheadline.weight(.semibold))
            .foregroundColor(.red)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.red.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    func sectionHeader() -> some View {
        self
            .font(.subheadline.weight(.semibold))
            .foregroundColor(.secondary)
            .textCase(.uppercase)
            .tracking(0.5)
    }

    func goldButton() -> some View {
        self
            .font(.subheadline.weight(.semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                LinearGradient(
                    colors: [Color.theme.goldLight, Color.theme.gold],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
