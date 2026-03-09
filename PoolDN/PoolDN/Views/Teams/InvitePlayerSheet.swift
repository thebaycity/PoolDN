import SwiftUI

private struct RoleFilter: Identifiable {
    let id: String        // used as filter value ("player", "organizer") or "all"
    let label: String
    let icon: String
    var roleValue: String? { id == "all" ? nil : id }
}

struct InvitePlayerSheet: View {
    @Bindable var viewModel: TeamDetailViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var searchVM = PlayerDirectoryViewModel()
    @State private var invitedIds: Set<String> = []
    @State private var toastMessage: String? = nil
    @State private var toastIsError = false
    @FocusState private var searchFocused: Bool

    private let roleFilters: [RoleFilter] = [
        RoleFilter(id: "all",       label: "All",        icon: "person.2.fill"),
        RoleFilter(id: "player",    label: "Players",    icon: "figure.pool.swim"),
        RoleFilter(id: "organizer", label: "Organizers", icon: "star.circle.fill"),
    ]

    private var existingMemberIds: Set<String> {
        let members = viewModel.team?.members ?? []
        return Set(members.map { (m: TeamMember) in m.playerId })
    }

    private var isActive: Bool {
        searchVM.query.trimmingCharacters(in: CharacterSet.whitespaces).count >= 2
            || searchVM.selectedRole != nil
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // ── Search bar ────────────────────────────────
                searchBar
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 8)

                // ── Role filter chips ─────────────────────────
                roleChipsRow
                    .padding(.bottom, 10)

                Divider().overlay(Color.theme.separator)

