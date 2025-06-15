import SwiftUI

struct LiveWorkoutView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var activeWorkout: ActiveWorkout
    @EnvironmentObject var workoutDataManager: WorkoutDataManager
    @EnvironmentObject var exerciseDataManager: ExerciseDataManager
    
    @State private var weightInput: String = ""
    @State private var repsInput: String = ""
    @State private var durationInput: String = ""
    @State private var exerciseTimer: ExerciseTimer = ExerciseTimer()
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
                                    Text("Set \(set.setNumber): \(formatSetDisplay(set))")
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
                                    Text("Set \(set.setNumber): \(formatSetDisplay(set))")
                                        .font(.title3)
                                        .fontWeight(.medium)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color(.systemGray5))
                            .cornerRadius(8)
                        }
                        
                        // Exercise Input
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
                            
                            // Exercise Type Specific Input
                            if let currentExercise = activeWorkout.currentExercise {
                                switch currentExercise.exercise.type {
                                case .weight:
                                    weightExerciseInput()
                                case .bodyweight:
                                    bodyweightExerciseInput()
                                case .timed:
                                    timedExerciseInput()
                                }
                            }
                            
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
    
    private var canAddBodyweightSet: Bool {
        guard let reps = Int(repsInput) else { return false }
        return reps > 0
    }
    
    private var canAddTimedSet: Bool {
        guard let duration = Int(durationInput) else { return false }
        return duration > 0
    }
    
    private var canStartTimer: Bool {
        guard let duration = Int(durationInput) else { return false }
        return duration > 0
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
        durationInput = ""
    }
    
    private func addBodyweightSet() {
        guard let currentExercise = activeWorkout.currentExercise,
              let reps = Int(repsInput),
              reps > 0 else { return }
        
        activeWorkout.addBodyweightSet(
            exerciseId: currentExercise.exercise.id,
            reps: reps
        )
        
        clearInputs()
    }
    
    private func addTimedSet() {
        let duration = exerciseTimer.totalDuration - exerciseTimer.timeRemaining
        addTimedSetWithDuration(duration)
        exerciseTimer.stop()
    }
    
    private func addTimedSetManual() {
        guard let duration = Int(durationInput),
              duration > 0 else { return }
        
        addTimedSetWithDuration(duration)
        clearInputs()
    }
    
    private func addTimedSetWithDuration(_ duration: Int) {
        guard let currentExercise = activeWorkout.currentExercise else { return }
        
        activeWorkout.addTimedSet(
            exerciseId: currentExercise.exercise.id,
            durationSeconds: duration
        )
    }
    
    private func startExerciseTimer() {
        guard let duration = Int(durationInput),
              duration > 0 else { return }
        
        exerciseTimer.start(duration: duration)
    }
    
    private func formatSetDisplay(_ set: WorkoutSet) -> String {
        if let weight = set.weightKg, let reps = set.reps {
            // Weight-based exercise
            return "\(String(format: "%.1f", weight))kg × \(reps)"
        } else if let reps = set.reps {
            // Bodyweight exercise
            return "\(reps) reps"
        } else if let duration = set.durationSeconds {
            // Timed exercise
            let minutes = duration / 60
            let seconds = duration % 60
            if minutes > 0 {
                return "\(minutes)m \(seconds)s"
            } else {
                return "\(seconds)s"
            }
        } else {
            return "Unknown"
        }
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
    
    // MARK: - Exercise Input Methods
    
    @ViewBuilder
    private func weightExerciseInput() -> some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Weight (kg)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    TextField("0", text: $weightInput)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.decimalPad)
                        .font(.title2)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Reps")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    TextField("0", text: $repsInput)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)
                        .font(.title2)
                }
            }
            
            Button(action: addSet) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                    Text("Add Set")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(canAddSet ? Color.green : Color.gray)
                .cornerRadius(12)
            }
            .disabled(!canAddSet)
        }
    }
    
    @ViewBuilder
    private func bodyweightExerciseInput() -> some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Reps")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                TextField("0", text: $repsInput)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
                    .font(.title2)
            }
            
            Button(action: addBodyweightSet) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                    Text("Add Set")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(canAddBodyweightSet ? Color.green : Color.gray)
                .cornerRadius(12)
            }
            .disabled(!canAddBodyweightSet)
        }
    }
    
    @ViewBuilder
    private func timedExerciseInput() -> some View {
        VStack(spacing: 16) {
            // Exercise Timer Display
            if exerciseTimer.isRunning {
                VStack(spacing: 12) {
                    Text("EXERCISE TIMER")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    
                    Text(exerciseTimer.formattedTime)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .monospacedDigit()
                        .foregroundColor(.orange)
                    
                    HStack(spacing: 16) {
                        Button("Pause") {
                            exerciseTimer.pause()
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Stop & Record") {
                            addTimedSet()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                    }
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
            } else if exerciseTimer.timeRemaining > 0 {
                VStack(spacing: 12) {
                    Text("EXERCISE PAUSED")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    
                    Text(exerciseTimer.formattedTime)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .monospacedDigit()
                        .foregroundColor(.orange)
                    
                    HStack(spacing: 16) {
                        Button("Resume") {
                            exerciseTimer.resume()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.orange)
                        
                        Button("Stop & Record") {
                            addTimedSet()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                    }
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
            } else {
                // Manual duration input or timer controls
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Target Duration (seconds)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        
                        TextField("30", text: $durationInput)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.numberPad)
                            .font(.title2)
                    }
                    
                    HStack(spacing: 12) {
                        Button("30s") {
                            durationInput = "30"
                            exerciseTimer.start(duration: 30)
                        }
                        .buttonStyle(.bordered)
                        
                        Button("60s") {
                            durationInput = "60"
                            exerciseTimer.start(duration: 60)
                        }
                        .buttonStyle(.bordered)
                        
                        Button("90s") {
                            durationInput = "90"
                            exerciseTimer.start(duration: 90)
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    Button(action: startExerciseTimer) {
                        HStack {
                            Image(systemName: "timer")
                                .font(.title3)
                            Text("Start Timer")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(canStartTimer ? Color.orange : Color.gray)
                        .cornerRadius(12)
                    }
                    .disabled(!canStartTimer)
                    
                    Button(action: addTimedSetManual) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                            Text("Record Duration")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(canAddTimedSet ? Color.green : Color.gray)
                        .cornerRadius(12)
                    }
                    .disabled(!canAddTimedSet)
                }
            }
        }
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

