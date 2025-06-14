import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var workoutDataManager: WorkoutDataManager
    @State private var selectedSession: WorkoutSession?
    
    var body: some View {
        NavigationView {
            VStack {
                if workoutDataManager.workoutSessions.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "clock")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        
                        Text("No workout history")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("Complete your first workout to see it here")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(workoutDataManager.workoutSessions, id: \.id) { session in
                            WorkoutSessionRow(session: session) {
                                selectedSession = session
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("History")
            .onAppear {
                Task {
                    await workoutDataManager.loadWorkoutSessions()
                }
            }
            .refreshable {
                await workoutDataManager.loadWorkoutSessions()
            }
        }
        .sheet(item: $selectedSession) { session in
            WorkoutDetailView(session: session)
        }
    }
}

struct WorkoutSessionRow: View {
    let session: WorkoutSession
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(session.name)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    if let duration = session.durationMinutes {
                        Text("\(duration)min")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack {
                    Text(session.startedAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if session.endedAt != nil {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    } else {
                        Text("In Progress")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct WorkoutDetailView: View {
    let session: WorkoutSession
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var workoutDataManager: WorkoutDataManager
    @EnvironmentObject var exerciseDataManager: ExerciseDataManager
    
    @State private var sets: [WorkoutSet] = []
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    SwiftUI.ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            // Session info
                            VStack(alignment: .leading, spacing: 8) {
                                Text(session.name)
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                
                                HStack {
                                    Text(session.startedAt.formatted(date: .abbreviated, time: .shortened))
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    if let duration = session.durationMinutes {
                                        Text("• \(duration) minutes")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            
                            // Exercises and sets
                            if sets.isEmpty {
                                Text("No sets recorded")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 40)
                            } else {
                                ForEach(groupedSets.keys.sorted(), id: \.self) { exerciseId in
                                    if let exerciseSets = groupedSets[exerciseId] {
                                        ExerciseDetailSection(
                                            exerciseId: exerciseId,
                                            sets: exerciseSets
                                        )
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Workout Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            loadSets()
        }
    }
    
    private var groupedSets: [String: [WorkoutSet]] {
        Dictionary(grouping: sets, by: \.exerciseId)
    }
    
    private func loadSets() {
        Task {
            do {
                let sessionSets = try await workoutDataManager.getSets(for: session.id)
                await MainActor.run {
                    sets = sessionSets
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                }
                print("Failed to load sets: \(error)")
            }
        }
    }
}

struct ExerciseDetailSection: View {
    let exerciseId: String
    let sets: [WorkoutSet]
    @EnvironmentObject var exerciseDataManager: ExerciseDataManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let exercise = exerciseDataManager.getExercise(by: exerciseId) {
                Text(exercise.name)
                    .font(.headline)
                    .fontWeight(.semibold)
            } else {
                Text(exerciseId)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            ForEach(sets.sorted(by: { $0.setNumber < $1.setNumber }), id: \.id) { set in
                HStack {
                    Text("Set \(set.setNumber)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(width: 60, alignment: .leading)
                    
                    Text("\(Int(set.weightLbs))lbs × \(set.reps) reps")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text(set.completedAt.formatted(date: .omitted, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 2)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}