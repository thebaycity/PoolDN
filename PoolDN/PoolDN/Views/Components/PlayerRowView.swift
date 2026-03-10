import SwiftUI

/// A single player row used in the directory and invite sheets.
struct PlayerRowView: View {
    let user: User
    var action: (() -> Void)? = nil
    var actionLabel: String = "Invite"
    var actionIcon: String = "paperplane.fill"
    var actionDone: Bool = false
    var currentUserId: String? = nil

    private var isCurrentUser: Bool {
        user.id == currentUserId
    }

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(avatarUrl: user.avatarUrl, name: user.name, size: 44)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(user.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Color.theme.textPrimary)
                        .lineLimit(1)

                    if isCurrentUser {
                        Text("You")
                            .font(.caption2.weight(.bold))
                            .foregroundColor(Color.theme.accent)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.theme.accent.opacity(0.1))
                            .clipShape(Capsule())
                    }

                    if user.role == "organizer" {
                        Image(systemName: "star.circle.fill")
                            .font(.caption2)
                            .foregroundColor(Color.theme.accentYellow)
                    }
                }

                if let nickname = user.nickname {
                    Text("@\(nickname)")
                        .font(.caption)
                        .foregroundColor(Color.theme.accent)
                }

                Text(user.email)
                    .font(.caption)
                    .foregroundColor(Color.theme.textSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 4)

            if let action, !isCurrentUser {
                Button(action: action) {
                    if actionDone {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(Color.theme.accentGreen)
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: actionIcon)
                                .font(.caption.bold())
                            Text(actionLabel)
                                .font(.caption.weight(.semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Color.theme.accent)
                        .clipShape(Capsule())
                    }
                }
                .buttonStyle(.plain)
                .disabled(actionDone)
            }
        }
        .padding(.vertical, 6)
    }
}

