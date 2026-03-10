import SwiftUI

struct CompetitionTeamsTab: View {
    let competition: Competition
    let participations: [TeamParticipation]
    let isOrganizer: Bool
    let hasMoreParticipations: Bool
    let isLoadingMoreParticipations: Bool
    @Bindable var viewModel: CompetitionDetailViewModel
    @Bindable var appState: AppState
    var onLoadMoreParticipations: (() async -> Void)? = nil
    @State private var showApplySheet = false
    @State private var showInviteSheet = false
    @State private var myTeams: [Team] = []
    @State private var selectedTab = 0
    @State private var teamToWithdraw: TeamParticipation?
    @State private var teamToRemove: TeamParticipation?
    @State private var showGenerateConfirmation = false
    @State private var inviteToDecline: TeamParticipation?
    @State private var appToReject: TeamParticipation?
    @State private var appToWithdraw: TeamParticipation?

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

    var myPendingApplications: [TeamParticipation] {
        guard let userId = appState.currentUser?.id else { return [] }
        return pendingTeams.filter { app in
            myTeams.contains(where: { $0.id == app.teamId && $0.captainId == userId })
        }
    }

    private var tabOptions: [(String, Int)] {
        var tabs: [(String, Int)] = [("All", 0), ("Accepted", 1)]
        if isOrganizer {
            if !invitedTeams.isEmpty { tabs.append(("Invited", 2)) }
            if !pendingTeams.isEmpty { tabs.append(("Pending", 3)) }
        } else if !myInvitations.isEmpty {
            tabs.append(("Invited", 2))
        }
        return tabs
    }

    private var showInvitedSection: Bool {
        selectedTab == 0 || selectedTab == 2
    }

    private var showPendingSection: Bool {
        selectedTab == 0 || selectedTab == 3
    }

