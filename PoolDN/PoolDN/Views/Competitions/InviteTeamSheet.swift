import SwiftUI

struct InviteTeamSheet: View {
    let competition: Competition
    let participations: [TeamParticipation]
    let onInvite: (String) async -> Void
    let onDismiss: () -> Void

    @State private var searchText = ""
    @State private var teams: [Team] = []
    @State private var isLoading = true
    @State private var invitingTeamId: String?
    @State private var justInvitedIds: Set<String> = []

    private var filteredTeams: [Team] {
        if searchText.isEmpty { return teams }
        let query = searchText.lowercased()
        return teams.filter {
            $0.name.lowercased().contains(query) ||
            ($0.city?.lowercased().contains(query) ?? false)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.subheadline)
                        .foregroundColor(Color.theme.textTertiary)

                    TextField("Search teams...", text: $searchText)
                        .font(.subheadline)
                        .foregroundColor(Color.theme.textPrimary)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)

                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.subheadline)
                                .foregroundColor(Color.theme.textTertiary)
                        }
                    }
                }
                .padding(12)
                .background(Color.theme.surfaceLight)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 4)

                if isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if filteredTeams.isEmpty {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: searchText.isEmpty ? "person.3" : "magnifyingglass")
                            .font(.title)
                            .foregroundColor(Color.theme.textTertiary)
                        Text(searchText.isEmpty ? "No teams available" : "No teams found")
                            .font(.subheadline)
                            .foregroundColor(Color.theme.textSecondary)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 2) {
                            ForEach(filteredTeams) { team in
                                teamRow(team)
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(Color.theme.border, lineWidth: 0.5)
                        )
                        .padding()
                    }
                }
            }
            .background(Color.theme.background)
            .navigationTitle("Invite Team")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { onDismiss() }
                }
            }
            .task {
                await loadTeams()
            }
        }
    }

    @ViewBuilder
    private func teamRow(_ team: Team) -> some View {
        let participation = participations.first(where: { $0.teamId == team.id })
        let status = participation?.status
        let wasJustInvited = justInvitedIds.contains(team.id)
        let isInviting = invitingTeamId == team.id

        HStack(spacing: 12) {
            // Team avatar
            ZStack {
                Circle()
                    .fill(avatarColor(status: status).opacity(0.15))
                    .frame(width: 40, height: 40)
                Text(teamInitials(team.name))
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(avatarColor(status: status))
            }

            // Team info
            VStack(alignment: .leading, spacing: 3) {
                Text(team.name)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(Color.theme.textPrimary)

                HStack(spacing: 8) {
                    Label("\(team.members.count)", systemImage: "person.2")
                        .font(.caption)
                        .foregroundColor(Color.theme.textSecondary)
                    if let city = team.city {
                        Label(city, systemImage: "mappin")
                            .font(.caption)
                            .foregroundColor(Color.theme.textSecondary)
                    }
                }
            }

            Spacer()

            // Status / Action
            if isInviting {
                ProgressView()
                    .scaleEffect(0.8)
            } else if status == "accepted" {
                Label("Accepted", systemImage: "checkmark.seal.fill")
                    .font(.caption)
                    .foregroundColor(Color.theme.accentGreen)
            } else if status == "invited" || wasJustInvited {
                HStack(spacing: 8) {
                    Text("Invited")
                        .font(.caption)
                        .foregroundColor(Color.theme.accentYellow)

                    Button {
                        invite(team)
                    } label: {
                        Text("Resend")
                            .font(.caption.weight(.medium))
                            .foregroundColor(Color.theme.accent)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.theme.accent.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
            } else if status == "pending" {
                Text("Applied")
                    .font(.caption)
                    .foregroundColor(Color.theme.accentOrange)
            } else if status == "declined" || status == "rejected" {
                HStack(spacing: 8) {
                    Text(status == "declined" ? "Declined" : "Rejected")
                        .font(.caption)
                        .foregroundColor(Color.theme.accentRed)

                    Button {
                        invite(team)
                    } label: {
                        Text("Re-invite")
                            .font(.caption.weight(.medium))
                            .foregroundColor(Color.theme.accent)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.theme.accent.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
            } else {
                Button {
                    invite(team)
                } label: {
                    Text("Invite")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Color.theme.accent)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(14)
        .background(Color.theme.surface)
    }

    private func invite(_ team: Team) {
        invitingTeamId = team.id
        Task {
            await onInvite(team.id)
            justInvitedIds.insert(team.id)
            invitingTeamId = nil
        }
    }

    private func loadTeams() async {
        isLoading = true
        do {
            teams = try await TeamService.listTeams(limit: 200).data
        } catch {}
        isLoading = false
    }

    private func avatarColor(status: String?) -> Color {
        switch status {
        case "accepted": return Color.theme.accentGreen
        case "invited": return Color.theme.accentYellow
        case "pending": return Color.theme.accentOrange
        case "declined", "rejected": return Color.theme.accentRed
        default: return Color.theme.accent
        }
    }

    private func teamInitials(_ name: String) -> String {
        let words = name.split(separator: " ")
        if words.count >= 2 {
            return String(words[0].prefix(1) + words[1].prefix(1)).uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }
}
