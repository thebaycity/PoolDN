import SwiftUI

struct TeamListView: View {
    @Bindable var appState: AppState
    @State private var viewModel = TeamListViewModel()
    @State private var selectedFilter = 0

    private let filters = ["My Teams", "All Teams"]

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                // Capsule tab bar
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(filters.enumerated()), id: \.offset) { index, title in
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedFilter = index
                                }
                            } label: {
                                Text(title)
                                    .font(.subheadline)
                                    .fontWeight(selectedFilter == index ? .semibold : .regular)
                                    .foregroundColor(selectedFilter == index ? .white : Color.theme.textSecondary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(selectedFilter == index ? Color.theme.accent : Color.theme.surfaceLight)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                if selectedFilter == 0 {
                    // My Teams
                    VStack(alignment: .leading, spacing: 10) {
                        if viewModel.myTeams.isEmpty && !viewModel.isLoading {
                            HStack(spacing: 8) {
                                Image(systemName: "person.3")
                                    .foregroundColor(Color.theme.textTertiary)
                                Text("You're not on any teams yet")
                                    .font(.subheadline)
                                    .foregroundColor(Color.theme.textSecondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(14)
                            .background(Color.theme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .strokeBorder(Color.theme.border, lineWidth: 0.5)
                            )
                        } else {
                            ForEach(viewModel.myTeams) { team in
                                NavigationLink(value: team.id) {
                                    TeamRow(team: team, currentPlayerId: appState.currentUser?.id)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                } else {
                    // All Teams
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(viewModel.allTeams) { team in
                            NavigationLink(value: team.id) {
                                TeamRow(team: team, currentPlayerId: appState.currentUser?.id)
                            }
                            .onAppear {
                                if team.id == viewModel.allTeams.last?.id {
                                    Task { await viewModel.loadMore() }
                                }
                            }
                        }

                        if viewModel.isLoadingMore {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .background(Color.theme.background)
        .navigationTitle("Teams")
        .navigationDestination(for: String.self) { id in
            TeamDetailView(teamId: id, appState: appState)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink {
                    CreateTeamView(appState: appState)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(Color.accentColor)
                        .font(.title3)
                }
            }
        }
        .overlay {
            if viewModel.isLoading && viewModel.myTeams.isEmpty {
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
}
