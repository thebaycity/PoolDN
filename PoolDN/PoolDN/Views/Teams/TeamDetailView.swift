import SwiftUI

struct TeamDetailView: View {
    let teamId: String
    @Bindable var appState: AppState
    @State private var viewModel = TeamDetailViewModel()
    @State private var showInviteSheet = false

    var isCaptain: Bool {
        viewModel.team?.captainId == appState.currentUser?.id
    }

    var body: some View {
        ScrollView {
            if let team = viewModel.team {
                VStack(spacing: 16) {
                    // Team Header
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.theme.accent.opacity(0.15))
                                .frame(width: 72, height: 72)
                            Text(String(team.name.prefix(2)).uppercased())
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(Color.theme.accent)
                        }

                        VStack(spacing: 4) {
                            Text(team.name)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(Color.theme.textPrimary)

                            if isCaptain {
                                HStack(spacing: 4) {
                                    Image(systemName: "star.fill")
                                        .font(.caption2)
                                    Text("Captain")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(Color.theme.accentYellow)
                            }
                        }

                        HStack(spacing: 20) {
                            if let city = team.city {
                                Label(city, systemImage: "mappin")
                                    .font(.caption)
                                    .foregroundColor(Color.theme.textSecondary)
                            }
                            if let venue = team.homeVenue {
                                Label(venue, systemImage: "building.2")
                                    .font(.caption)
                                    .foregroundColor(Color.theme.textSecondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .cardStyle()

                    // Members
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Members")
                                .sectionHeader()
                            Spacer()
                            Text("\(team.members.count)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(Color.theme.accent)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.theme.accent.opacity(0.12))
                                .clipShape(Capsule())

                            if isCaptain {
                                Button {
                                    showInviteSheet = true
                                } label: {
                                    Image(systemName: "person.badge.plus")
                                        .font(.subheadline)
                                        .foregroundColor(Color.theme.accent)
                                }
                            }
                        }

                        ForEach(team.members, id: \.playerId) { member in
                            NavigationLink(value: member.playerId) {
                                HStack(spacing: 12) {
                                    if let avatarUrl = member.avatarUrl,
                                       let url = URL(string: "\(AppConfig.apiBaseURL.replacingOccurrences(of: "/api", with: ""))\(avatarUrl)") {
                                        AsyncImage(url: url) { phase in
                                            switch phase {
                                            case .success(let img):
                                                img.resizable()
                                                    .aspectRatio(contentMode: .fill)
                                                    .frame(width: 40, height: 40)
                                                    .clipShape(Circle())
                                            default:
                                                memberInitials(member)
                                            }
                                        }
                                    } else {
                                        memberInitials(member)
                                    }

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(member.name ?? member.playerId)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(Color.theme.textPrimary)
                                            .lineLimit(1)
                                        if let nickname = member.nickname {
                                            Text("@\(nickname)")
                                                .font(.caption)
                                                .foregroundColor(Color.theme.textSecondary)
                                        }
                                    }

                                    Spacer()

                                    Text(member.role.capitalized)
                                        .font(.caption2)
                                        .fontWeight(.semibold)
                                        .foregroundColor(member.role == "captain" ? Color.theme.accentYellow : Color.theme.textSecondary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(member.role == "captain" ? Color.theme.accentYellow.opacity(0.12) : Color.theme.surfaceLight)
                                        .clipShape(Capsule())

                                    Image(systemName: "chevron.right")
                                        .font(.caption2)
                                        .foregroundColor(Color.theme.textTertiary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .cardStyle()
                }
                .padding()
            } else if viewModel.isLoading {
                LoadingView()
            } else if let error = viewModel.errorMessage {
                ErrorView(message: error) {
                    Task { await viewModel.load(teamId) }
                }
            }
        }
        .background(Color.theme.background)
        .navigationTitle(viewModel.team?.name ?? "Team")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: String.self) { playerId in
            UserProfileView(userId: playerId)
        }
        .sheet(isPresented: $showInviteSheet) {
            InvitePlayerSheet(viewModel: viewModel)
        }
        .task {
            await viewModel.load(teamId)
        }
    }

    private func memberInitials(_ member: TeamMember) -> some View {
        ZStack {
            Circle()
                .fill(member.role == "captain" ? Color.theme.accentYellow.opacity(0.15) : Color.theme.surfaceLight)
                .frame(width: 40, height: 40)
            Text(String((member.name ?? member.playerId).prefix(2)).uppercased())
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(member.role == "captain" ? Color.theme.accentYellow : Color.theme.textSecondary)
        }
    }
}
