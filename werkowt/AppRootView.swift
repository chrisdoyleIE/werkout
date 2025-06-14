import SwiftUI

struct AppRootView: View {
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var activeWorkout = ActiveWorkout()
    @StateObject private var exerciseDataManager = ExerciseDataManager.shared
    @StateObject private var workoutDataManager = WorkoutDataManager.shared
    
    var body: some View {
        Group {
            if authManager.isLoading {
                LoadingView()
            } else if authManager.isAuthenticated {
                MainTabView()
                    .environmentObject(activeWorkout)
                    .environmentObject(exerciseDataManager)
                    .environmentObject(workoutDataManager)
                    .environmentObject(authManager)
            } else {
                AuthView()
                    .environmentObject(authManager)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authManager.isAuthenticated)
    }
}

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("WERKOUT")
                .font(.largeTitle)
                .fontWeight(.black)
                .foregroundColor(.blue)
            
            SwiftUI.ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}