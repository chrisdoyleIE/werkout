import SwiftUI

struct WorkoutCreatorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var activeWorkout: ActiveWorkout
    @EnvironmentObject var exerciseDataManager: ExerciseDataManager
    
    @State private var workoutName = ""
    @State private var selectedExercises: Set<String> = []
    @State private var selectedMuscleGroups: Set<String> = []
    @State private var isCreatingWorkout = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Workout Name
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("1. Name Your Workout")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        if !workoutName.isEmpty {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                    
                    TextField("e.g., Chest & Triceps", text: $workoutName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    if workoutName.isEmpty {
                        Text("Give your workout a descriptive name")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                
                Divider()
                
                // Muscle Group Selection
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("2. Choose Muscle Groups")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        if !selectedMuscleGroups.isEmpty {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                    .padding(.horizontal)
                    
                    if selectedMuscleGroups.isEmpty {
                        Text("Tap muscle groups to filter exercises (select multiple)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    } else {
                        Text("Selected: \(selectedMuscleGroups.count) muscle group\(selectedMuscleGroups.count == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundColor(.blue)
                            .padding(.horizontal)
                    }
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(exerciseDataManager.muscleGroups, id: \.id) { muscleGroup in
                                MuscleGroupChip(
                                    muscleGroup: muscleGroup,
                                    isSelected: selectedMuscleGroups.contains(muscleGroup.id)
                                ) {
                                    if selectedMuscleGroups.contains(muscleGroup.id) {
                                        selectedMuscleGroups.remove(muscleGroup.id)
                                    } else {
                                        selectedMuscleGroups.insert(muscleGroup.id)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
                
                Divider()
                
                // Exercise Selection
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("3. Select Exercises")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        if !selectedExercises.isEmpty {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                    .padding(.horizontal)
                    
                    HStack {
                        if selectedExercises.isEmpty {
                            Text("Choose exercises for your workout")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("\(selectedExercises.count) exercise\(selectedExercises.count == 1 ? "" : "s") selected")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        
                        Spacer()
                        
                        if !selectedExercises.isEmpty {
                            Button("Clear All") {
                                selectedExercises.removeAll()
                            }
                            .font(.caption)
                            .foregroundColor(.red)
                        }
                    }
                    .padding(.horizontal)
                    
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            if filteredExercises.isEmpty && !selectedMuscleGroups.isEmpty {
                                VStack(spacing: 8) {
                                    Image(systemName: "questionmark.circle")
                                        .font(.largeTitle)
                                        .foregroundColor(.secondary)
                                    Text("No exercises found")
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                    Text("Try selecting different muscle groups")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                            } else {
                                ForEach(filteredExercises, id: \.id) { exercise in
                                    ExerciseSelectionRow(
                                        exercise: exercise,
                                        isSelected: selectedExercises.contains(exercise.id)
                                    ) {
                                        if selectedExercises.contains(exercise.id) {
                                            selectedExercises.remove(exercise.id)
                                        } else {
                                            selectedExercises.insert(exercise.id)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Start Button
                VStack(spacing: 8) {
                    if !errorMessage.isEmpty {
                        Text("❌ \(errorMessage)")
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    } else if !canStartWorkout {
                        if workoutName.isEmpty {
                            Text("⚠️ Add a workout name to continue")
                                .font(.caption)
                                .foregroundColor(.orange)
                        } else if selectedExercises.isEmpty {
                            Text("⚠️ Select at least one exercise to continue")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                    
                    Button(action: startWorkout) {
                        HStack {
                            if isCreatingWorkout {
                                SwiftUI.ProgressView()
                                    .scaleEffect(0.8)
                                    .foregroundColor(.white)
                            } else {
                                Image(systemName: "play.fill")
                            }
                            Text(isCreatingWorkout ? "CREATING..." : "START WORKOUT")
                                .fontWeight(.bold)
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canStartWorkout && !isCreatingWorkout ? Color.green : Color.gray)
                        .cornerRadius(12)
                    }
                    .disabled(!canStartWorkout || isCreatingWorkout)
                }
                .padding()
            }
            .navigationTitle("New Workout")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var filteredExercises: [Exercise] {
        if selectedMuscleGroups.isEmpty {
            return exerciseDataManager.getAllExercises()
        } else {
            return selectedMuscleGroups.flatMap { muscleGroupId in
                exerciseDataManager.getExercises(for: muscleGroupId)
            }
        }
    }
    
    private var canStartWorkout: Bool {
        !workoutName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !selectedExercises.isEmpty
    }
    
    private func startWorkout() {
        let exercises = selectedExercises.compactMap { exerciseDataManager.getExercise(by: $0) }
        
        isCreatingWorkout = true
        errorMessage = ""
        
        Task {
            do {
                try await activeWorkout.startWorkout(name: workoutName, exercises: exercises)
                
                await MainActor.run {
                    isCreatingWorkout = false
                }
            } catch {
                await MainActor.run {
                    isCreatingWorkout = false
                    errorMessage = "Failed to create workout: \(error.localizedDescription)"
                }
            }
        }
    }
}

struct MuscleGroupChip: View {
    let muscleGroup: MuscleGroup
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(muscleGroup.emoji)
                Text(muscleGroup.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color(.systemGray6))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
        }
    }
}

struct ExerciseSelectionRow: View {
    let exercise: Exercise
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(exercise.instructions)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? .blue : .secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }
}