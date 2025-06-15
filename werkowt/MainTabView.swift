import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var activeWorkout: ActiveWorkout
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
            
            HistoryView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("History")
                }
        }
    }
}