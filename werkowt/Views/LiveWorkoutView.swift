import SwiftUI

struct LiveWorkoutView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var activeWorkout: ActiveWorkout
    @EnvironmentObject var workoutDataManager: WorkoutDataManager
    @EnvironmentObject var exerciseDataManager: ExerciseDataManager
    
    @State private var weightInput: String = ""
    @State private var repsInput: String = ""
    @State private var lastWorkoutSets: [WorkoutSet] = []
    @State private var showingFinishConfirmation = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with workout info
            VStack(spacing: 8) {
                HStack {
                    Button("Finish") {
                        showingFinishConfirmation = true
                    }
                    .font(.headline)
                    
                    Spacer()
                    
                    Text(activeWorkout.session?.name ?? "Workout")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Text(formatElapsedTime())
                        .font(.headline)
                        .monospacedDigit()
                }
                
                // Exercise navigation tabs
                if !activeWorkout.exercises.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Array(activeWorkout.exercises.enumerated()), id: \.offset) { index, exerciseWithSets in
                                ExerciseTab(
                                    exercise: exerciseWithSets.exercise,
                                    isSelected: index == activeWorkout.currentExerciseIndex,
                                    isCompleted: !exerciseWithSets.sets.isEmpty,
                                    setCount: exerciseWithSets.sets.count
                                ) {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        activeWorkout.currentExerciseIndex = index
                                    }
                                    loadLastWorkoutData()
                                    clearInputs()
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            
            if let currentExercise = activeWorkout.currentExercise {
                ScrollView {
                    VStack(spacing: 24) {
                        // Exercise name
                        Text(currentExercise.exercise.name)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .padding(.top)
                        
                        // Last workout data - full display
                        if !lastWorkoutSets.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("LAST WORKOUT")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.secondary)
                                
                                ForEach(lastWorkoutSets.sorted(by: { $0.setNumber < $1.setNumber }), id: \.id) { set in
                                    Text("Set \(set.setNumber): \(String(format: "%.1f", set.weightKg))kg × \(set.reps)")
                                        .font(.title3)
                                        .fontWeight(.medium)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                        
                        // Today's sets
                        if !currentExercise.sets.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("TODAY")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                
                                ForEach(currentExercise.sets.sorted(by: { $0.setNumber < $1.setNumber }), id: \.id) { set in
                                    Text("Set \(set.setNumber): \(String(format: "%.1f", set.weightKg))kg × \(set.reps)")
                                        .font(.title3)
                                        .fontWeight(.medium)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color(.systemGray5))
                            .cornerRadius(8)
                        }
                        
                        // Manual input
                        VStack(spacing: 16) {
                            // Rest Timer Display
                            if activeWorkout.restTimer.isRunning {
                                VStack(spacing: 8) {
                                    Text("REST TIME")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.blue)
                                    
                                    Text(activeWorkout.restTimer.formattedTime)
                                        .font(.largeTitle)
                                        .fontWeight(.bold)
                                        .monospacedDigit()
                                        .foregroundColor(.blue)
                                    
                                    HStack(spacing: 16) {
                                        Button("Pause") {
                                            activeWorkout.restTimer.pause()
                                        }
                                        .buttonStyle(.bordered)
                                        
                                        Button("Stop") {
                                            activeWorkout.restTimer.stop()
                                        }
                                        .buttonStyle(.bordered)
                                    }
                                }
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(12)
                            } else if activeWorkout.restTimer.timeRemaining > 0 {
                                VStack(spacing: 8) {
                                    Text("REST PAUSED")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.orange)
                                    
                                    Text(activeWorkout.restTimer.formattedTime)
                                        .font(.largeTitle)
                                        .fontWeight(.bold)
                                        .monospacedDigit()
                                        .foregroundColor(.orange)
                                    
                                    Button("Resume") {
                                        activeWorkout.restTimer.resume()
                                    }
                                    .buttonStyle(.borderedProminent)
                                }
                                .padding()
                                .background(Color.orange.opacity(0.1))
                                .cornerRadius(12)
                            }
                            
                            HStack(spacing: 20) {
                                VStack {
                                    Text("Weight (kg)")
                                        .font(.headline)
                                    TextField("0.0", text: $weightInput)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .keyboardType(.decimalPad)
                                        .font(.title2)
                                        .multilineTextAlignment(.center)
                                }
                                
                                VStack {
                                    Text("Reps")
                                        .font(.headline)
                                    TextField("reps", text: $repsInput)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .keyboardType(.numberPad)
                                        .font(.title2)
                                        .multilineTextAlignment(.center)
                                }
                            }
                            
                            Button("ADD SET") {
                                addSet()
                            }
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(canAddSet ? Color.blue : Color.gray)
                            .cornerRadius(8)
                            .disabled(!canAddSet)
                            
                            // Rest Timer Controls (when not already running)
                            if !activeWorkout.restTimer.isRunning && activeWorkout.restTimer.timeRemaining == 0 {
                                VStack(spacing: 8) {
                                    Text("Start Rest Timer")
                                        .font(.headline)
                                        .fontWeight(.medium)
                                    
                                    HStack(spacing: 12) {
                                        Button("1m") {
                                            activeWorkout.restTimer.start(duration: 60)
                                        }
                                        .buttonStyle(.bordered)
                                        
                                        Button("2m") {
                                            activeWorkout.restTimer.start(duration: 120)
                                        }
                                        .buttonStyle(.bordered)
                                        
                                        Button("3m") {
                                            activeWorkout.restTimer.start(duration: 180)
                                        }
                                        .buttonStyle(.bordered)
                                        
                                        Button("5m") {
                                            activeWorkout.restTimer.start(duration: 300)
                                        }
                                        .buttonStyle(.bordered)
                                    }
                                }
                                .padding(.top, 8)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        
                        Spacer(minLength: 100)
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
        .onAppear {
            loadLastWorkoutData()
        }
        .onChange(of: activeWorkout.currentExerciseIndex) { _ in
            loadLastWorkoutData()
            clearInputs()
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
    
    private var canAddSet: Bool {
        guard let weight = Double(weightInput), let reps = Int(repsInput) else { return false }
        return weight > 0 && reps > 0
    }
    
    private func addSet() {
        guard let currentExercise = activeWorkout.currentExercise,
              let weight = Double(weightInput),
              let reps = Int(repsInput),
              weight > 0, reps > 0 else { return }
        
        activeWorkout.addSet(
            exerciseId: currentExercise.exercise.id,
            reps: reps,
            weight: weight
        )
        
        clearInputs()
    }
    
    private func clearInputs() {
        weightInput = ""
        repsInput = ""
    }
    
    private func loadLastWorkoutData() {
        guard let currentExercise = activeWorkout.currentExercise else { return }
        
        Task {
            do {
                let data = try await workoutDataManager.getPreviousSessionData(for: currentExercise.exercise.id)
                await MainActor.run {
                    lastWorkoutSets = data?.sets ?? []
                }
            } catch {
                await MainActor.run {
                    lastWorkoutSets = []
                }
                print("Failed to load last workout data: \(error)")
            }
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

struct ExerciseTab: View {
    let exercise: Exercise
    let isSelected: Bool
    let isCompleted: Bool
    let setCount: Int
    let action: () -> Void
    
    @EnvironmentObject var exerciseDataManager: ExerciseDataManager
    
    var muscleGroupEmoji: String {
        exerciseDataManager.getMuscleGroup(for: exercise.id)?.emoji ?? "💪"
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                // Muscle group emoji
                Text(muscleGroupEmoji)
                    .font(.system(size: 16))
                
                // Exercise name
                Text(exercise.name)
                    .font(.system(size: isSelected ? 13 : 11, weight: isSelected ? .bold : .semibold))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Progress indicator
                HStack(spacing: 2) {
                    if isCompleted {
                        Text("\(setCount) sets")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(isSelected ? .white : .green)
                    } else {
                        Text("0 sets")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                
                // Bottom indicator bar
                Rectangle()
                    .fill(isSelected ? Color.white : (isCompleted ? Color.green : Color.gray.opacity(0.3)))
                    .frame(height: 3)
                    .cornerRadius(1.5)
            }
            .frame(width: 80, height: 90)
            .padding(.horizontal, 8)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue : (isCompleted ? Color.green.opacity(0.1) : Color(.systemGray6)))
            )
            .foregroundColor(isSelected ? .white : .primary)
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

