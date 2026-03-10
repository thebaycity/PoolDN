import SwiftUI

struct EditCompetitionView: View {
    let competition: Competition
    @Bindable var detailViewModel: CompetitionDetailViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var vm = EditCompetitionViewModel()
    @State private var showDiscardAlert = false
    @State private var newGameLabel = ""
    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case name, gameType, description, prize, centralVenue, newItem
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // ── Locked-status banner ──────────────────
                    if vm.isUpcoming {
                        upcomingBanner
                    }

                    // ── Basic Info ────────────────────────────
                    formCard(title: "Basic Info", icon: "doc.text") {
                        validatedField(
                            label: "Competition Name",
                            icon: "trophy",
                            text: $vm.name,
                            placeholder: "e.g. City 8-Ball League",
                            error: vm.nameError,
                            focus: .name
                        )
                        Divider().overlay(Color.theme.separator)
                        validatedField(
                            label: "Game Type",
                            icon: "circle.grid.3x3",
                            text: $vm.gameType,
                            placeholder: "e.g. 8-Ball, 9-Ball",
                            error: vm.gameTypeError,
                            focus: .gameType
                        )
                        Divider().overlay(Color.theme.separator)
                        descriptionField
                    }

                    // ── Location ──────────────────────────────
                    formCard(title: "Location", icon: "mappin.circle") {
                        CitySelectionView(
                            label: "",
                            selectedCity: $vm.city,
                            selectedCountry: $vm.country,
                            placeholder: "Select host city",
                            isOptional: true
                        )
                    }

