import SwiftUI

struct RegisterView: View {
    @State private var viewModel = RegisterViewModel()
    @State private var step = 0
    @State private var appeared = false
    @State private var direction: Edge = .trailing
    var onRegister: (AuthResponse) -> Void
    var onSwitchToLogin: () -> Void

    private var canContinue: Bool {
        switch step {
        case 0: !viewModel.role.isEmpty
        case 1: !viewModel.name.isEmpty
        case 2:
            !viewModel.email.isEmpty &&
            viewModel.password.count >= 6 &&
            viewModel.password == viewModel.confirmPassword
        default: false
        }
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.theme.navyDeep, Color.theme.navy],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar
                topBar
                    .padding(.horizontal, 24)
                    .padding(.top, 8)

                // Step indicator
                stepIndicator
                    .padding(.top, 16)

                // Step content
                ZStack {
                    switch step {
                    case 0: stepWelcome.transition(stepTransition)
                    case 1: stepAboutYou.transition(stepTransition)
                    case 2: stepAccount.transition(stepTransition)
                    default: EmptyView()
                    }
                }
                .padding(.horizontal, 24)
                .frame(maxHeight: .infinity)

                // Bottom actions
                bottomActions
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: step)
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            if step > 0 {
                Button {
                    direction = .leading
                    viewModel.errorMessage = nil
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                        step -= 1
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.body.weight(.semibold))
                        Text("Back")
                            .font(.subheadline)
                    }
                    .foregroundColor(.white.opacity(0.7))
                }
            }
            Spacer()
            if step > 0 {
                Text("Step \(step + 1) of 3")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .frame(height: 44)
    }

    // MARK: - Step Indicator

    private var stepIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { i in
                Capsule()
                    .fill(i <= step ? Color.theme.gold : Color.white.opacity(0.2))
                    .frame(width: i == step ? 24 : 8, height: 8)
                    .animation(.spring(response: 0.3), value: step)
            }
        }
    }

    // MARK: - Step Transition

    private var stepTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: direction == .leading ? .leading : .trailing)
                .combined(with: .opacity),
            removal: .move(edge: direction == .leading ? .trailing : .leading)
                .combined(with: .opacity)
        )
    }

    // MARK: - Step 0: Welcome + Role

    private var stepWelcome: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 24)

            PoolDNLogo(size: 90)

            Spacer().frame(height: 20)

            Text("Join PoolDN")
                .font(.title.weight(.bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.theme.goldLight, Color.theme.gold],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            Text("Choose how you'll use the app")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.6))
                .padding(.top, 4)

            Spacer().frame(height: 32)

            VStack(spacing: 12) {
                roleCard(
                    icon: "person.fill",
                    title: "Player",
                    subtitle: "Join teams, compete in leagues & track your stats",
                    value: "player"
                )
                roleCard(
                    icon: "star.fill",
                    title: "Organizer",
                    subtitle: "Create competitions, manage teams & run events",
                    value: "organizer"
                )
            }

            Spacer()
        }
        .id(0)
    }

    // MARK: - Step 1: About You

    private var stepAboutYou: some View {
        StepContentView {
            Text("About You")
                .font(.title2.weight(.bold))
                .foregroundColor(.white)

            Text("Tell us a bit about yourself")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.6))
                .padding(.top, 2)

            Spacer().frame(height: 32)

            VStack(spacing: 16) {
                FormField(label: "Full Name", text: $viewModel.name, placeholder: "John Doe", icon: "person", onDark: true)
                FormField(label: "Nickname", text: $viewModel.nickname, placeholder: "Optional", icon: "at", onDark: true)
            }

            if let error = viewModel.errorMessage {
                errorBanner(error)
            }

            Spacer()
        }
        .id(1)
    }

    // MARK: - Step 2: Account

    private var stepAccount: some View {
        StepContentView {
            Text("Your Account")
                .font(.title2.weight(.bold))
                .foregroundColor(.white)

            Text("Set up your login credentials")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.6))
                .padding(.top, 2)

            Spacer().frame(height: 32)

            VStack(spacing: 16) {
                FormField(label: "Email", text: $viewModel.email, placeholder: "your@email.com", icon: "envelope", onDark: true)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                FormField(label: "Password", text: $viewModel.password, placeholder: "Min 6 characters", isSecure: true, icon: "lock", onDark: true)
                FormField(label: "Confirm Password", text: $viewModel.confirmPassword, placeholder: "Repeat password", isSecure: true, icon: "lock.shield", onDark: true)
            }

            if let error = viewModel.errorMessage {
                errorBanner(error)
            }

            Spacer()
        }
        .id(2)
    }

    // MARK: - Bottom Actions

    private var bottomActions: some View {
        VStack(spacing: 16) {
            Button {
                handleContinue()
            } label: {
                Group {
                    if viewModel.isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text(step == 2 ? "Create Account" : "Continue")
                    }
                }
                .goldButton()
            }
            .disabled(!canContinue || viewModel.isLoading)
            .opacity(canContinue ? 1 : 0.5)

            if step == 0 {
                Button {
                    onSwitchToLogin()
                } label: {
                    HStack(spacing: 4) {
                        Text("Already have an account?")
                            .foregroundColor(.white.opacity(0.5))
                        Text("Sign In")
                            .fontWeight(.semibold)
                            .foregroundColor(Color.theme.gold)
                    }
                    .font(.subheadline)
                }
            }
        }
    }

    // MARK: - Helpers

    private func handleContinue() {
        viewModel.errorMessage = nil
        if step == 0 {
            direction = .trailing
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                step = 1
            }
        } else if step == 1 {
            guard !viewModel.name.isEmpty else {
                viewModel.errorMessage = "Please enter your name"
                return
            }
            direction = .trailing
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                step = 2
            }
        } else if step == 2 {
            guard !viewModel.email.isEmpty else {
                viewModel.errorMessage = "Please enter your email"
                return
            }
            guard viewModel.password.count >= 6 else {
                viewModel.errorMessage = "Password must be at least 6 characters"
                return
            }
            guard viewModel.password == viewModel.confirmPassword else {
                viewModel.errorMessage = "Passwords don't match"
                return
            }
            Task {
                if let response = await viewModel.register() {
                    onRegister(response)
                }
            }
        }
    }

    private func roleCard(icon: String, title: String, subtitle: String, value: String) -> some View {
        let isSelected = viewModel.role == value
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                viewModel.role = value
            }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(isSelected ? Color.theme.gold : .white.opacity(0.5))
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                        .lineLimit(2)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color.theme.gold)
                        .font(.title3)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(14)
            .background(isSelected ? Color.theme.gold.opacity(0.12) : Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(isSelected ? Color.theme.gold : Color.white.opacity(0.1), lineWidth: isSelected ? 1.5 : 0.5)
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
        }
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.caption)
            Text(message)
                .font(.caption)
        }
        .foregroundColor(Color.theme.accentRed)
        .padding(.top, 12)
    }
}

// MARK: - Step Content Wrapper

private struct StepContentView<Content: View>: View {
    @State private var appeared = false
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 40)
            content
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .onAppear {
            appeared = false
            withAnimation(.easeOut(duration: 0.4)) {
                appeared = true
            }
        }
    }
}
