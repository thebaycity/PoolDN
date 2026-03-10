import SwiftUI

struct ScheduleReviewStep: View {
    @Bindable var viewModel: CompetitionCreateViewModel

    private let weekdayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                venueCard
                matchupsCard
                schedulingCard
                summaryCard
                Spacer(minLength: 32)
            }
            .padding(16)
        }
    }

    // MARK: - Venue

    private var venueCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Venue", systemImage: "building.2")
                .font(.caption.weight(.semibold))
                .foregroundColor(Color.theme.accent)
                .textCase(.uppercase)
                .tracking(0.4)

            // Segmented-style picker
            HStack(spacing: 8) {
                venueOption(label: "Central Venue", icon: "building.2.fill", tag: "central")
                venueOption(label: "Team Venues", icon: "house.fill", tag: "team_venues")
            }

            if viewModel.venueType == "central" {
                HStack(spacing: 10) {
                    Image(systemName: "mappin")
                        .font(.subheadline)
                        .foregroundColor(Color.theme.accent)
                        .frame(width: 20)
                    TextField("Venue name or address", text: $viewModel.centralVenue)
                        .font(.subheadline)
                        .foregroundColor(Color.theme.textPrimary)
                }
                .padding(12)
                .background(Color.theme.surfaceLight)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
        .padding(14)
        .background(Color.theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Color.theme.border, lineWidth: 0.5))
    }

    private func venueOption(label: String, icon: String, tag: String) -> some View {
        let selected = viewModel.venueType == tag
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) { viewModel.venueType = tag }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.caption)
                Text(label).font(.subheadline.weight(selected ? .semibold : .regular))
            }
            .foregroundColor(selected ? .white : Color.theme.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(selected ? Color.theme.accent : Color.theme.surfaceLight)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Matchups

    private var matchupsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Matchups", systemImage: "arrow.left.arrow.right")
                .font(.caption.weight(.semibold))
                .foregroundColor(Color.theme.accent)
                .textCase(.uppercase)
                .tracking(0.4)

            HStack(spacing: 8) {
                matchupOption(label: "Single", sub: "1 game each", icon: "arrow.right", tag: 1)
                matchupOption(label: "Home & Away", sub: "2 games each", icon: "arrow.left.arrow.right", tag: 2)
            }
        }
        .padding(14)
        .background(Color.theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Color.theme.border, lineWidth: 0.5))
    }

    private func matchupOption(label: String, sub: String, icon: String, tag: Int) -> some View {
        let selected = viewModel.gamesPerOpponent == tag
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) { viewModel.gamesPerOpponent = tag }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(selected ? Color.theme.accent : Color.theme.textTertiary)
                Text(label)
                    .font(.subheadline.weight(selected ? .semibold : .regular))
                    .foregroundColor(selected ? Color.theme.textPrimary : Color.theme.textSecondary)
                Text(sub)
                    .font(.caption2)
                    .foregroundColor(Color.theme.textTertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(selected ? Color.theme.accent.opacity(0.08) : Color.theme.surfaceLight)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(selected ? Color.theme.accent.opacity(0.4) : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Scheduling

    private var schedulingCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Scheduling", systemImage: "calendar.badge.clock")
                .font(.caption.weight(.semibold))
                .foregroundColor(Color.theme.accent)
                .textCase(.uppercase)
                .tracking(0.4)

            HStack(spacing: 8) {
                scheduleOption(label: "Weekly Rounds", icon: "repeat", tag: "weekly_rounds")
                scheduleOption(label: "Fixed Matchdays", icon: "calendar", tag: "fixed_matchdays")
            }

            if viewModel.schedulingType == "weekly_rounds" {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Match Days")
                        .font(.caption)
                        .foregroundColor(Color.theme.textSecondary)

                    HStack(spacing: 6) {
                        ForEach(0..<7) { day in
                            let isSelected = viewModel.selectedWeekdays.contains(day)
                            Button {
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    if isSelected {
                                        viewModel.selectedWeekdays.remove(day)
                                    } else {
                                        viewModel.selectedWeekdays.insert(day)
                                    }
                                }
                            } label: {
                                Text(weekdayNames[day])
                                    .font(.caption2.weight(.semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 9)
                                    .background(isSelected ? Color.theme.accent : Color.theme.surfaceLight)
                                    .foregroundColor(isSelected ? .white : Color.theme.textSecondary)
                                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                                            .strokeBorder(isSelected ? Color.clear : Color.theme.border, lineWidth: 0.5)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .padding(14)
        .background(Color.theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Color.theme.border, lineWidth: 0.5))
    }

    private func scheduleOption(label: String, icon: String, tag: String) -> some View {
        let selected = viewModel.schedulingType == tag
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) { viewModel.schedulingType = tag }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.caption)
                Text(label).font(.subheadline.weight(selected ? .semibold : .regular))
            }
            .foregroundColor(selected ? .white : Color.theme.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(selected ? Color.theme.accent : Color.theme.surfaceLight)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Summary

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Review Summary", systemImage: "checkmark.circle")
                .font(.caption.weight(.semibold))
                .foregroundColor(Color.theme.accentGreen)
                .textCase(.uppercase)
                .tracking(0.4)

            Divider().overlay(Color.theme.separator)

            Group {
                summaryRow(icon: "trophy", label: "Name", value: viewModel.name.isEmpty ? "—" : viewModel.name, required: true)
                if !viewModel.gameType.isEmpty {
                    summaryRow(icon: "circle.grid.3x3", label: "Game Type", value: viewModel.gameType)
                }
                summaryRow(icon: "person.2", label: "Team Size", value: "\(viewModel.teamSizeMin)–\(viewModel.teamSizeMax) players")
                if !viewModel.city.isEmpty {
                    summaryRow(icon: "mappin", label: "City", value: viewModel.city)
                }
                summaryRow(icon: "calendar", label: "Start Date", value: viewModel.startDate.shortDateString)
                summaryRow(icon: "list.bullet", label: "Match Games", value: "\(viewModel.gameStructure.count) item\(viewModel.gameStructure.count == 1 ? "" : "s")")
                summaryRow(icon: "building.2", label: "Venue", value: viewModel.venueType == "central" ? (viewModel.centralVenue.isEmpty ? "Central (TBD)" : viewModel.centralVenue) : "Team Venues")
                summaryRow(icon: "arrow.left.arrow.right", label: "Games / Opponent", value: "\(viewModel.gamesPerOpponent)")
            }
        }
        .padding(14)
        .background(Color.theme.accentGreen.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.theme.accentGreen.opacity(0.25), lineWidth: 1)
        )
    }

    private func summaryRow(icon: String, label: String, value: String, required: Bool = false) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(Color.theme.accent)
                .frame(width: 16)

            Text(label)
                .font(.subheadline)
                .foregroundColor(Color.theme.textSecondary)

            Spacer()

            HStack(spacing: 4) {
                if required && value == "—" {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption2)
                        .foregroundColor(Color.theme.accentRed)
                }
                Text(value)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(required && value == "—" ? Color.theme.accentRed : Color.theme.textPrimary)
            }
        }
    }
}
