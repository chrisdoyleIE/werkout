import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var activeWorkout: ActiveWorkout
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        TabView(selection: .constant(0)) {
            MealTrackingView()
                .tabItem {
                    Image(systemName: "carrot")
                    Text("Meals")
                }
                .tag(0)
            
            HomeView()
                .tabItem {
                    Image(systemName: "house")
                    Text("Workouts")
                }
                .tag(1)
            
            WorkoutProgressView()
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("Progress")
                }
                .tag(2)
        }
    }
}