                    // ── Date & Prize ──────────────────────────
                    formCard(title: "Date & Prize", icon: "calendar") {
                        HStack {
                            Label("Start Date", systemImage: "calendar")
                                .font(.subheadline)
                                .foregroundColor(Color.theme.textSecondary)
                            Spacer()
                            DatePicker("", selection: $vm.startDate,
                                       in: Date().addingTimeInterval(86400)...,
                                       displayedComponents: .date)
                                .labelsHidden()
                                .tint(Color.theme.accent)
                        }
                        Divider().overlay(Color.theme.separator)
                        HStack {
                            Label("Prize Pool", systemImage: "dollarsign.circle")
                                .font(.subheadline)
                                .foregroundColor(Color.theme.textSecondary)
                            Spacer()
                            HStack(spacing: 4) {
                                Text("$").foregroundColor(Color.theme.textSecondary)
                                TextField("0", text: $vm.prize)
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 80)
                                    .focused($focusedField, equals: .prize)
                            }
                            .font(.subheadline)
                            .foregroundColor(Color.theme.textPrimary)
                        }
                    }

                    // ── Team Size (draft only) ─────────────────
                    if !vm.isUpcoming {
                        formCard(title: "Team Size", icon: "person.2") {
                            teamSizeRow
                        }
                    }

                    // ── Match Structure (draft only) ──────────
                    if !vm.isUpcoming {
                        matchStructureCard
                        addItemCard
                    }

                    // ── Schedule Config (draft only) ─────────
                    if !vm.isUpcoming {
                        venueCard
                        matchupsCard
                        schedulingCard
                    }

                    // ── Error ─────────────────────────────────
                    if let err = vm.errorMessage {
                        errorBanner(err)
                    }

                    Spacer(minLength: 32)
                }
                .padding(16)
            }
            .background(Color.theme.background)
            .navigationTitle("Edit Competition")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showDiscardAlert = true }
                }
                ToolbarItem(placement: .primaryAction) {
                    if vm.isLoading {
                        ProgressView().scaleEffect(0.8).tint(Color.theme.accent)
                    } else {
                        Button("Save") {
                            Task { await saveAndDismiss() }
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(vm.isValid ? Color.theme.accent : Color.theme.textTertiary)
                        .disabled(!vm.isValid)
                    }
                }
            }
            .confirmationDialog("Discard changes?", isPresented: $showDiscardAlert, titleVisibility: .visible) {
                Button("Discard", role: .destructive) { dismiss() }
                Button("Keep Editing", role: .cancel) {}
            }
            .onAppear { vm.load(from: competition) }
        }
    }

    // MARK: - Sub-views

    private var upcomingBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "info.circle.fill")
                .foregroundColor(Color.theme.accent)
            VStack(alignment: .leading, spacing: 2) {
                Text("Limited Editing")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(Color.theme.textPrimary)
                Text("Team size, match structure, and schedule are locked once published.")
                    .font(.caption)
                    .foregroundColor(Color.theme.textSecondary)
            }
        }
        .padding(12)
        .background(Color.theme.accent.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.theme.accent.opacity(0.2), lineWidth: 0.5)
        )
    }

    private var descriptionField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Description", systemImage: "text.alignleft")
                .font(.caption)
                .foregroundColor(Color.theme.textTertiary)
            ZStack(alignment: .topLeading) {
                if vm.description.isEmpty {
                    Text("Describe the competition format, rules…")
                        .font(.subheadline)
                        .foregroundColor(Color.theme.textTertiary)
                        .padding(.top, 8).padding(.leading, 4)
                }
                TextEditor(text: $vm.description)
                    .font(.subheadline)
                    .foregroundColor(Color.theme.textPrimary)
                    .frame(minHeight: 80)
                    .scrollContentBackground(.hidden)
                    .focused($focusedField, equals: .description)
            }
        }
    }

    private var teamSizeRow: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Min players per team")
                    .font(.subheadline)
                    .foregroundColor(Color.theme.textSecondary)
                Spacer()
                Stepper("\(vm.teamSizeMin)", value: $vm.teamSizeMin, in: 1...vm.teamSizeMax)
                    .labelsHidden()
                Text("\(vm.teamSizeMin)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Color.theme.textPrimary)
                    .frame(width: 24, alignment: .center)
            }
            Divider().overlay(Color.theme.separator)
            HStack {
                Text("Max players per team")
                    .font(.subheadline)
                    .foregroundColor(Color.theme.textSecondary)
                Spacer()
                Stepper("\(vm.teamSizeMax)", value: $vm.teamSizeMax, in: vm.teamSizeMin...20)
                    .labelsHidden()
                Text("\(vm.teamSizeMax)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Color.theme.textPrimary)
                    .frame(width: 24, alignment: .center)
            }
            if let err = vm.teamSizeError {
                Label(err, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundColor(Color.theme.accentRed)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: - Match Structure

    private var matchStructureCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Match Structure", systemImage: "list.bullet.rectangle")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(Color.theme.accent)
                    .textCase(.uppercase)
                    .tracking(0.4)
                Spacer()
                if !vm.gameStructure.isEmpty {
                    Text("\(vm.gameStructure.count) items")
                        .font(.caption)
                        .foregroundColor(Color.theme.textTertiary)
                }
            }

            if vm.gameStructure.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "plus.square.dashed")
                        .font(.title3)
                        .foregroundColor(Color.theme.textTertiary)
                    Text("Add games and breaks below to define one match.")
                        .font(.caption)
                        .foregroundColor(Color.theme.textSecondary)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.theme.surfaceLight)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(vm.gameStructure.enumerated()), id: \.offset) { idx, item in
                        HStack(spacing: 10) {
                            Text("\(idx + 1)")
                                .font(.caption2.monospacedDigit())
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(width: 20, height: 20)
                                .background(item.type == "game" ? Color.theme.accent : Color.theme.textTertiary)
                                .clipShape(Circle())

                            Image(systemName: item.type == "game" ? "circle.fill" : "pause.circle.fill")
                                .font(.caption2)
                                .foregroundColor(item.type == "game" ? Color.theme.accent : Color.theme.textTertiary)

                            Text(item.label)
                                .font(.subheadline)
                                .foregroundColor(Color.theme.textPrimary)

                            Spacer()

                            Text(item.type == "game" ? "Game" : "Break")
                                .font(.caption2.weight(.semibold))
                                .foregroundColor(item.type == "game" ? Color.theme.accent : Color.theme.textSecondary)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(item.type == "game" ? Color.theme.accent.opacity(0.1) : Color.theme.surfaceLight)
                                .clipShape(Capsule())

                            Button {
                                vm.gameStructure.remove(at: idx)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.body)
                                    .foregroundColor(Color.theme.textTertiary)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 2)

                        if idx < vm.gameStructure.count - 1 {
                            Divider().overlay(Color.theme.separator)
                        }
                    }
                }
            }
        }
        .padding(14)
        .background(Color.theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.theme.border, lineWidth: 0.5)
        )
    }

    private var addItemCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Add Item", systemImage: "plus.circle")
                .font(.caption.weight(.semibold))
                .foregroundColor(Color.theme.accent)
                .textCase(.uppercase)
                .tracking(0.4)

            HStack(spacing: 10) {
                Image(systemName: "tag")
                    .font(.subheadline)
                    .foregroundColor(Color.theme.accent)
                    .frame(width: 20)
                TextField("e.g. 8-Ball Singles, Break", text: $newGameLabel)
                    .font(.subheadline)
                    .foregroundColor(Color.theme.textPrimary)
                    .focused($focusedField, equals: .newItem)
                    .submitLabel(.done)
                    .onSubmit { addGame() }
            }
            .padding(12)
            .background(Color.theme.surfaceLight)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            HStack(spacing: 10) {
                Button { addGame() } label: {
                    Label("Add Game", systemImage: "circle.fill")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(newGameLabel.isEmpty ? Color.theme.textTertiary : Color.theme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .disabled(newGameLabel.isEmpty)
                .buttonStyle(.plain)

                Button {
                    guard !newGameLabel.isEmpty else { return }
                    vm.addBreak(label: newGameLabel)
                    newGameLabel = ""
                    focusedField = nil
                } label: {
                    Label("Break", systemImage: "pause.fill")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(newGameLabel.isEmpty ? Color.theme.textTertiary : Color.theme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(Color.theme.surfaceLight)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(Color.theme.border, lineWidth: 1)
                        )
                }
                .disabled(newGameLabel.isEmpty)
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background(Color.theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.theme.border, lineWidth: 0.5)
        )
    }

    // MARK: - Schedule Config

    private let weekdayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    private var venueCard: some View {
        formCard(title: "Venue", icon: "building.2") {
            HStack(spacing: 8) {
                venueOption(label: "Central Venue", icon: "building.2.fill", tag: "central")
                venueOption(label: "Team Venues", icon: "house.fill", tag: "team_venues")
            }

            if vm.venueType == "central" {
                HStack(spacing: 10) {
                    Image(systemName: "mappin")
                        .font(.subheadline)
                        .foregroundColor(Color.theme.accent)
                        .frame(width: 20)
                    TextField("Venue name or address", text: $vm.centralVenue)
                        .font(.subheadline)
                        .foregroundColor(Color.theme.textPrimary)
                        .focused($focusedField, equals: .centralVenue)
                }
                .padding(12)
                .background(Color.theme.surfaceLight)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
    }

    private func venueOption(label: String, icon: String, tag: String) -> some View {
        let selected = vm.venueType == tag
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) { vm.venueType = tag }
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

    private var matchupsCard: some View {
        formCard(title: "Matchups", icon: "arrow.left.arrow.right") {
            HStack(spacing: 8) {
                matchupOption(label: "Single", sub: "1 game each", icon: "arrow.right", tag: 1)
                matchupOption(label: "Home & Away", sub: "2 games each", icon: "arrow.left.arrow.right", tag: 2)
            }
        }
    }

    private func matchupOption(label: String, sub: String, icon: String, tag: Int) -> some View {
        let selected = vm.gamesPerOpponent == tag
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) { vm.gamesPerOpponent = tag }
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

    private var schedulingCard: some View {
        formCard(title: "Scheduling", icon: "calendar.badge.clock") {
            HStack(spacing: 8) {
                scheduleOption(label: "Weekly Rounds", icon: "repeat", tag: "weekly_rounds")
                scheduleOption(label: "Fixed Matchdays", icon: "calendar", tag: "fixed_matchdays")
            }

            if vm.schedulingType == "weekly_rounds" {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Match Days")
                        .font(.caption)
                        .foregroundColor(Color.theme.textSecondary)

                    HStack(spacing: 6) {
                        ForEach(0..<7) { day in
                            let isSelected = vm.selectedWeekdays.contains(day)
                            Button {
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    if isSelected {
                                        vm.selectedWeekdays.remove(day)
                                    } else {
                                        vm.selectedWeekdays.insert(day)
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
    }

    private func scheduleOption(label: String, icon: String, tag: String) -> some View {
        let selected = vm.schedulingType == tag
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) { vm.schedulingType = tag }
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

    // MARK: - Reusable builders

    private func formCard<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.caption.weight(.semibold))
                .foregroundColor(Color.theme.accent)
                .textCase(.uppercase)
                .tracking(0.4)
            content()
        }
        .padding(14)
        .background(Color.theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.theme.border, lineWidth: 0.5)
        )
    }

    private func validatedField(
        label: String,
        icon: String,
        text: Binding<String>,
        placeholder: String,
        error: String?,
        focus: Field
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundColor(error != nil ? Color.theme.accentRed : Color.theme.accent)
                    .frame(width: 20)
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.caption)
                        .foregroundColor(error != nil ? Color.theme.accentRed : Color.theme.textTertiary)
                    TextField(placeholder, text: text)
                        .font(.subheadline)
                        .foregroundColor(Color.theme.textPrimary)
                        .focused($focusedField, equals: focus)
                }
            }
            if let err = error, !text.wrappedValue.isEmpty {
                Text(err)
                    .font(.caption2)
                    .foregroundColor(Color.theme.accentRed)
                    .padding(.leading, 30)
            }
        }
        .animation(.easeInOut(duration: 0.15), value: error)
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(Color.theme.accentRed)
            Text(message)
                .font(.subheadline)
                .foregroundColor(Color.theme.textPrimary)
            Spacer()
            Button { vm.errorMessage = nil } label: {
                Image(systemName: "xmark")
                    .font(.caption.bold())
                    .foregroundColor(Color.theme.textTertiary)
            }
        }
        .padding(12)
        .background(Color.theme.accentRed.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.theme.accentRed.opacity(0.25), lineWidth: 0.5)
        )
    }

    // MARK: - Actions

    private func addGame() {
        guard !newGameLabel.isEmpty else { return }
        vm.addGame(label: newGameLabel)
        newGameLabel = ""
        focusedField = nil
    }

    private func saveAndDismiss() async {
        if let updated = await vm.save() {
            detailViewModel.competition = updated
            dismiss()
        }
    }
}


