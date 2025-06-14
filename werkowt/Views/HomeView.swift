import SwiftUI

struct HomeView: View {
    @EnvironmentObject var activeWorkout: ActiveWorkout
    @EnvironmentObject var workoutDataManager: WorkoutDataManager
    @State private var showingWorkoutCreator = false
    @State private var showingLiveWorkout = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    HStack {
                        VStack(alignment: .leading) {
                            Text("WERKOUT")
                                .font(.largeTitle)
                                .fontWeight(.black)
                            Text("Ready to get stronger?")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button(action: {}) {
                            Image(systemName: "gearshape.fill")
                                .font(.title2)
                                .foregroundColor(.primary)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Start Workout Button
                    Button(action: {
                        showingWorkoutCreator = true
                    }) {
                        HStack {
                            Image(systemName: "figure.strengthtraining.traditional")
                                .font(.title2)
                            Text("START WORKOUT")
                                .font(.headline)
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    // Recent Activity
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Recent Activity")
                                .font(.headline)
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        
                        if workoutDataManager.workoutSessions.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "figure.strengthtraining.traditional")
                                    .font(.largeTitle)
                                    .foregroundColor(.secondary)
                                Text("No workouts yet")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text("Start your first workout to see progress here")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else {
                            ForEach(Array(workoutDataManager.workoutSessions.prefix(3)), id: \.id) { session in
                                RecentWorkoutCard(session: session)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Quick Stats
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Quick Stats")
                                .font(.headline)
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        
                        HStack(spacing: 20) {
                            StatCard(
                                title: "Total Workouts",
                                value: "\(workoutDataManager.workoutSessions.count)",
                                icon: "number.circle.fill"
                            )
                            
                            StatCard(
                                title: "This Week",
                                value: "\(workoutsThisWeek)",
                                icon: "calendar.circle.fill"
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 100)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                Task {
                    await workoutDataManager.loadWorkoutSessions()
                }
            }
        }
        .sheet(isPresented: $showingWorkoutCreator) {
            WorkoutCreatorView()
        }
        .onChange(of: activeWorkout.isActive) { isActive in
            if isActive {
                showingWorkoutCreator = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showingLiveWorkout = true
                }
            }
        }
        .fullScreenCover(isPresented: $showingLiveWorkout) {
            LiveWorkoutView()
                .environmentObject(activeWorkout)
                .environmentObject(workoutDataManager)
                .environmentObject(ExerciseDataManager.shared)
                .onDisappear {
                    showingLiveWorkout = false
                }
        }
    }
    
    private var workoutsThisWeek: Int {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return workoutDataManager.workoutSessions.filter { session in
            session.startedAt >= weekAgo
        }.count
    }
}

struct RecentWorkoutCard: View {
    let session: WorkoutSession
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(session.name)
                    .font(.headline)
                    .fontWeight(.medium)
                Spacer()
                if let duration = session.durationMinutes {
                    Text("\(duration)min")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack {
                Text(RelativeDateTimeFormatter().localizedString(for: session.startedAt, relativeTo: Date()))
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}