                // ── Content ───────────────────────────────────
                contentArea
            }
            .background(Color.theme.background)
            .navigationTitle("Invite Players")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                if !invitedIds.isEmpty {
                    ToolbarItem(placement: .primaryAction) {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color.theme.accentGreen)
                            Text("\(invitedIds.count) sent")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(Color.theme.accentGreen)
                        }
                    }
                }
            }
            .overlay(alignment: .bottom) {
                if let msg = toastMessage {
                    toastBanner(msg, isError: toastIsError)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, 16)
                }
            }
            .animation(.spring(response: 0.32, dampingFraction: 0.78), value: toastMessage)
            .task {
                // Browse all players on open
                searchVM.onRoleChanged(nil as String?)
            }
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.subheadline)
                .foregroundColor(searchVM.query.isEmpty
                                 ? Color.theme.textTertiary
                                 : Color.theme.accent)

            TextField("Name, nickname or email…", text: $searchVM.query)
                .font(.subheadline)
                .foregroundColor(Color.theme.textPrimary)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .focused($searchFocused)
                .onChange(of: searchVM.query) { _, new in
                    searchVM.onQueryChanged(new)
                }

            if !searchVM.query.isEmpty {
                Button { searchVM.onQueryChanged("") } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.subheadline)
                        .foregroundColor(Color.theme.textTertiary)
                }
                .buttonStyle(.plain)
                .transition(.opacity)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.theme.surfaceLight)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(
                    searchFocused ? Color.theme.accent.opacity(0.55) : Color.theme.border,
                    lineWidth: searchFocused ? 1.5 : 0.5
                )
                .animation(.easeInOut(duration: 0.18), value: searchFocused)
        )
    }

    // MARK: - Role Chips

    private var roleChipsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(roleFilters) { filter in
                    let selected = searchVM.selectedRole == filter.roleValue
                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            searchVM.onRoleChanged(selected ? nil as String? : filter.roleValue)
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: filter.icon)
                                .font(.caption2)
                            Text(filter.label)
                                .font(.caption.weight(selected ? .semibold : .regular))
                        }
                        .foregroundColor(selected ? .white : Color.theme.textSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(selected ? Color.theme.accent : Color.theme.surfaceLight)
                        .clipShape(Capsule())
                        .overlay(Capsule().strokeBorder(
                            selected ? Color.clear : Color.theme.border,
                            lineWidth: 0.5))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var contentArea: some View {
        if searchVM.isSearching {
            loadingView
        } else if searchVM.results.isEmpty && isActive {
            emptyView
        } else {
            playerList
        }
    }

    private var loadingView: some View {
        VStack(spacing: 14) {
            Spacer()
            ProgressView().scaleEffect(1.2).tint(Color.theme.accent)
            Text("Finding players…")
                .font(.subheadline)
                .foregroundColor(Color.theme.textSecondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var emptyView: some View {
        VStack(spacing: 20) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Color.theme.surfaceLight)
                    .frame(width: 72, height: 72)
                Image(systemName: "person.fill.questionmark")
                    .font(.system(size: 28))
                    .foregroundColor(Color.theme.textSecondary)
            }
            VStack(spacing: 6) {
                Text("No Players Found")
                    .font(.headline)
                    .foregroundColor(Color.theme.textPrimary)
                Text("Try a different name or nickname.")
                    .font(.subheadline)
                    .foregroundColor(Color.theme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            // Fallback: invite by raw email
            if searchVM.query.contains("@") {
                Button {
                    Task { await invite(email: searchVM.query, userId: nil) }
                } label: {
                    Label("Invite \(searchVM.query)", systemImage: "paperplane.fill")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.theme.accent)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
    }

    private var playerList: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: []) {
                // Header count
                if !searchVM.results.isEmpty {
                    HStack {
                        Text(headerLabel)
                            .font(.caption)
                            .foregroundColor(Color.theme.textTertiary)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 4)
                }

                ForEach(searchVM.results) { user in
                    let isMember  = existingMemberIds.contains(user.id)
                    let isInvited = invitedIds.contains(user.id)

                    playerRow(user: user, isMember: isMember, isInvited: isInvited)

                    if user.id != searchVM.results.last?.id {
                        Divider()
                            .overlay(Color.theme.separator)
                            .padding(.leading, 72)
                    }
                }

                // Email-invite fallback at the bottom when searching
                if !searchVM.query.isEmpty && searchVM.query.contains("@") {
                    emailInviteFooter
                }

                Spacer().frame(height: 80) // space for toast
            }
            .background(Color.theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.theme.border, lineWidth: 0.5)
            )
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 16)
        }
    }

    @ViewBuilder
    private func playerRow(user: User, isMember: Bool, isInvited: Bool) -> some View {
        HStack(spacing: 12) {
            AvatarView(avatarUrl: user.avatarUrl, name: user.name, size: 44)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(user.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Color.theme.textPrimary)
                        .lineLimit(1)

                    if isMember {
                        Text("Member")
                            .font(.caption2.weight(.bold))
                            .foregroundColor(Color.theme.accentGreen)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color.theme.accentGreen.opacity(0.12))
                            .clipShape(Capsule())
                    }

                    if user.role == "organizer" {
                        Image(systemName: "star.circle.fill")
                            .font(.caption2)
                            .foregroundColor(Color.theme.accentYellow)
                    }
                }

                if let nick = user.nickname {
                    Text("@\(nick)")
                        .font(.caption)
                        .foregroundColor(Color.theme.accent)
                }

                Text(user.email)
                    .font(.caption)
                    .foregroundColor(Color.theme.textSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 4)

            // Action button
            if isMember {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(Color.theme.accentGreen)
            } else if isInvited {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(Color.theme.accent)
            } else {
                Button {
                    Task { await invite(email: user.email, userId: user.id) }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "paperplane.fill")
                            .font(.caption.bold())
                        Text("Invite")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Color.theme.accent)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var emailInviteFooter: some View {
        Button {
            Task { await invite(email: searchVM.query, userId: nil) }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "envelope.badge.fill")
                    .foregroundColor(Color.theme.accent)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Invite by email")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(Color.theme.textPrimary)
                    Text(searchVM.query)
                        .font(.caption)
                        .foregroundColor(Color.theme.textSecondary)
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundColor(Color.theme.textTertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private var headerLabel: String {
        let count = searchVM.results.count
        let suffix = count == 1 ? "player" : "players"
        if !searchVM.query.isEmpty {
            return "\(count) \(suffix) matching \"\(searchVM.query)\""
        } else if let role = searchVM.selectedRole {
            return "\(count) \(role)\(count == 1 ? "" : "s")"
        }
        return "\(count) \(suffix)"
    }

    // MARK: - Toast

    private func toastBanner(_ message: String, isError: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: isError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                .foregroundColor(isError ? Color.theme.accentRed : Color.theme.accentGreen)
            Text(message)
                .font(.subheadline.weight(.medium))
                .foregroundColor(Color.theme.textPrimary)
            Spacer()
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .background(Color.theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.14), radius: 14, y: 4)
        .padding(.horizontal, 16)
    }

    // MARK: - Invite action

    private func invite(email: String, userId: String?) async {
        await viewModel.invitePlayer(email: email)
        if let error = viewModel.errorMessage {
            viewModel.errorMessage = nil
            showToast(error, isError: true)
        } else {
            if let uid = userId { invitedIds.insert(uid) }
            let name = email.components(separatedBy: "@").first ?? email
            showToast("Invitation sent to \(name)!", isError: false)
        }
    }

    private func showToast(_ message: String, isError: Bool) {
        withAnimation { toastMessage = message; toastIsError = isError }
        Task {
            try? await Task.sleep(nanoseconds: 2_800_000_000)
            withAnimation { toastMessage = nil }
        }
    }
}

