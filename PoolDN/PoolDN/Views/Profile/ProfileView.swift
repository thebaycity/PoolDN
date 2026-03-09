import SwiftUI
import PhotosUI

struct ProfileView: View {
    @Bindable var appState: AppState
    @State private var viewModel = ProfileViewModel()
    @State private var showEditSheet = false
    @State private var showChangePassword = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showCropView = false
    @State private var selectedImage: UIImage?
    @State private var showFullAvatar = false

    var body: some View {
        ScrollView {
            if let user = viewModel.user {
                VStack(spacing: 16) {
                    heroCard(user: user)

                    if let stats = viewModel.stats {
                        statsCard(stats: stats)
                    }

                    if !viewModel.myTeams.isEmpty {
                        myTeamsCard()
                    }

                    accountCard(user: user)

                    actionsSection()
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 32)
            } else if viewModel.isLoading {
                LoadingView()
            } else if let error = viewModel.errorMessage {
                ErrorView(message: error) {
                    Task {
                        if let uid = appState.currentUser?.id {
                            await viewModel.load(uid)
                        }
                    }
                }
            }
        }
        .background(Color.theme.background)
        .navigationTitle("Profile")
        .navigationDestination(for: Team.self) { team in
            TeamDetailView(teamId: team.id, appState: appState)
        }
        .sheet(isPresented: $showEditSheet) {
            EditProfileSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $showChangePassword) {
            ChangePasswordSheet(viewModel: viewModel)
        }
        .fullScreenCover(isPresented: $showFullAvatar) {
            fullAvatarCover()
        }
        .fullScreenCover(isPresented: $showCropView) {
            if let image = selectedImage {
                ImageCropView(image: image) { croppedData in
                    showCropView = false
                    selectedImage = nil
                    Task { await viewModel.uploadAvatar(croppedData) }
                } onCancel: {
                    showCropView = false
                    selectedImage = nil
                }
            }
        }
        .onChange(of: selectedPhoto) { _, newValue in
            guard let item = newValue else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    selectedImage = uiImage
                    showCropView = true
                }
                selectedPhoto = nil
            }
        }
        .task {
            if let uid = appState.currentUser?.id {
                await viewModel.load(uid)
            }
        }
    }

    // MARK: - Hero Card

    @ViewBuilder
    private func heroCard(user: User) -> some View {
        VStack(spacing: 16) {
            // Avatar
            ZStack {
                ZStack(alignment: .bottomTrailing) {
                    AvatarView(
                        avatarUrl: user.avatarUrl,
                        name: user.name,
                        size: 96,
                        version: viewModel.avatarVersion
                    )
                    .onTapGesture {
                        if user.avatarUrl != nil { showFullAvatar = true }
                    }

                    if !viewModel.isUploading {
                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            Image(systemName: "camera.fill")
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(7)
                                .background(Color.theme.accent)
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                        }
                        .offset(x: 4, y: 4)
                    }
                }

                if viewModel.isUploading {
                    Circle()
                        .fill(.black.opacity(0.45))
                        .frame(width: 96, height: 96)
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.3)
                }
            }

            // Name & meta
            VStack(spacing: 6) {
                Text(user.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color.theme.textPrimary)

                if let nickname = user.nickname {
                    Text("@\(nickname)")
                        .font(.subheadline)
                        .foregroundColor(Color.theme.accent)
                }

                HStack(spacing: 8) {
                    if user.role == "organizer" {
                        Label("Organizer", systemImage: "star.circle.fill")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.theme.accentYellow)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.theme.accentYellow.opacity(0.12))
                            .clipShape(Capsule())
                    }

                    Label(user.email, systemImage: "envelope")
                        .font(.caption)
                        .foregroundColor(Color.theme.textSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .cardStyle()
    }

    // MARK: - Stats Card

    @ViewBuilder
    private func statsCard(stats: UserStats) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Statistics")
                .sectionHeader()

            HStack(spacing: 0) {
                statBox("Matches", "\(stats.totalMatches)", icon: "sportscourt", color: Color.theme.textPrimary)
                statDivider
                statBox("Wins", "\(stats.wins)", icon: "trophy.fill", color: Color.theme.accentGreen)
                statDivider
                statBox("Losses", "\(stats.losses)", icon: "xmark.circle", color: Color.theme.accentRed)
                statDivider
                statBox("Teams", "\(stats.teamsCount)", icon: "person.3", color: Color.theme.accent)
            }
        }
        .cardStyle()
    }

    // MARK: - My Teams Card

    @ViewBuilder
    private func myTeamsCard() -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("My Teams")
                    .sectionHeader()
                Spacer()
                Text("\(viewModel.myTeams.count)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(Color.theme.accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.theme.accent.opacity(0.12))
                    .clipShape(Capsule())
            }

            Divider().overlay(Color.theme.separator)

            ForEach(viewModel.myTeams) { team in
                NavigationLink(value: team) {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.theme.accent.opacity(0.12))
                                .frame(width: 40, height: 40)
                            Text(String(team.name.prefix(2)).uppercased())
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(Color.theme.accent)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(team.name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(Color.theme.textPrimary)
                            if let city = team.city {
                                Label(city, systemImage: "mappin")
                                    .font(.caption)
                                    .foregroundColor(Color.theme.textSecondary)
                            }
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundColor(Color.theme.textTertiary)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .cardStyle()
    }

    // MARK: - Account Card

    @ViewBuilder
    private func accountCard(user: User) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Account")
                .sectionHeader()

            Divider().overlay(Color.theme.separator)

            infoRow(icon: "envelope.fill", label: "Email", value: user.email)

            Divider().overlay(Color.theme.separator)

            infoRow(icon: "person.badge.shield.checkmark", label: "Role", value: user.role.capitalized)

            Divider().overlay(Color.theme.separator)

            infoRow(icon: "calendar", label: "Member Since", value: formattedDate(from: user.createdAt))

            Divider().overlay(Color.theme.separator)

            // Change password tappable row
            Button {
                showChangePassword = true
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: "lock.rotation")
                        .font(.subheadline)
                        .foregroundColor(Color.theme.accent)
                        .frame(width: 20)

                    Text("Change Password")
                        .font(.subheadline)
                        .foregroundColor(Color.theme.accent)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundColor(Color.theme.textTertiary)
                }
            }
            .buttonStyle(.plain)
        }
        .cardStyle()
    }

    // MARK: - Actions

    @ViewBuilder
    private func actionsSection() -> some View {
        Button {
            showEditSheet = true
        } label: {
            Label("Edit Profile", systemImage: "pencil")
                .secondaryButton()
        }

        Button {
            appState.logout()
        } label: {
            Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                .destructiveButton()
        }
    }

    // MARK: - Full Avatar Cover

    @ViewBuilder
    private func fullAvatarCover() -> some View {
        if let user = viewModel.user {
            ZStack {
                Color.black.ignoresSafeArea()

                if let avatarUrl = user.avatarUrl,
                   let url = URL(string: "\(AppConfig.apiBaseURL.replacingOccurrences(of: "/api", with: ""))\(avatarUrl)?v=\(viewModel.avatarVersion)") {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let img):
                            img.resizable().aspectRatio(contentMode: .fit)
                        case .failure:
                            Image(systemName: "person.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.white.opacity(0.5))
                        default:
                            ProgressView().tint(.white)
                        }
                    }
                }

                VStack {
                    HStack {
                        Spacer()
                        Button { showFullAvatar = false } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(.white.opacity(0.8))
                        }
                        .padding()
                    }
                    Spacer()
                }
            }
        }
    }

    // MARK: - Helpers

    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(Color.theme.accent)
                .frame(width: 20)

            Text(label)
                .font(.subheadline)
                .foregroundColor(Color.theme.textSecondary)

            Spacer()

            Text(value)
                .font(.subheadline)
                .foregroundColor(Color.theme.textPrimary)
                .multilineTextAlignment(.trailing)
        }
    }

    private func formattedDate(from timestamp: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp / 1000))
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    private var statDivider: some View {
        Rectangle()
            .fill(Color.theme.separator)
            .frame(width: 1, height: 32)
    }

    private func statBox(_ label: String, _ value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(label)
                .font(.caption2)
                .foregroundColor(Color.theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}
