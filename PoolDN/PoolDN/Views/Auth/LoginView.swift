import SwiftUI

struct LoginView: View {
    @State private var viewModel = LoginViewModel()
    var onLogin: (AuthResponse) -> Void
    var onSwitchToRegister: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Spacer().frame(height: 80)

                // Brand
                VStack(spacing: 8) {
                    PoolDNLogo(size: 110)

                    Text("Pool & Billiards League")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.6))
                }

                Spacer().frame(height: 48)

                // Form
                VStack(spacing: 16) {
                    FormField(label: "Email", text: $viewModel.email, placeholder: "your@email.com", icon: "envelope", onDark: true)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)

                    FormField(label: "Password", text: $viewModel.password, placeholder: "Enter password", isSecure: true, icon: "lock", onDark: true)
                }

                if let error = viewModel.errorMessage {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.caption)
                        Text(error)
                            .font(.caption)
                    }
                    .foregroundColor(Color.theme.accentRed)
                    .padding(.top, 12)
                }

                Spacer().frame(height: 32)

                Button {
                    Task {
                        if let response = await viewModel.login() {
                            onLogin(response)
                        }
                    }
                } label: {
                    Group {
                        if viewModel.isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Sign In")
                        }
                    }
                    .goldButton()
                }
                .disabled(viewModel.isLoading)

                Spacer().frame(height: 24)

                Button {
                    onSwitchToRegister()
                } label: {
                    HStack(spacing: 4) {
                        Text("Don't have an account?")
                            .foregroundColor(.white.opacity(0.5))
                        Text("Sign Up")
                            .fontWeight(.semibold)
                            .foregroundColor(Color.theme.gold)
                    }
                    .font(.subheadline)
                }
            }
            .padding(.horizontal, 24)
        }
        .background(
            LinearGradient(
                colors: [Color.theme.navyDeep, Color.theme.navy],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .scrollDismissesKeyboard(.interactively)
    }
}
