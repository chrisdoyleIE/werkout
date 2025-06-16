import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var activeWorkout: ActiveWorkout
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Workouts")
                }
            
            WorkoutProgressView()
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("Progress")
                }
        }
    }
}
