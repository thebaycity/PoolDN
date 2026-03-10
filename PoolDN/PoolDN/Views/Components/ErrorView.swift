import SwiftUI

struct ErrorView: View {
    let message: String
    var retryAction: (() -> Void)?

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.theme.accentRed.opacity(0.12))
                    .frame(width: 72, height: 72)
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(Color.theme.accentRed)
            }

            VStack(spacing: 8) {
                Text("Something went wrong")
                    .font(.headline)
                    .foregroundColor(Color.theme.textPrimary)
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(Color.theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }

            if let retry = retryAction {
                Button(action: retry) {
                    Text("Try Again")
                        .secondaryButton()
                }
                .frame(width: 160)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
