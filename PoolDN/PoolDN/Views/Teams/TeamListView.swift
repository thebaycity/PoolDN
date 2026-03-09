import SwiftUI

struct TeamListView: View {
    @Bindable var appState: AppState
    @State private var viewModel = TeamListViewModel()
    @FocusState private var searchFocused: Bool

    private var isSearchActive: Bool {
        viewModel.searchQuery.trimmingCharacters(in: CharacterSet.whitespaces).count >= 2
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                searchBar
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 12)

                if isSearchActive {
                    searchResultsContent
                } else {
                    myTeamsSection
                    allTeamsSection
                }
            }
            .padding(.bottom, 32)
        }
        .background(Color.theme.background)
        .navigationTitle("Teams")
        .navigationBarTitleDisplayMode(.large)
        .navigationDestination(for: String.self) { id in
            TeamDetailView(teamId: id, appState: appState)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink {
                    CreateTeamView(appState: appState)
                } label: {
                    Label("New Team", systemImage: "plus.circle.fill")
                        .labelStyle(.titleAndIcon)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                }
            }
        }
        .overlay {
            if viewModel.isLoading && viewModel.myTeams.isEmpty && viewModel.allTeams.isEmpty {
                LoadingView()
            }
        }
        .refreshable {
            if let pid = appState.currentUser?.id {
                await viewModel.load(playerId: pid)
            }
        }
        .task {
            if let pid = appState.currentUser?.id {
                await viewModel.load(playerId: pid)
            }
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.subheadline)
                .foregroundColor(viewModel.searchQuery.isEmpty ? Color.theme.textTertiary : Color.theme.accent)

            TextField("Search teams by name or city...", text: $viewModel.searchQuery)
                .font(.subheadline)
                .foregroundColor(Color.theme.textPrimary)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .focused($searchFocused)
                .onChange(of: viewModel.searchQuery) { _, new in
                    viewModel.onQueryChanged(new)
                }

            if !viewModel.searchQuery.isEmpty {
                Button { viewModel.clearSearch() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.subheadline)
                        .foregroundColor(Color.theme.textTertiary)
                }
                .buttonStyle(.plain)
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

    // MARK: - My Teams Section

    @ViewBuilder
    private var myTeamsSection: some View {
        if viewModel.myTeams.isEmpty && !viewModel.isLoading {
            emptyMyTeams
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
        } else if !viewModel.myTeams.isEmpty {
            VStack(spacing: 10) {
                // Section header
                HStack {
                    Text("MY TEAMS")
                        .sectionHeader()
                    Spacer()
                    Text("\(viewModel.myTeams.count)")
                        .font(.caption.weight(.bold))
                        .foregroundColor(Color.theme.textTertiary)
                }
                .padding(.horizontal, 16)

                // Team cards
                ForEach(viewModel.myTeams) { team in
                    NavigationLink(value: team.id) {
                        TeamRow(team: team, currentPlayerId: appState.currentUser?.id, compact: true)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 16)
                }
            }
            .padding(.bottom, 20)
        }
    }

    // MARK: - All Teams Section

    private var allTeamsSection: some View {
        VStack(spacing: 10) {
            // Section header
            HStack {
                Text("ALL TEAMS")
                    .sectionHeader()
                Spacer()
                if !viewModel.allTeams.isEmpty {
                    Text("\(viewModel.allTeams.count)\(viewModel.hasMore ? "+" : "")")
                        .font(.caption.weight(.bold))
                        .foregroundColor(Color.theme.textTertiary)
                }
            }
            .padding(.horizontal, 16)

            if viewModel.allTeams.isEmpty && !viewModel.isLoading {
                Text("No teams found")
                    .font(.subheadline)
                    .foregroundColor(Color.theme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 40)
            } else {
                ForEach(viewModel.allTeams) { team in
                    NavigationLink(value: team.id) {
                        TeamRow(team: team, currentPlayerId: appState.currentUser?.id)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 16)
                    .onAppear {
                        if team.id == viewModel.allTeams.last?.id {
                            Task { await viewModel.loadMore() }
                        }
                    }
                }

                if viewModel.isLoadingMore {
                    ProgressView().frame(maxWidth: .infinity).padding()
                }
            }
        }
    }

    // MARK: - Search Results

    @ViewBuilder
    private var searchResultsContent: some View {
        if viewModel.isSearching {
            VStack(spacing: 14) {
                Spacer()
                ProgressView().scaleEffect(1.2).tint(Color.theme.accent)
                Text("Searching...").font(.subheadline).foregroundColor(Color.theme.textSecondary)
                Spacer()
            }
            .frame(maxWidth: .infinity, minHeight: 200)
        } else if viewModel.searchResults.isEmpty {
            VStack(spacing: 16) {
                Spacer()
                ZStack {
                    Circle().fill(Color.theme.surfaceLight).frame(width: 72, height: 72)
                    Image(systemName: "person.3").font(.system(size: 28)).foregroundColor(Color.theme.textSecondary)
                }
                Text("No Teams Found")
                    .font(.headline).foregroundColor(Color.theme.textPrimary)
                Text("Try a different name or city.")
                    .font(.subheadline).foregroundColor(Color.theme.textSecondary)
                Spacer()
            }
            .frame(maxWidth: .infinity, minHeight: 200)
        } else {
            VStack(spacing: 10) {
                HStack {
                    Text("\(viewModel.searchResults.count) result\(viewModel.searchResults.count == 1 ? "" : "s")")
                        .font(.caption).foregroundColor(Color.theme.textTertiary)
                    Spacer()
                }
                .padding(.horizontal, 16)

                ForEach(viewModel.searchResults) { team in
                    NavigationLink(value: team.id) {
                        TeamRow(team: team, currentPlayerId: appState.currentUser?.id)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 16)
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyMyTeams: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 40)
            ZStack {
                Circle()
                    .fill(Color.theme.accent.opacity(0.08))
                    .frame(width: 80, height: 80)
                Image(systemName: "person.3")
                    .font(.system(size: 30))
                    .foregroundColor(Color.theme.accent.opacity(0.5))
            }
            VStack(spacing: 6) {
                Text("No Teams Yet")
                    .font(.headline)
                    .foregroundColor(Color.theme.textPrimary)
                Text("Create a team or accept an invitation\nto get started.")
                    .font(.subheadline)
                    .foregroundColor(Color.theme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            NavigationLink {
                CreateTeamView(appState: appState)
            } label: {
                Label("Create a Team", systemImage: "plus.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.theme.accent)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            Spacer(minLength: 40)
        }
        .frame(maxWidth: .infinity)
    }
}
