import SwiftUI

struct CompetitionListView: View {
    @Bindable var appState: AppState
    @State private var viewModel = CompetitionListViewModel()
    @State private var selectedFilter = 0

    private let filters = ["All", "Upcoming", "Active", "Completed"]

    private var filteredCompetitions: [Competition] {
        switch selectedFilter {
        case 1: return viewModel.publicCompetitions.filter { $0.status == .upcoming }
        case 2: return viewModel.publicCompetitions.filter { $0.status == .active }
        case 3: return viewModel.publicCompetitions.filter { $0.status == .completed }
        default: return viewModel.publicCompetitions
        }
    }

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

                // My Competitions (only in "All" filter)
                if selectedFilter == 0 && !viewModel.myCompetitions.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("My Competitions")
                            .sectionHeader()
                            .padding(.horizontal, 4)

                        ForEach(viewModel.myCompetitions) { comp in
                            NavigationLink(value: comp.id) {
                                CompetitionRow(competition: comp)
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                // Filtered competitions
                VStack(alignment: .leading, spacing: 10) {
                    if selectedFilter == 0 {
                        Text("All Competitions")
                            .sectionHeader()
                            .padding(.horizontal, 4)
                    }

                    if filteredCompetitions.isEmpty && !viewModel.isLoading {
                        EmptyStateView(
                            icon: "trophy",
                            title: "No Competitions",
                            message: selectedFilter == 0 ? "Be the first to create one!" : "No \(filters[selectedFilter].lowercased()) competitions"
                        )
                    } else {
                        ForEach(filteredCompetitions) { comp in
                            NavigationLink(value: comp.id) {
                                CompetitionRow(competition: comp)
                            }
                            .onAppear {
                                if comp.id == filteredCompetitions.last?.id {
                                    Task { await viewModel.loadMore(myPlayerId: appState.currentUser?.id) }
                                }
                            }
                        }

                        if viewModel.isLoadingMore {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(Color.theme.background)
        .navigationTitle("Competitions")
        .navigationDestination(for: String.self) { id in
            CompetitionDetailView(competitionId: id, appState: appState)
        }
        .toolbar {
            if let role = appState.currentUser?.role,
               role == "organizer" || role == "admin" || role == "super_admin" {
                ToolbarItem(placement: .primaryAction) {
                    NavigationLink {
                        CreateCompetitionView(appState: appState)
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(Color.accentColor)
                            .font(.title3)
                    }
                }
            }
        }
        .overlay {
            if viewModel.isLoading && viewModel.competitions.isEmpty {
                LoadingView()
            }
        }
        .refreshable {
            await viewModel.load(myPlayerId: appState.currentUser?.id)
        }
        .task {
            await viewModel.load(myPlayerId: appState.currentUser?.id)
        }
    }
}
