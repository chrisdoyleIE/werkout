import SwiftUI

struct LiveWorkoutView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var activeWorkout: ActiveWorkout
    @EnvironmentObject var workoutDataManager: WorkoutDataManager
    @EnvironmentObject var exerciseDataManager: ExerciseDataManager
    
    @State private var weightInput: String = ""
    @State private var repsInput: String = ""
    @State private var durationInput: String = ""
    @State private var wentToFailure: Bool = false
    @State private var lastWorkoutSets: [WorkoutSet] = []
    @State private var showingFinishConfirmation = false
    
    // Simple timer states
    @State private var restTimeRemaining: Int = 0
    @State private var restTimer: Timer?
    @State private var exerciseTimeElapsed: Int = 0
    @State private var exerciseTimer: Timer?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with workout info
            VStack(spacing: 12) {
                HStack {
                    Button("Finish") {
                        showingFinishConfirmation = true
                    }
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.accentRed)
                    
                    Spacer()
                    
                    Text(formatElapsedTime())
                        .font(.system(size: 17, weight: .semibold))
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
                                    activeWorkout.currentExerciseIndex = index
                                    loadLastWorkoutData()
                                    clearInputs()
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    
                    // Visual separator between tabs and content
                    Rectangle()
                        .fill(Color(.systemGray4))
                        .frame(height: 1)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
            
            if let currentExercise = activeWorkout.currentExercise {
                ScrollView {
                    VStack(spacing: 16) {
                        
                        // Last workout data - full display
                        if !lastWorkoutSets.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("LAST WORKOUT")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .textCase(.uppercase)
                                
                                ForEach(lastWorkoutSets.sorted(by: { $0.setNumber < $1.setNumber }), id: \.id) { set in
                                    Text("Set \(set.setNumber): \(formatSetDisplay(set))")
                                        .font(.system(size: 15, weight: .medium))
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
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.primary)
                                    .textCase(.uppercase)
                                
                                ForEach(currentExercise.sets.sorted(by: { $0.setNumber < $1.setNumber }), id: \.id) { set in
                                    HStack {
                                        Text("Set \(set.setNumber): \(formatSetDisplay(set))")
                                            .font(.system(size: 15, weight: .medium))
                                        
                                        Spacer()
                                        
                                        Button(action: {
                                            deleteSet(set)
                                        }) {
                                            Image(systemName: "trash")
                                                .font(.system(size: 15))
                                                .foregroundColor(.accentRed)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
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
                            if restTimeRemaining > 0 {
                                VStack(spacing: 8) {
                                    Text("REST TIME")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.secondary)
                                        .textCase(.uppercase)
                                    
                                    Text(formatTime(restTimeRemaining))
                                        .font(.system(size: 32, weight: .semibold))
                                        .monospacedDigit()
                                        .foregroundColor(.primary)
                                    
                                    Button("Skip Rest") {
                                        stopRestTimer()
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color(.systemGray6))
                                    .foregroundColor(.primary)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color(.systemGray4), lineWidth: 1)
                                    )
                                }
                                .padding()
                                .background(Color(.systemGray6))
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
                            
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        
                        Spacer(minLength: 60)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
            } else {
                Spacer()
                Text("No exercises selected")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
        .onAppear {
            Logger.debug("LiveWorkoutView: onAppear - activeWorkout.isActive: \(activeWorkout.isActive), exercises: \(activeWorkout.exercises.count)", category: Logger.workout)
            loadLastWorkoutData()
        }
        .onDisappear {
            Logger.debug("LiveWorkoutView: onDisappear - activeWorkout.isActive: \(activeWorkout.isActive)", category: Logger.workout)
        }
        .onChange(of: activeWorkout.currentExerciseIndex) { _ in
            loadLastWorkoutData()
            clearInputs()
            stopExerciseTimer() // Stop exercise timer when switching exercises
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
    
    
    private func addSet() {
        guard let currentExercise = activeWorkout.currentExercise,
              let weight = Double(weightInput),
              let reps = Int(repsInput),
              weight > 0, reps > 0 else { return }
        
        // Dismiss keyboard
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        
        activeWorkout.addSet(
            exerciseId: currentExercise.exercise.id,
            reps: reps,
            weight: weight,
            wentToFailure: wentToFailure
        )
        
        clearInputs()
        startRestTimer(duration: 90) // Auto-start rest timer
    }
    
    private func clearInputs() {
        weightInput = ""
        repsInput = ""
        durationInput = ""
        wentToFailure = false
    }
    
    private func addBodyweightSet() {
        guard let currentExercise = activeWorkout.currentExercise,
              let reps = Int(repsInput),
              reps > 0 else { return }
        
        // Dismiss keyboard
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        
        activeWorkout.addBodyweightSet(
            exerciseId: currentExercise.exercise.id,
            reps: reps,
            wentToFailure: wentToFailure
        )
        
        clearInputs()
        startRestTimer(duration: 90) // Auto-start rest timer
    }
    
    // MARK: - Simple Timer Methods
    
    private func startRestTimer(duration: Int) {
        stopRestTimer() // Stop any existing timer
        restTimeRemaining = duration
        restTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if restTimeRemaining > 0 {
                restTimeRemaining -= 1
            } else {
                stopRestTimer()
            }
        }
    }
    
    private func stopRestTimer() {
        restTimer?.invalidate()
        restTimer = nil
        restTimeRemaining = 0
    }
    
    private func startExerciseTimer() {
        stopExerciseTimer() // Stop any existing timer
        exerciseTimeElapsed = 0
        exerciseTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            exerciseTimeElapsed += 1
        }
    }
    
    private func stopExerciseTimer() {
        exerciseTimer?.invalidate()
        exerciseTimer = nil
        exerciseTimeElapsed = 0
    }
    
    private func recordTimedExercise() {
        guard let currentExercise = activeWorkout.currentExercise else { return }
        
        activeWorkout.addTimedSet(
            exerciseId: currentExercise.exercise.id,
            durationSeconds: exerciseTimeElapsed
        )
        
        stopExerciseTimer()
        startRestTimer(duration: 60) // Auto-start rest timer
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let seconds = seconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func deleteSet(_ set: WorkoutSet) {
        activeWorkout.deleteSet(set)
    }
    
    private func formatSetDisplay(_ set: WorkoutSet) -> String {
        var display = ""
        
        if let weight = set.weightKg, let reps = set.reps {
            // Weight-based exercise
            display = "\(String(format: "%.1f", weight))kg × \(reps)"
        } else if let reps = set.reps {
            // Bodyweight exercise
            display = "\(reps) reps"
        } else if let duration = set.durationSeconds {
            // Timed exercise
            let minutes = duration / 60
            let seconds = duration % 60
            if minutes > 0 {
                display = "\(minutes)m \(seconds)s"
            } else {
                display = "\(seconds)s"
            }
        } else {
            display = "Unknown"
        }
        
        // Add failure indicator
        if set.wentToFailure {
            display += " 🔥"
        }
        
        return display
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
        Logger.debug("LiveWorkoutView: finishWorkout called, dismissing view", category: Logger.workout)
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
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    TextField("0", text: $weightInput)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 17))
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Reps")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    TextField("0", text: $repsInput)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)
                        .font(.system(size: 17))
                }
                
                // Failure toggle - flame icon
                VStack(alignment: .center, spacing: 8) {
                    Text("Failure")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        wentToFailure.toggle()
                    }) {
                        Image(systemName: wentToFailure ? "flame.circle.fill" : "flame.circle")
                            .font(.system(size: 24))
                            .foregroundColor(wentToFailure ? .accentRed : .secondary.opacity(0.5))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            Button(action: addSet) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                    Text("Add Set")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(canAddSet ? Color.black : Color(.systemGray4))
                .cornerRadius(12)
            }
            .disabled(!canAddSet)
        }
    }
    
    @ViewBuilder
    private func bodyweightExerciseInput() -> some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Reps")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    TextField("0", text: $repsInput)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)
                        .font(.system(size: 17))
                }
                
                // Failure toggle - flame icon
                VStack(alignment: .center, spacing: 8) {
                    Text("Failure")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        wentToFailure.toggle()
                    }) {
                        Image(systemName: wentToFailure ? "flame.circle.fill" : "flame.circle")
                            .font(.system(size: 24))
                            .foregroundColor(wentToFailure ? .accentRed : .secondary.opacity(0.5))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            Button(action: addBodyweightSet) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                    Text("Add Set")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(canAddBodyweightSet ? Color.black : Color(.systemGray4))
                .cornerRadius(12)
            }
            .disabled(!canAddBodyweightSet)
        }
    }
    
    @ViewBuilder
    private func timedExerciseInput() -> some View {
        VStack(spacing: 16) {
            // Exercise Timer Display
            if exerciseTimer != nil {
                VStack(spacing: 12) {
                    Text("EXERCISE TIMER")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    
                    Text(formatTime(exerciseTimeElapsed))
                        .font(.system(size: 32, weight: .semibold))
                        .monospacedDigit()
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 16) {
                        Button("Stop & Record") {
                            recordTimedExercise()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.black)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            } else {
                // Timer controls
                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        Button("30s") {
                            startExerciseTimer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                        .foregroundColor(.primary)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                        
                        Button("60s") {
                            startExerciseTimer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                        .foregroundColor(.primary)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                        
                        Button("90s") {
                            startExerciseTimer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                        .foregroundColor(.primary)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                    }
                    
                    Button("Start Timer") {
                        startExerciseTimer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.black)
                    .foregroundColor(.white)
                    .cornerRadius(8)
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
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                // Exercise name
                Text(exercise.name)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundColor(isSelected ? .white : .primary)
                
                // Progress indicator
                Text(isCompleted ? "\(setCount) sets" : "0 sets")
                    .font(.system(size: 11))
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                
                // Bottom indicator bar
                Rectangle()
                    .fill(isSelected ? Color.accentRed : (isCompleted ? Color.primary : Color(.systemGray4)))
                    .frame(height: 2)
                    .cornerRadius(1)
            }
            .frame(width: 80, height: 65)
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.primary : Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.systemGray4), lineWidth: isSelected ? 0 : 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

