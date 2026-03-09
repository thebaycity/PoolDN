import SwiftUI

struct UserProfileView: View {
    let userId: String
    @State private var viewModel = UserProfileViewModel()

    var body: some View {
        ScrollView {
            if let user = viewModel.user {
                VStack(spacing: 16) {
                    // Avatar & Name
                    VStack(spacing: 14) {
                        AvatarView(
                            avatarUrl: user.avatarUrl,
                            name: user.name,
                            size: 88
                        )

                        VStack(spacing: 4) {
                            Text(user.name)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(Color.theme.textPrimary)
                            if let nickname = user.nickname {
                                Text("@\(nickname)")
                                    .font(.subheadline)
                                    .foregroundColor(Color.theme.accent)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .cardStyle()

                    // Stats
                    if let stats = viewModel.stats {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Statistics")
                                .sectionHeader()

                            HStack(spacing: 0) {
                                statBox("Matches", "\(stats.totalMatches)", icon: "sportscourt", color: Color.theme.textPrimary)
                                divider
                                statBox("Wins", "\(stats.wins)", icon: "trophy.fill", color: Color.theme.accentGreen)
                                divider
                                statBox("Losses", "\(stats.losses)", icon: "xmark.circle", color: Color.theme.accentRed)
                                divider
                                statBox("Teams", "\(stats.teamsCount)", icon: "person.3", color: Color.theme.accent)
                            }
                        }
                        .cardStyle()
                    }

                    // Teams
                    if !viewModel.teams.isEmpty {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Teams")
                                .sectionHeader()

                            Divider().overlay(Color.theme.separator)

                            ForEach(viewModel.teams) { team in
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.theme.accent.opacity(0.15))
                                            .frame(width: 36, height: 36)
                                        Text(String(team.name.prefix(2)).uppercased())
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(Color.theme.accent)
                                    }

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(team.name)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(Color.theme.textPrimary)
                                        if let city = team.city {
                                            Text(city)
                                                .font(.caption)
                                                .foregroundColor(Color.theme.textSecondary)
                                        }
                                    }

                                    Spacer()
                                }
                            }
                        }
                        .cardStyle()
                    }
                }
                .padding()
            } else if viewModel.isLoading {
                LoadingView()
            } else if let error = viewModel.errorMessage {
                ErrorView(message: error) {
                    Task { await viewModel.load(userId) }
                }
            }
        }
        .background(Color.theme.background)
        .navigationTitle(viewModel.user?.name ?? "User")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.load(userId)
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.theme.separator)
            .frame(width: 1, height: 32)
    }

    private func statBox(_ label: String, _ value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(label)
                .font(.caption2)
                .foregroundColor(Color.theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}
