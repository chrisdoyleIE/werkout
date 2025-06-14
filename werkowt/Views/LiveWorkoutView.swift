import SwiftUI

struct LiveWorkoutView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var activeWorkout: ActiveWorkout
    @EnvironmentObject var workoutDataManager: WorkoutDataManager
    @EnvironmentObject var exerciseDataManager: ExerciseDataManager
    
    @State private var currentWeight: Double = 0
    @State private var currentReps: Int = 0
    @State private var previousSessionData: PreviousSessionData?
    @State private var showingFinishConfirmation = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with timer and workout name
                HeaderView()
                
                // Exercise selector
                ExerciseListView()
                
                Divider()
                
                // Current exercise details
                if let currentExercise = activeWorkout.currentExercise {
                    ScrollView {
                        VStack(spacing: 20) {
                            CurrentExerciseView(
                                exercise: currentExercise,
                                previousData: previousSessionData
                            )
                            
                            SetInputView(
                                weight: $currentWeight,
                                reps: $currentReps,
                                onAddSet: addCurrentSet
                            )
                            
                            RestTimerView()
                            
                            NavigationButtonsView()
                        }
                        .padding()
                    }
                } else {
                    Spacer()
                    Text("No exercises selected")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Finish") {
                        showingFinishConfirmation = true
                    }
                }
            }
        }
        .onAppear {
            loadPreviousSessionData()
            setupInitialWeight()
        }
        .onChange(of: activeWorkout.currentExerciseIndex) { _ in
            loadPreviousSessionData()
            setupInitialWeight()
        }
        .confirmationDialog("Finish Workout", isPresented: $showingFinishConfirmation) {
            Button("Finish Workout", role: .destructive) {
                finishWorkout()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to finish this workout?")
        }
    }
    
    @ViewBuilder
    private func HeaderView() -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(formatElapsedTime())
                    .font(.title2)
                    .fontWeight(.bold)
                    .monospacedDigit()
                
                Text(activeWorkout.session?.name ?? "Workout")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
    }
    
    @ViewBuilder
    private func ExerciseListView() -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Array(activeWorkout.exercises.enumerated()), id: \.offset) { index, exerciseWithSets in
                    ExerciseChip(
                        exercise: exerciseWithSets.exercise,
                        isCompleted: exerciseWithSets.isCompleted,
                        isCurrent: index == activeWorkout.currentExerciseIndex
                    ) {
                        activeWorkout.currentExerciseIndex = index
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
    
    private func addCurrentSet() {
        guard let currentExercise = activeWorkout.currentExercise,
              currentWeight > 0, currentReps > 0 else { return }
        
        activeWorkout.addSet(
            exerciseId: currentExercise.exercise.id,
            reps: currentReps,
            weight: currentWeight
        )
        
        // Auto-increment weight by 2.5 lbs for next set
        currentWeight += 2.5
    }
    
    private func loadPreviousSessionData() {
        guard let currentExercise = activeWorkout.currentExercise else { return }
        
        Task {
            do {
                let data = try await workoutDataManager.getPreviousSessionData(for: currentExercise.exercise.id)
                await MainActor.run {
                    previousSessionData = data
                }
            } catch {
                print("Failed to load previous session data: \(error)")
            }
        }
    }
    
    private func setupInitialWeight() {
        guard let previousData = previousSessionData else { return }
        
        // Use the weight from the first set of the previous session
        if let firstSet = previousData.sets.first {
            currentWeight = firstSet.weightLbs
            currentReps = firstSet.reps
        }
    }
    
    private func finishWorkout() {
        activeWorkout.finishWorkout()
        dismiss()
    }
    
    private func formatElapsedTime() -> String {
        guard let startTime = activeWorkout.startTime else { return "0:00" }
        let elapsed = Int(Date().timeIntervalSince(startTime))
        let minutes = elapsed / 60
        let seconds = elapsed % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct ExerciseChip: View {
    let exercise: Exercise
    let isCompleted: Bool
    let isCurrent: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(exercise.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.caption)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isCurrent ? Color.blue : Color(.systemGray6))
            .foregroundColor(isCurrent ? .white : .primary)
            .cornerRadius(16)
        }
    }
}

