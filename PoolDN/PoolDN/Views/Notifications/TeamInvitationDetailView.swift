import SwiftUI

struct TeamInvitationDetailView: View {
    let invitation: TeamInvitation
    let onDismiss: () -> Void
    let onRespond: (String, Bool) async -> Void
    @State private var team: Team?
    @State private var isLoadingTeam = true
    @State private var isResponding = false
    @State private var isCompleted = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(Color.theme.accent.opacity(0.15))
                            .frame(width: 56, height: 56)
                        Image(systemName: "person.badge.plus")
                            .font(.title3)
                            .foregroundColor(Color.theme.accent)
                    }
                    .padding(.top, 8)

                    // Title
                    VStack(spacing: 8) {
                        Text("Team Invitation")
                            .font(.title3.weight(.bold))
                            .foregroundColor(Color.theme.textPrimary)

                        Text("You've been invited to join \(invitation.teamName)")
                            .font(.subheadline)
                            .foregroundColor(Color.theme.textSecondary)
                            .multilineTextAlignment(.center)
                    }

                    // Team card
                    if isLoadingTeam {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 24)
                    } else if let team {
                        teamCard(team)
                    }

                    if let error = errorMessage {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.caption)
                            Text(error)
                                .font(.caption)
                        }
                        .foregroundColor(Color.theme.accentRed)
                    }

                    // Action buttons
                    if !isCompleted {
                        HStack(spacing: 12) {
                            Button {
                                respond(accept: false)
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "xmark")
                                    Text("Decline")
                                }
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(Color.theme.accentRed)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.theme.accentRed.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }

                            Button {
                                respond(accept: true)
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "checkmark")
                                    Text("Accept")
                                }
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.theme.accentGreen)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                        }
                        .disabled(isResponding)
                    } else {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Done")
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Color.theme.accentGreen)
                    }

                    Spacer()
                }
                .padding()
            }
            .background(Color.theme.background)
            .navigationTitle("Invitation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { onDismiss() }
                }
            }
            .task {
                await loadTeam()
            }
        }
    }

    private func teamCard(_ team: Team) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            // Team header
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.theme.accent.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Text(teamInitials(team.name))
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(Color.theme.accent)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(team.name)
                        .font(.headline)
                        .foregroundColor(Color.theme.textPrimary)
                    if let city = team.city {
                        Text(city)
                            .font(.caption)
                            .foregroundColor(Color.theme.textSecondary)
                    }
                }

                Spacer()
            }

            if let venue = team.homeVenue {
                HStack(spacing: 8) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.caption)
                        .foregroundColor(Color.theme.textTertiary)
                    Text(venue)
                        .font(.caption)
                        .foregroundColor(Color.theme.textSecondary)
                }
            }

            Divider().overlay(Color.theme.separator)

            // Members
            Text("Members (\(team.members.count))")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(Color.theme.textPrimary)

            ForEach(team.members, id: \.playerId) { member in
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(member.playerId == team.captainId ? Color.theme.accentYellow.opacity(0.15) : Color.theme.surfaceLight)
                            .frame(width: 32, height: 32)
                        Text(memberInitials(member))
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(member.playerId == team.captainId ? Color.theme.accentYellow : Color.theme.textSecondary)
                    }

                    VStack(alignment: .leading, spacing: 1) {
                        Text(member.name ?? member.nickname ?? "Player")
                            .font(.subheadline)
                            .foregroundColor(Color.theme.textPrimary)
                        if member.playerId == team.captainId {
                            Text("Captain")
                                .font(.caption2)
                                .foregroundColor(Color.theme.accentYellow)
                        }
                    }

                    Spacer()
                }
            }
        }
        .cardStyle()
    }

    private func loadTeam() async {
        isLoadingTeam = true
        do {
            team = try await TeamService.getTeam(invitation.teamId)
        } catch {
            errorMessage = "Could not load team details"
        }
        isLoadingTeam = false
    }

    private func respond(accept: Bool) {
        isResponding = true
        errorMessage = nil
        Task {
            await onRespond(invitation.id, accept)
            isCompleted = true
            isResponding = false
            try? await Task.sleep(for: .seconds(1))
            onDismiss()
        }
    }

    private func teamInitials(_ name: String) -> String {
        let words = name.split(separator: " ")
        if words.count >= 2 {
            return String(words[0].prefix(1) + words[1].prefix(1)).uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }

    private func memberInitials(_ member: TeamMember) -> String {
        let name = member.name ?? member.nickname ?? "?"
        let words = name.split(separator: " ")
        if words.count >= 2 {
            return String(words[0].prefix(1) + words[1].prefix(1)).uppercased()
        }
        return String(name.prefix(1)).uppercased()
    }
}
