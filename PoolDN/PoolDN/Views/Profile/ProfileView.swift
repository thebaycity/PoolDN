import SwiftUI
import PhotosUI

struct ProfileView: View {
    @Bindable var appState: AppState
    @State private var viewModel = ProfileViewModel()
    @State private var showEditSheet = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showCropView = false
    @State private var selectedImage: UIImage?
    @State private var showFullAvatar = false

    var body: some View {
        ScrollView {
            if let user = viewModel.user {
                VStack(spacing: 16) {
                    // Avatar & Name
                    VStack(spacing: 14) {
                        // Avatar with camera badge + upload progress
                        ZStack {
                            ZStack(alignment: .bottomTrailing) {
                                avatarView(user: user, size: 88)
                                    .onTapGesture {
                                        if user.avatarUrl != nil {
                                            showFullAvatar = true
                                        }
                                    }

                                if !viewModel.isUploading {
                                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                                        Image(systemName: "camera.fill")
                                            .font(.caption)
                                            .foregroundColor(.white)
                                            .padding(6)
                                            .background(Color.theme.accent)
                                            .clipShape(Circle())
                                    }
                                    .offset(x: 4, y: 4)
                                }
                            }

                            if viewModel.isUploading {
                                Circle()
                                    .fill(.black.opacity(0.4))
                                    .frame(width: 88, height: 88)
                                ProgressView()
                                    .tint(.white)
                                    .scaleEffect(1.3)
                            }
                        }

                        VStack(spacing: 4) {
                            Text(user.name)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(Color.theme.textPrimary)
                            if let nickname = user.nickname {
                                Text("@\(nickname)")
                                    .font(.subheadline)
                                    .foregroundColor(Color.theme.accent)
                            }
                            if user.role == "organizer" {
                                Text("Organizer")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color.theme.accent)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 3)
                                    .background(Color.theme.accent.opacity(0.12))
                                    .clipShape(Capsule())
                            }
                            Text(user.email)
                                .font(.caption)
                                .foregroundColor(Color.theme.textSecondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .cardStyle()

                    // Stats
                    if let stats = viewModel.stats {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Statistics")
                                .sectionHeader()

                            HStack(spacing: 0) {
                                statBox("Matches", "\(stats.totalMatches)", icon: "sportscourt")
                                divider
                                statBox("Wins", "\(stats.wins)", icon: "trophy.fill", color: Color.theme.accentGreen)
                                divider
                                statBox("Losses", "\(stats.losses)", icon: "xmark.circle", color: Color.theme.accentRed)
                                divider
                                statBox("Teams", "\(stats.teamsCount)", icon: "person.3")
                            }
                        }
                        .cardStyle()
                    }

                    // My Teams
                    if !viewModel.myTeams.isEmpty {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("My Teams")
                                .sectionHeader()

                            Divider().overlay(Color.theme.separator)

                            ForEach(viewModel.myTeams) { team in
                                NavigationLink(value: team) {
                                    HStack(spacing: 12) {
                                        ZStack {
                                            Circle()
                                                .fill(Color.theme.accent.opacity(0.15))
                                                .frame(width: 36, height: 36)
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
                                                Text(city)
                                                    .font(.caption)
                                                    .foregroundColor(Color.theme.textSecondary)
                                            }
                                        }

                                        Spacer()

                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(Color.theme.textTertiary)
                                    }
                                }
                            }
                        }
                        .cardStyle()
                    }

                    // Details
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Details")
                            .sectionHeader()

                        Divider().overlay(Color.theme.separator)

                        detailRow(icon: "number", value: user.id)
                    }
                    .cardStyle()

                    // Actions
                    Button {
                        showEditSheet = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "pencil")
                            Text("Edit Profile")
                        }
                        .secondaryButton()
                    }

                    Button {
                        appState.logout()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Sign Out")
                        }
                        .destructiveButton()
                    }
                }
                .padding()
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
        .fullScreenCover(isPresented: $showFullAvatar) {
            if let user = viewModel.user {
                ZStack {
                    Color.black.ignoresSafeArea()

                    if let avatarUrl = user.avatarUrl,
                       let url = URL(string: "\(AppConfig.apiBaseURL.replacingOccurrences(of: "/api", with: ""))\(avatarUrl)") {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let img):
                                img
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
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
                            Button {
                                showFullAvatar = false
                            } label: {
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
        .fullScreenCover(isPresented: $showCropView) {
            if let image = selectedImage {
                ImageCropView(image: image) { croppedData in
                    showCropView = false
                    selectedImage = nil
                    Task {
                        if await viewModel.uploadAvatar(croppedData) {
                            if let uid = appState.currentUser?.id {
                                await viewModel.load(uid)
                            }
                        }
                    }
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

    @ViewBuilder
    private func avatarView(user: User, size: CGFloat) -> some View {
        if let avatarUrl = user.avatarUrl,
           let url = URL(string: "\(AppConfig.apiBaseURL.replacingOccurrences(of: "/api", with: ""))\(avatarUrl)") {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: size, height: size)
                        .clipShape(Circle())
                case .failure:
                    initialsCircle(name: user.name, size: size)
                default:
                    Circle()
                        .fill(Color.theme.accent.opacity(0.15))
                        .frame(width: size, height: size)
                }
            }
        } else {
            initialsCircle(name: user.name, size: size)
        }
    }

    private func initialsCircle(name: String, size: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(Color.theme.accent.opacity(0.15))
                .frame(width: size, height: size)
            Text(String(name.prefix(2)).uppercased())
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(Color.theme.accent)
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.theme.separator)
            .frame(width: 1, height: 32)
    }

    private func statBox(_ label: String, _ value: String, icon: String, color: Color = Color.theme.textPrimary) -> some View {
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

    private func detailRow(icon: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(Color.theme.accent)
                .frame(width: 22)
            Text(value)
                .font(.subheadline)
                .foregroundColor(Color.theme.textPrimary)
            Spacer()
        }
    }
}
