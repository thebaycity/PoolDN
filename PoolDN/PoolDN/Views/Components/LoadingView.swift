import SwiftUI

struct LoadingView: View {
    var message = "Loading..."

    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .controlSize(.large)
                .tint(Color.theme.accent)
            Text(message)
                .font(.subheadline)
                .foregroundColor(Color.theme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.theme.background)
    }
}
