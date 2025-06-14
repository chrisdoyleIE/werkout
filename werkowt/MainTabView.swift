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
            
            ExerciseLibraryView()
                .tabItem {
                    Image(systemName: "books.vertical.fill")
                    Text("Exercises")
                }
            
            WorkoutProgressView()
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("Progress")
                }
            
            HistoryView()
                .tabItem {
                    Image(systemName: "clock.fill")
                    Text("History")
                }
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
        }
        .fullScreenCover(isPresented: .constant(false)) {
            LiveWorkoutView()
                .environmentObject(activeWorkout)
                .environmentObject(WorkoutDataManager.shared)
                .environmentObject(ExerciseDataManager.shared)
        }
    }
}