    private var showAcceptedSection: Bool {
        selectedTab == 0 || selectedTab == 1
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
                            showGenerateConfirmation = true
                        } label: {
                            Text("Close & Generate Matches")
                                .primaryButton()
                        }
                        .disabled(acceptedTeams.count < 2)
                        .confirmationDialog("Generate Matches", isPresented: $showGenerateConfirmation, titleVisibility: .visible) {
                            Button("Close & Generate") {
                                Task { await viewModel.closeAndGenerate() }
                            }
                            Button("Cancel", role: .cancel) {}
                        } message: {
                            Text("This will close applications and generate the match schedule. This action cannot be undone.")
                        }
                    }
                    .cardStyle()
                }

                // Invite team button (organizer)
                if isOrganizer && competition.status == .upcoming {
                    Button {
                        showInviteSheet = true
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

                // Segmented picker
                if tabOptions.count > 2 {
                    Picker("Filter", selection: $selectedTab) {
                        ForEach(tabOptions, id: \.1) { tab in
                            Text(tab.0).tag(tab.1)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // Competition invitations for my teams (captain view)
                if showInvitedSection && !isOrganizer && !myInvitations.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Your Invitations")
                            .sectionHeader()

                        ForEach(myInvitations) { invite in
                            VStack(spacing: 12) {
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

                                        Spacer()

                                        Image(systemName: "chevron.right")
                                            .font(.caption2)
                                            .foregroundColor(Color.theme.textTertiary)
                                    }
                                }
                                .buttonStyle(.plain)

                                Button {
                                    Task { await viewModel.respondToInvitation(teamId: invite.teamId, accept: true) }
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "checkmark")
                                        Text("Accept")
                                    }
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color.theme.accentGreen)
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                }

                                Button {
                                    inviteToDecline = invite
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "xmark")
                                        Text("Decline")
                                    }
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(Color.theme.accentRed)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color.theme.accentRed.opacity(0.12))
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                }
                            }
                            .padding(14)
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
                if showInvitedSection && isOrganizer && !invitedTeams.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Invited")
                            .sectionHeader()

                        ForEach(invitedTeams) { invite in
                            HStack(spacing: 12) {
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
                                    }
                                }
                                .buttonStyle(.plain)

                                Spacer()

                                Button {
                                    teamToWithdraw = invite
                                } label: {
                                    Text("Withdraw")
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
                                    .strokeBorder(Color.theme.border, lineWidth: 0.5)
                            )
                        }
                    }
                }

                // Application Pending status card (player view)
                if showPendingSection && !isOrganizer && !myPendingApplications.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(myPendingApplications) { app in
                            VStack(spacing: 12) {
                                HStack(spacing: 10) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.theme.accentYellow.opacity(0.15))
                                            .frame(width: 40, height: 40)
                                        Image(systemName: "clock")
                                            .font(.subheadline)
                                            .foregroundColor(Color.theme.accentYellow)
                                    }

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Application Pending")
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundColor(Color.theme.textPrimary)
                                        Text("Your team \(app.teamName) has applied. Waiting for organizer approval.")
                                            .font(.caption)
                                            .foregroundColor(Color.theme.textSecondary)
                                    }
                                }

                                Button {
                                    appToWithdraw = app
                                } label: {
                                    Text("Withdraw Application")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(Color.theme.accentRed)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(Color.theme.accentRed.opacity(0.12))
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                }
                            }
                            .padding(14)
                            .background(Color.theme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .strokeBorder(Color.theme.accentYellow.opacity(0.3), lineWidth: 0.5)
                            )
                        }
                    }
                }

                // Pending Applications (organizer view)
                if showPendingSection && isOrganizer && !pendingTeams.isEmpty {
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
                                    Text("Accept")
                                        .font(.caption.weight(.semibold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.theme.accentGreen)
                                        .clipShape(Capsule())
                                }

                                Button {
                                    appToReject = app
                                } label: {
                                    Text("Reject")
                                        .font(.caption.weight(.semibold))
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
                                    .strokeBorder(Color.theme.accentOrange.opacity(0.3), lineWidth: 0.5)
                            )
                        }
                    }
                }

                // Accepted Teams
                if showAcceptedSection {
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

                                        Spacer(minLength: 0)

                                        Image(systemName: "checkmark.seal.fill")
                                            .foregroundColor(Color.theme.accentGreen)
                                            .font(.subheadline)

                                        Image(systemName: "chevron.right")
                                            .font(.caption2)
                                            .foregroundColor(Color.theme.textTertiary)
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.plain)
                                .padding(12)
                                .background(Color.theme.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .strokeBorder(Color.theme.border, lineWidth: 0.5)
                                )
                                .contextMenu {
                                    if isOrganizer && (competition.status == .upcoming || competition.status == .active) {
                                        Button(role: .destructive) {
                                            teamToRemove = team
                                        } label: {
                                            Label("Remove Team", systemImage: "trash")
                                        }
                                    }
                                }
                                .onAppear {
                                    if team.id == acceptedTeams.last?.id, hasMoreParticipations {
                                        Task { await onLoadMoreParticipations?() }
                                    }
                                }
                            }
                        }
                    }
                }

                // Participations load-more footer
                if isLoadingMoreParticipations {
                    HStack(spacing: 10) {
                        ProgressView().scaleEffect(0.85).tint(Color.theme.accent)
                        Text("Loading more teams...")
                            .font(.caption)
                            .foregroundColor(Color.theme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                } else if hasMoreParticipations {
                    Button {
                        Task { await onLoadMoreParticipations?() }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.down.circle")
                            Text("Load More Teams")
                        }
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(Color.theme.accent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.theme.surfaceLight)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
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
            InviteTeamSheet(
                competition: competition,
                participations: participations,
                onInvite: { teamId in
                    await viewModel.inviteTeam(teamId: teamId)
                },
                onDismiss: { showInviteSheet = false }
            )
            .presentationDetents([.large])
        }
        .confirmationDialog(
            "Withdraw Invitation",
            isPresented: Binding(
                get: { teamToWithdraw != nil },
                set: { if !$0 { teamToWithdraw = nil } }
            ),
            titleVisibility: .visible
        ) {
            if let team = teamToWithdraw {
                Button("Withdraw Invitation", role: .destructive) {
                    Task { await viewModel.withdrawInvitation(teamId: team.teamId) }
                }
            }
        } message: {
            if let team = teamToWithdraw {
                Text("Withdraw the invitation for \(team.teamName)? They will be able to be invited again.")
            }
        }
        .confirmationDialog(
            "Remove Team",
            isPresented: Binding(
                get: { teamToRemove != nil },
                set: { if !$0 { teamToRemove = nil } }
            ),
            titleVisibility: .visible
        ) {
            if let team = teamToRemove {
                Button("Remove Team", role: .destructive) {
                    Task { await viewModel.removeTeam(teamId: team.teamId) }
                }
            }
        } message: {
            if let team = teamToRemove {
                Text("Remove \(team.teamName) from this competition? This action cannot be undone.")
            }
        }
        .confirmationDialog(
            "Decline Invitation?",
            isPresented: Binding(
                get: { inviteToDecline != nil },
                set: { if !$0 { inviteToDecline = nil } }
            ),
            titleVisibility: .visible
        ) {
            if let invite = inviteToDecline {
                Button("Decline", role: .destructive) {
                    Task { await viewModel.respondToInvitation(teamId: invite.teamId, accept: false) }
                }
            }
        } message: {
            Text("Are you sure you want to decline this competition invitation?")
        }
        .confirmationDialog(
            "Reject Application?",
            isPresented: Binding(
                get: { appToReject != nil },
                set: { if !$0 { appToReject = nil } }
            ),
            titleVisibility: .visible
        ) {
            if let app = appToReject {
                Button("Reject", role: .destructive) {
                    Task { await viewModel.handleApplication(teamId: app.teamId, accept: false) }
                }
            }
        } message: {
            if let app = appToReject {
                Text("Reject the application from \(app.teamName)?")
            }
        }
        .confirmationDialog(
            "Withdraw Application?",
            isPresented: Binding(
                get: { appToWithdraw != nil },
                set: { if !$0 { appToWithdraw = nil } }
            ),
            titleVisibility: .visible
        ) {
            if let app = appToWithdraw {
                Button("Withdraw", role: .destructive) {
                    Task { await viewModel.withdrawApplication(teamId: app.teamId) }
                }
            }
        } message: {
            if let app = appToWithdraw {
                Text("Withdraw the application for \(app.teamName)? You can re-apply later.")
            }
        }
    }
}
