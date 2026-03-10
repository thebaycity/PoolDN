import SwiftUI

struct CompetitionListView: View {
    @Bindable var appState: AppState
    @State private var viewModel = CompetitionListViewModel()
    @State private var selectedFilter = 0

    private let filters: [(label: String, icon: String)] = [
        ("All", "square.grid.2x2"),
        ("Upcoming", "clock"),
        ("Active", "flame"),
        ("Completed", "checkmark.seal")
    ]

    private var isOrganizer: Bool {
        let role = appState.currentUser?.role ?? ""
        return role == "organizer" || role == "admin" || role == "super_admin"
    }

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
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                // Filter bar
                Section {
                    Color.clear.frame(height: 0)
                } header: {
                    filterBar
                }

                VStack(spacing: 20) {
                    // Organizer: My Competitions section
                    if isOrganizer && !viewModel.myCompetitions.isEmpty && selectedFilter == 0 {
                        myCompetitionsSection
                    }

                    // Role-specific CTA for non-organizers
                    if !isOrganizer && selectedFilter == 0 && !filteredCompetitions.isEmpty {
                        playerCTABanner
                    }

                    // Main list
                    allCompetitionsSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
        }
        .background(Color.theme.background)
        .navigationTitle("Competitions")
        .navigationDestination(for: String.self) { id in
            CompetitionDetailView(competitionId: id, appState: appState)
        }
        .toolbar {
            if isOrganizer {
                ToolbarItem(placement: .primaryAction) {
                    NavigationLink {
                        CreateCompetitionView(appState: appState)
                    } label: {
                        Label("New", systemImage: "plus.circle.fill")
                            .labelStyle(.titleAndIcon)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.accentColor)
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

    // MARK: - Filter Bar

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(filters.enumerated()), id: \.offset) { index, filter in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedFilter = index
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: filter.icon)
                                .font(.caption)
                            Text(filter.label)
                                .font(.subheadline)
                                .fontWeight(selectedFilter == index ? .semibold : .regular)
                        }
                        .foregroundColor(selectedFilter == index ? .white : Color.theme.textSecondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(selectedFilter == index ? Color.theme.accent : Color.theme.surfaceLight)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(Color.theme.background)
    }

    // MARK: - My Competitions (Organizer)

    private var myCompetitionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("My Competitions", systemImage: "star.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Color.theme.accentYellow)

                Spacer()

                Text("\(viewModel.myCompetitions.count)")
                    .font(.caption.weight(.bold))
                    .foregroundColor(Color.theme.accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.theme.accent.opacity(0.12))
                    .clipShape(Capsule())
            }

            ForEach(viewModel.myCompetitions) { comp in
                NavigationLink(value: comp.id) {
                    CompetitionRow(competition: comp)
                }
                .buttonStyle(.plain)
            }

            NavigationLink {
                CreateCompetitionView(appState: appState)
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Create New Competition")
                        .fontWeight(.medium)
                }
                .font(.subheadline)
                .foregroundColor(Color.theme.accent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.theme.accent.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color.theme.accent.opacity(0.2), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(Color.theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.theme.accentYellow.opacity(0.25), lineWidth: 1)
        )
    }

    // MARK: - Player CTA Banner

    private var playerCTABanner: some View {
        HStack(spacing: 14) {
            Image(systemName: "person.badge.plus")
                .font(.title3)
                .foregroundColor(Color.theme.accent)
                .frame(width: 40, height: 40)
                .background(Color.theme.accent.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text("Find your competition")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Color.theme.textPrimary)
                Text("Browse and apply to join with your team")
                    .font(.caption)
                    .foregroundColor(Color.theme.textSecondary)
            }

            Spacer()
        }
        .padding(14)
        .background(Color.theme.accent.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.theme.accent.opacity(0.15), lineWidth: 1)
        )
    }

    // MARK: - All Competitions Section

    private var allCompetitionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(selectedFilter == 0 ? "All Competitions" : filters[selectedFilter].label)
                    .sectionHeader()

                Spacer()

                if !filteredCompetitions.isEmpty {
                    Text("\(filteredCompetitions.count)\(viewModel.hasMore ? "+" : "")")
                        .font(.caption.weight(.bold))
                        .foregroundColor(Color.theme.textTertiary)
                }
            }

            if filteredCompetitions.isEmpty && !viewModel.isLoading {
                EmptyStateView(
                    icon: "trophy",
                    title: "No Competitions",
                    message: selectedFilter == 0
                        ? (isOrganizer ? "Create your first competition!" : "Check back soon.")
                        : "No \(filters[selectedFilter].label.lowercased()) competitions right now"
                )
                .padding(.vertical, 24)
            } else {
                ForEach(filteredCompetitions) { comp in
                    NavigationLink(value: comp.id) {
                        CompetitionRow(competition: comp)
                    }
                    .buttonStyle(.plain)
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
    }
}
