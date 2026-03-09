import SwiftUI

@Observable
class AppState {
    var isAuthenticated = false
    var currentUser: UserSummary?
    var selectedTab = 0

    init() {
        if AuthService.isAuthenticated {
            isAuthenticated = true
        }
    }

    func handleAuth(_ response: AuthResponse) {
        currentUser = response.user
        isAuthenticated = true
    }

    func logout() {
        AuthService.logout()
        isAuthenticated = false
        currentUser = nil
    }

    func loadProfile() async {
        do {
            let user = try await AuthService.getMe()
            currentUser = UserSummary(id: user.id, email: user.email, name: user.name, nickname: user.nickname, role: user.role)
        } catch {
            logout()
        }
    }
}

struct ContentRouter: View {
    @State var appState = AppState()
    @State private var showRegister = false

    var body: some View {
        Group {
            if appState.isAuthenticated {
                MainTabView(appState: appState)
                    .transition(.opacity)
                    .task {
                        if appState.currentUser == nil {
                            await appState.loadProfile()
                        }
                    }
            } else {
                if showRegister {
                    RegisterView(
                        onRegister: { response in
                            withAnimation(.easeInOut(duration: 0.3)) {
                                appState.handleAuth(response)
                            }
                        },
                        onSwitchToLogin: {
                            withAnimation(.easeInOut(duration: 0.2)) { showRegister = false }
                        }
                    )
                    .transition(.move(edge: .trailing))
                } else {
                    LoginView(
                        onLogin: { response in
                            withAnimation(.easeInOut(duration: 0.3)) {
                                appState.handleAuth(response)
                            }
                        },
                        onSwitchToRegister: {
                            withAnimation(.easeInOut(duration: 0.2)) { showRegister = true }
                        }
                    )
                    .transition(.move(edge: .leading))
                }
            }
        }
    }
}
