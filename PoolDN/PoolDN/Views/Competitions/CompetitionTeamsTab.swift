import SwiftUI

struct CompetitionTeamsTab: View {
    let competition: Competition
    let participations: [TeamParticipation]
    let isOrganizer: Bool
    @Bindable var viewModel: CompetitionDetailViewModel
    @Bindable var appState: AppState
    @State private var showApplySheet = false
    @State private var showInviteSheet = false
    @State private var allTeams: [Team] = []
    @State private var myTeams: [Team] = []

    var acceptedTeams: [TeamParticipation] {
        participations.filter { $0.status == "accepted" }
    }

    var pendingTeams: [TeamParticipation] {
        participations.filter { $0.status == "pending" }
    }

    var invitedTeams: [TeamParticipation] {
        participations.filter { $0.status == "invited" }
    }

    var myInvitations: [TeamParticipation] {
        guard let userId = appState.currentUser?.id else { return [] }
        return invitedTeams.filter { invite in
            myTeams.contains(where: { $0.id == invite.teamId && $0.captainId == userId })
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Organizer CTA
                if isOrganizer && competition.status == .upcoming {
                    VStack(spacing: 14) {
                        Image(systemName: "flag.checkered")
                            .font(.title)
                            .foregroundStyle(Color.accentColor)

                        Text("Ready to start?")
                            .font(.headline)
                            .foregroundColor(Color.theme.textPrimary)

                        Text("\(acceptedTeams.count) team\(acceptedTeams.count == 1 ? "" : "s") accepted")
                            .font(.subheadline)
                            .foregroundColor(Color.theme.textSecondary)

                        Button {
                            Task { await viewModel.closeAndGenerate() }
                        } label: {
                            Text("Close & Generate Matches")
                                .primaryButton()
                        }
                        .disabled(acceptedTeams.count < 2)
                    }
                    .cardStyle()
                }

                // Invite team button (organizer)
                if isOrganizer && competition.status == .upcoming {
                    Button {
                        Task {
                            allTeams = try await TeamService.listTeams(limit: 100).data
                            showInviteSheet = true
                        }
                    } label: {
                        HStack {
                            Image(systemName: "envelope.badge.person.crop")
                            Text("Invite Team")
                        }
                        .secondaryButton()
                    }
                }

                // Apply button
                if !isOrganizer && competition.status == .upcoming {
                    Button {
                        Task {
                            if let pid = appState.currentUser?.id {
                                myTeams = try await TeamService.getPlayerTeams(playerId: pid)
                            }
                            showApplySheet = true
                        }
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Apply with Team")
                        }
                        .secondaryButton()
                    }
                }

                // Competition invitations for my teams (captain view)
                if !isOrganizer && !myInvitations.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Your Invitations")
                            .sectionHeader()

                        ForEach(myInvitations) { invite in
                            HStack(spacing: 12) {
                                NavigationLink {
                                    TeamDetailView(teamId: invite.teamId, appState: appState)
                                } label: {
                                    HStack(spacing: 12) {
                                        ZStack {
                                            Circle()
                                                .fill(Color.theme.accent.opacity(0.15))
                                                .frame(width: 40, height: 40)
                                            Image(systemName: "envelope.open.fill")
                                                .font(.subheadline)
                                                .foregroundColor(Color.theme.accent)
                                        }

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(invite.teamName)
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .foregroundColor(Color.theme.textPrimary)
                                            Text("Invited to join")
                                                .font(.caption)
                                                .foregroundColor(Color.theme.textSecondary)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)

                                Spacer()

                                Button {
                                    Task { await viewModel.respondToInvitation(teamId: invite.teamId, accept: true) }
                                } label: {
                                    Text("Accept")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.theme.accentGreen)
                                        .clipShape(Capsule())
                                }

                                Button {
                                    Task { await viewModel.respondToInvitation(teamId: invite.teamId, accept: false) }
                                } label: {
                                    Text("Decline")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(Color.theme.accentRed)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.theme.accentRed.opacity(0.12))
                                        .clipShape(Capsule())
                                }
                            }
                            .padding(12)
                            .background(Color.theme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .strokeBorder(Color.theme.accent.opacity(0.3), lineWidth: 0.5)
                            )
                        }
                    }
                }

                // Invited teams (organizer view)
                if isOrganizer && !invitedTeams.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Invited")
                            .sectionHeader()

                        ForEach(invitedTeams) { invite in
                            NavigationLink {
                                TeamDetailView(teamId: invite.teamId, appState: appState)
                            } label: {
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.theme.accent.opacity(0.15))
                                            .frame(width: 40, height: 40)
                                        Text(String(invite.teamName.prefix(2)).uppercased())
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(Color.theme.accent)
                                    }

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(invite.teamName)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(Color.theme.textPrimary)
                                        if let roster = invite.roster {
                                            Text("\(roster.count) members")
                                                .font(.caption)
                                                .foregroundColor(Color.theme.textSecondary)
                                        }
                                    }

                                    Spacer()

                                    Text("Awaiting response")
                                        .font(.caption)
                                        .foregroundColor(Color.theme.textSecondary)

                                    Image(systemName: "chevron.right")
                                        .font(.caption2)
                                        .foregroundColor(Color.theme.textTertiary)
                                }
                            }
                            .buttonStyle(.plain)
                            .padding(12)
                            .background(Color.theme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .strokeBorder(Color.theme.border, lineWidth: 0.5)
                            )
                        }
                    }
                }

                // Pending Applications
                if isOrganizer && !pendingTeams.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Pending Applications")
                            .sectionHeader()

                        ForEach(pendingTeams) { app in
                            HStack(spacing: 12) {
                                NavigationLink {
                                    TeamDetailView(teamId: app.teamId, appState: appState)
                                } label: {
                                    HStack(spacing: 12) {
                                        ZStack {
                                            Circle()
                                                .fill(Color.theme.accentOrange.opacity(0.15))
                                                .frame(width: 40, height: 40)
                                            Text(String(app.teamName.prefix(2)).uppercased())
                                                .font(.caption)
                                                .fontWeight(.bold)
                                                .foregroundColor(Color.theme.accentOrange)
                                        }

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(app.teamName)
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .foregroundColor(Color.theme.textPrimary)
                                            if let roster = app.roster {
                                                Text("\(roster.count) members")
                                                    .font(.caption)
                                                    .foregroundColor(Color.theme.textSecondary)
                                            }
                                        }
                                    }
                                }
                                .buttonStyle(.plain)

                                Spacer()

                                Button {
                                    Task { await viewModel.handleApplication(teamId: app.teamId, accept: true) }
                                } label: {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.title3)
                                        .foregroundColor(Color.theme.accentGreen)
                                }

                                Button {
                                    Task { await viewModel.handleApplication(teamId: app.teamId, accept: false) }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.title3)
                                        .foregroundColor(Color.theme.accentRed)
                                }
                            }
                            .padding(12)
                            .background(Color.theme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .strokeBorder(Color.theme.accentOrange.opacity(0.3), lineWidth: 0.5)
                            )
                        }
                    }
                }

                // Accepted Teams
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Accepted")
                            .sectionHeader()
                        Spacer()
                        Text("\(acceptedTeams.count)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(Color.theme.accent)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.theme.accent.opacity(0.12))
                            .clipShape(Capsule())
                    }

                    if acceptedTeams.isEmpty {
                        Text("No teams accepted yet")
                            .font(.subheadline)
                            .foregroundColor(Color.theme.textSecondary)
                            .padding(.vertical, 8)
                    } else {
                        ForEach(acceptedTeams) { team in
                            NavigationLink {
                                TeamDetailView(teamId: team.teamId, appState: appState)
                            } label: {
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.theme.accent.opacity(0.15))
                                            .frame(width: 40, height: 40)
                                        Text(String(team.teamName.prefix(2)).uppercased())
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(Color.theme.accent)
                                    }

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(team.teamName)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(Color.theme.textPrimary)
                                        HStack(spacing: 8) {
                                            if let roster = team.roster {
                                                Label("\(roster.count)", systemImage: "person.2")
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

                                    Spacer()

                                    Image(systemName: "checkmark.seal.fill")
                                        .foregroundColor(Color.theme.accentGreen)
                                        .font(.subheadline)

                                    Image(systemName: "chevron.right")
                                        .font(.caption2)
                                        .foregroundColor(Color.theme.textTertiary)
                                }
                            }
                            .buttonStyle(.plain)
                            .padding(12)
                            .background(Color.theme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .strokeBorder(Color.theme.border, lineWidth: 0.5)
                            )
                        }
                    }
                }
            }
            .padding()
        }
        .sheet(isPresented: $showApplySheet) {
            NavigationStack {
                List {
                    ForEach(myTeams.filter { team in
                        !participations.contains(where: { $0.teamId == team.id })
                    }) { team in
                        Button {
                            Task {
                                await viewModel.apply(teamId: team.id)
                                showApplySheet = false
                            }
                        } label: {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(Color.theme.accent.opacity(0.15))
                                        .frame(width: 36, height: 36)
                                    Text(String(team.name.prefix(2)).uppercased())
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundColor(Color.theme.accent)
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(team.name)
                                        .foregroundColor(Color.theme.textPrimary)
                                    Text("\(team.members.count) members")
                                        .font(.caption)
                                        .foregroundColor(Color.theme.textSecondary)
                                }
                                Spacer()
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .navigationTitle("Select Team")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showApplySheet = false }
                    }
                }
            }
            .presentationDetents([.medium])
        }
        .task {
            if let pid = appState.currentUser?.id {
                myTeams = (try? await TeamService.getPlayerTeams(playerId: pid)) ?? []
            }
        }
        .sheet(isPresented: $showInviteSheet) {
            NavigationStack {
                List {
                    ForEach(allTeams.filter { team in
                        !participations.contains(where: { $0.teamId == team.id })
                    }) { team in
                        Button {
                            Task {
                                await viewModel.inviteTeam(teamId: team.id)
                                showInviteSheet = false
                            }
                        } label: {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(Color.theme.accent.opacity(0.15))
                                        .frame(width: 36, height: 36)
                                    Text(String(team.name.prefix(2)).uppercased())
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundColor(Color.theme.accent)
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(team.name)
                                        .foregroundColor(Color.theme.textPrimary)
                                    HStack(spacing: 8) {
                                        Text("\(team.members.count) members")
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
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .navigationTitle("Invite Team")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showInviteSheet = false }
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }
}