struct CurrentExerciseView: View {
    let exercise: ExerciseWithSets
    let previousData: PreviousSessionData?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Exercise name
            Text(exercise.exercise.name.uppercased())
                .font(.title2)
                .fontWeight(.bold)
            
            // Previous session data
            if let previousData = previousData {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Last Session (\(RelativeDateTimeFormatter().localizedString(for: previousData.sessionDate, relativeTo: Date()))):")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(previousData.formattedSets)
                        .font(.headline)
                        .fontWeight(.medium)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
            
            // Today's sets
            VStack(alignment: .leading, spacing: 8) {
                Text("Today's Sets:")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                if exercise.sets.isEmpty {
                    Text("No sets completed yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    ForEach(exercise.sets, id: \.id) { set in
                        HStack {
                            Text("Set \(set.setNumber):")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text("\(Int(set.weightLbs))lbs × \(set.reps) reps")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
    }
}

struct SetInputView: View {
    @Binding var weight: Double
    @Binding var reps: Int
    let onAddSet: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                // Weight input
                VStack {
                    Text("Weight")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    HStack {
                        Button(action: { weight = max(0, weight - 5) }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.title)
                                .foregroundColor(.blue)
                        }
                        
                        Text("\(Int(weight))")
                            .font(.title)
                            .fontWeight(.bold)
                            .frame(minWidth: 60)
                        
                        Button(action: { weight += 5 }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title)
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                // Reps input
                VStack {
                    Text("Reps")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    HStack {
                        Button(action: { reps = max(0, reps - 1) }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.title)
                                .foregroundColor(.blue)
                        }
                        
                        Text("\(reps)")
                            .font(.title)
                            .fontWeight(.bold)
                            .frame(minWidth: 60)
                        
                        Button(action: { reps += 1 }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title)
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            
            // Add Set button
            Button(action: onAddSet) {
                Text("ADD SET")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(weight > 0 && reps > 0 ? Color.green : Color.gray)
                    .cornerRadius(12)
            }
            .disabled(weight <= 0 || reps <= 0)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct RestTimerView: View {
    @EnvironmentObject var activeWorkout: ActiveWorkout
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Rest Timer")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(activeWorkout.restTimer.formattedTime)
                .font(.title)
                .fontWeight(.bold)
                .monospacedDigit()
            
            HStack(spacing: 16) {
                if activeWorkout.restTimer.isRunning {
                    Button("Pause") {
                        activeWorkout.restTimer.pause()
                    }
                    .buttonStyle(.bordered)
                } else if activeWorkout.restTimer.timeRemaining > 0 {
                    Button("Resume") {
                        activeWorkout.restTimer.resume()
                    }
                    .buttonStyle(.bordered)
                }
                
                Button("Stop") {
                    activeWorkout.restTimer.stop()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct NavigationButtonsView: View {
    @EnvironmentObject var activeWorkout: ActiveWorkout
    
    var body: some View {
        HStack(spacing: 16) {
            Button(action: previousExercise) {
                HStack {
                    Image(systemName: "chevron.left")
                    Text("Previous")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .disabled(activeWorkout.currentExerciseIndex <= 0)
            
            Button(action: nextExercise) {
                HStack {
                    Text("Next")
                    Image(systemName: "chevron.right")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .disabled(activeWorkout.currentExerciseIndex >= activeWorkout.exercises.count - 1)
        }
    }
    
    private func previousExercise() {
        if activeWorkout.currentExerciseIndex > 0 {
            activeWorkout.currentExerciseIndex -= 1
        }
    }
    
    private func nextExercise() {
        if activeWorkout.currentExerciseIndex < activeWorkout.exercises.count - 1 {
            activeWorkout.currentExerciseIndex += 1
        }
    }
}