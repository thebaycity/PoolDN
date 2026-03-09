import SwiftUI

/// Full-screen player directory with live search.
/// Can be used standalone (as a tab or pushed view) or embedded.
struct PlayerDirectoryView: View {
    var appState: AppState? = nil
    /// When set, shows an action button on each row instead of navigation.
    var onSelect: ((User) -> Void)? = nil
    /// IDs that are already added — shown with a checkmark.
    var disabledIds: Set<String> = []

    @State private var viewModel = PlayerDirectoryViewModel()
    @FocusState private var searchFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            searchBar
            Divider().overlay(Color.theme.separator)
            contentArea
        }
        .background(Color.theme.background)
        .navigationTitle("Players")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { viewModel.clear() }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.subheadline)
                    .foregroundColor(viewModel.query.isEmpty ? Color.theme.textTertiary : Color.theme.accent)

                TextField("Search by name, nickname or email…", text: $viewModel.query)
                    .font(.subheadline)
                    .foregroundColor(Color.theme.textPrimary)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .focused($searchFocused)
                    .onChange(of: viewModel.query) { _, new in
                        viewModel.onQueryChanged(new)
                    }

                if !viewModel.query.isEmpty {
                    Button {
                        viewModel.clear()
                    } label: {
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
                        searchFocused ? Color.theme.accent.opacity(0.5) : Color.theme.border,
                        lineWidth: searchFocused ? 1.5 : 0.5
                    )
                    .animation(.easeInOut(duration: 0.2), value: searchFocused)
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.theme.background)
    }

    // MARK: - Content

    @ViewBuilder
    private var contentArea: some View {
        if viewModel.query.trimmingCharacters(in: .whitespaces).count < 2 {
            promptState
        } else if viewModel.isSearching {
            loadingState
        } else if viewModel.results.isEmpty {
            emptyState
        } else {
            resultsList
        }
    }

    private var promptState: some View {
        VStack(spacing: 16) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Color.theme.accent.opacity(0.08))
                    .frame(width: 80, height: 80)
                Image(systemName: "person.2.fill")
                    .font(.system(size: 30))
                    .foregroundColor(Color.theme.accent.opacity(0.5))
            }
            VStack(spacing: 6) {
                Text("Find Players")
                    .font(.headline)
                    .foregroundColor(Color.theme.textPrimary)
                Text("Type at least 2 characters to search\nby name, nickname, or email.")
                    .font(.subheadline)
                    .foregroundColor(Color.theme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var loadingState: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView()
                .scaleEffect(1.3)
                .tint(Color.theme.accent)
            Text("Searching…")
                .font(.subheadline)
                .foregroundColor(Color.theme.textSecondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Color.theme.surfaceLight)
                    .frame(width: 80, height: 80)
                Image(systemName: "person.fill.questionmark")
                    .font(.system(size: 30))
                    .foregroundColor(Color.theme.textSecondary)
            }
            VStack(spacing: 6) {
                Text("No Players Found")
                    .font(.headline)
                    .foregroundColor(Color.theme.textPrimary)
                Text("No results for \"\(viewModel.query)\"")
                    .font(.subheadline)
                    .foregroundColor(Color.theme.textSecondary)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var resultsList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // Result count header
                HStack {
                    Text("\(viewModel.results.count) result\(viewModel.results.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(Color.theme.textTertiary)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

                ForEach(viewModel.results) { user in
                    rowFor(user: user)
                    if user.id != viewModel.results.last?.id {
                        Divider()
                            .overlay(Color.theme.separator)
                            .padding(.leading, 72)
                    }
                }
            }
            .background(Color.theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.theme.border, lineWidth: 0.5)
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
    }

    @ViewBuilder
    private func rowFor(user: User) -> some View {
        if let onSelect {
            // Action mode (inline button)
            PlayerRowView(
                user: user,
                action: { onSelect(user) },
                actionLabel: "Invite",
                actionIcon: "paperplane.fill",
                actionDone: disabledIds.contains(user.id),
                currentUserId: appState?.currentUser?.id
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 2)
        } else {
            // Navigation mode (tap row to see profile)
            NavigationLink {
                UserProfileView(userId: user.id)
            } label: {
                PlayerRowView(
                    user: user,
                    currentUserId: appState?.currentUser?.id
                )
                .padding(.horizontal, 16)
                .padding(.vertical, 2)
            }
            .buttonStyle(.plain)
        }
    }
}


