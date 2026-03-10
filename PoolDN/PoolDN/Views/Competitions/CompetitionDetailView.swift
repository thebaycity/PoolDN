import SwiftUI

struct CompetitionDetailView: View {
    let competitionId: String
    @Bindable var appState: AppState
    @State private var viewModel = CompetitionDetailViewModel()
    @State private var selectedTab = 0

    var isOrganizer: Bool {
        viewModel.competition?.organizerId == appState.currentUser?.id
    }

    private var tabs: [(String, String)] {
        var items: [(String, String)] = [
            ("About", "info.circle"),
            ("Teams", "person.3"),
        ]
        if let comp = viewModel.competition,
           comp.status == .active || comp.status == .completed {
            items.append(("Matches", "sportscourt"))
            items.append(("Standings", "list.number"))
            items.append(("Players", "person.text.rectangle"))
        }
        return items
    }

    var body: some View {
        VStack(spacing: 0) {
            if let comp = viewModel.competition {
                // Custom Tab Bar
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(Array(tabs.enumerated()), id: \.offset) { index, tab in
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedTab = index
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: tab.1)
                                        .font(.caption)
                                    Text(tab.0)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(selectedTab == index ? .white : Color.theme.textSecondary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    selectedTab == index
                                        ? AnyShapeStyle(Color.accentColor)
                                        : AnyShapeStyle(Color.theme.surfaceLight)
                                )
                                .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                }
                .background(Color.theme.surface)

                Divider().overlay(Color.theme.separator)

                switch selectedTab {
                case 0:
                    CompetitionAboutTab(competition: comp, isOrganizer: isOrganizer, viewModel: viewModel, appState: appState)
                case 1:
                    CompetitionTeamsTab(
                        competition: comp,
                        participations: viewModel.participations,
                        isOrganizer: isOrganizer,
                        hasMoreParticipations: viewModel.hasMoreParticipations,
                        isLoadingMoreParticipations: viewModel.isLoadingMoreParticipations,
                        viewModel: viewModel,
                        appState: appState,
                        onLoadMoreParticipations: { await viewModel.loadMoreParticipations() }
                    )
                case 2:
                    CompetitionMatchesTab(
                        competitionId: comp.id,
                        matches: viewModel.matches,
                        hasMore: viewModel.hasMoreMatches,
                        isLoadingMore: viewModel.isLoadingMoreMatches,
                        appState: appState,
                        gameStructure: comp.gameStructure,
                        participations: viewModel.participations,
                        onLoadMore: { await viewModel.loadMoreMatches() }
                    )
                case 3:
                    StandingsView(
                        standings: viewModel.standings,
                        currentPlayerTeamIds: viewModel.participations
                            .filter { p in
                                p.roster?.contains(where: { $0.playerId == appState.currentUser?.id }) == true
                            }
                            .map(\.teamId)
                    )
                case 4:
                    CompetitionPlayersTab(
                        playerRatings: viewModel.playerRatings,
                        currentPlayerId: appState.currentUser?.id
                    )
                default:
                    EmptyView()
                }
            } else if viewModel.isLoading {
                LoadingView()
            } else if let error = viewModel.errorMessage {
                ErrorView(message: error) {
                    Task { await viewModel.load(competitionId) }
                }
            }
        }
        .background(Color.theme.background)
        .navigationTitle(viewModel.competition?.name ?? "Competition")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Success", isPresented: .init(
            get: { viewModel.actionMessage != nil },
            set: { if !$0 { viewModel.actionMessage = nil } }
        )) {
            Button("OK") { viewModel.actionMessage = nil }
        } message: {
            Text(viewModel.actionMessage ?? "")
        }
        .task {
            await viewModel.load(competitionId)
        }
    }
}
