import SwiftUI

struct MainTabView: View {
    @Bindable var appState: AppState

    var body: some View {
        TabView(selection: $appState.selectedTab) {
            NavigationStack {
                CompetitionListView(appState: appState)
            }
            .tabItem {
                Label("Competitions", systemImage: "trophy.fill")
            }
            .tag(0)

            NavigationStack {
                TeamListView(appState: appState)
            }
            .tabItem {
                Label("Teams", systemImage: "person.3.fill")
            }
            .tag(1)

            NavigationStack {
                NotificationListView(appState: appState)
            }
            .tabItem {
                Label("Alerts", systemImage: "bell.fill")
            }
            .tag(2)

            NavigationStack {
                ProfileView(appState: appState)
            }
            .tabItem {
                Label("Profile", systemImage: "person.circle.fill")
            }
            .tag(3)
        }
        .tint(Color.theme.accent)
    }
}
