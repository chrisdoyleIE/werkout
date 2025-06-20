import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var activeWorkout: ActiveWorkout
    @EnvironmentObject var authManager: AuthManager
    @State private var selectedTab = 1
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NutritionTabView()
                .tabItem {
                    Image(systemName: "carrot")
                    Text("Nutrition")
                }
                .tag(0)
            
            HomeView()
                .tabItem {
                    Image(systemName: "play.house.fill")
                    Text("Track")
                }
                .tag(1)
            
            WorkoutProgressView()
                .tabItem {
                    Image(systemName: "dumbbell.fill")
                    Text("Training")
                }
                .tag(2)
        }
    }
}
