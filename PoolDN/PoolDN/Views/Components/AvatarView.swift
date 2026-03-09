import SwiftUI

/// Shared avatar component used across the app.
/// Appends a `?v=` cache-buster so AsyncImage always refetches
/// the latest image after an upload.
struct AvatarView: View {
    let avatarUrl: String?
    let name: String
    let size: CGFloat
    var version: Int = 0
    var roleColor: Color = Color.theme.accent

    private var resolvedURL: URL? {
        guard let path = avatarUrl else { return nil }
        let base = AppConfig.apiBaseURL.replacingOccurrences(of: "/api", with: "")
        return URL(string: "\(base)\(path)?v=\(version)")
    }

    var body: some View {
        Group {
            if let url = resolvedURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        initialsView
                    default:
                        Circle()
                            .fill(roleColor.opacity(0.15))
                    }
                }
            } else {
                initialsView
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }

    private var initialsView: some View {
        ZStack {
            Circle()
                .fill(roleColor.opacity(0.15))
            Text(String(name.prefix(2)).uppercased())
                .font(size > 50 ? .title : .caption)
                .fontWeight(.bold)
                .foregroundColor(roleColor)
        }
    }
}

