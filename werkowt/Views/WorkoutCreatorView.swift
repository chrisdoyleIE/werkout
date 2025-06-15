import SwiftUI

struct WorkoutCreatorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var activeWorkout: ActiveWorkout
    @EnvironmentObject var exerciseDataManager: ExerciseDataManager
    
    @State private var selectedExercises: Set<String> = []
    @State private var selectedMuscleGroups: Set<String> = []
    @State private var isCreatingWorkout = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        if !selectedMuscleGroups.isEmpty {
                            Text(generatedWorkoutName)
                                .font(.largeTitle)
                                .fontWeight(.black)
                                .foregroundColor(.blue)
                                .multilineTextAlignment(.center)
                        } else {
                            Text("Choose Muscle Groups")
                                .font(.largeTitle)
                                .fontWeight(.black)
                        }
                        
                        if selectedExercises.count > 0 {
                            Text("\(selectedExercises.count) exercise\(selectedExercises.count == 1 ? "" : "s") selected")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top)
                    
                    // Muscle Group Grid
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                        ForEach(exerciseDataManager.muscleGroups, id: \.id) { muscleGroup in
                            MuscleGroupCard(
                                muscleGroup: muscleGroup,
                                isSelected: selectedMuscleGroups.contains(muscleGroup.id),
                                exerciseCount: muscleGroup.exercises.count
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    if selectedMuscleGroups.contains(muscleGroup.id) {
                                        selectedMuscleGroups.remove(muscleGroup.id)
                                    } else {
                                        selectedMuscleGroups.insert(muscleGroup.id)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Exercise Selection (only show if muscle groups selected)
                    if !selectedMuscleGroups.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Select Exercises")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Spacer()
                                
                                if !selectedExercises.isEmpty {
                                    Button("Clear All") {
                                        withAnimation(.easeInOut) {
                                            selectedExercises.removeAll()
                                        }
                                    }
                                    .font(.subheadline)
                                    .foregroundColor(.red)
                                }
                            }
                            .padding(.horizontal)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 1), spacing: 8) {
                                ForEach(filteredExercises, id: \.id) { exercise in
                                    ExerciseCard(
                                        exercise: exercise,
                                        isSelected: selectedExercises.contains(exercise.id)
                                    ) {
                                        withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
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
                
                    // Start Button (floating at bottom)
                    if canStartWorkout {
                        Button(action: startWorkout) {
                            HStack {
                                if isCreatingWorkout {
                                    SwiftUI.ProgressView()
                                        .scaleEffect(0.8)
                                        .tint(.white)
                                } else {
                                    Image(systemName: "play.fill")
                                        .font(.title3)
                                }
                                Text(isCreatingWorkout ? "Starting..." : "Start Workout")
                                    .font(.title3)
                                    .fontWeight(.bold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [Color.blue, Color.blue.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .disabled(isCreatingWorkout)
                        .padding(.horizontal)
                        .padding(.bottom)
                    }
                    
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.headline)
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
    
    private var generatedWorkoutName: String {
        let selectedGroupNames = selectedMuscleGroups.compactMap { groupId in
            exerciseDataManager.muscleGroups.first { $0.id == groupId }?.name
        }.sorted()
        
        if selectedGroupNames.isEmpty {
            return "Custom Workout"
        } else if selectedGroupNames.count == 1 {
            return "\(selectedGroupNames[0]) Day"
        } else if selectedGroupNames.count == 2 {
            return "\(selectedGroupNames.joined(separator: " & "))"
        } else {
            return "\(selectedGroupNames.prefix(2).joined(separator: " & ")) + \(selectedGroupNames.count - 2) more"
        }
    }
    
    private var canStartWorkout: Bool {
        !selectedExercises.isEmpty
    }
    
    private func startWorkout() {
        let exercises = selectedExercises.compactMap { exerciseDataManager.getExercise(by: $0) }
        
        isCreatingWorkout = true
        errorMessage = ""
        
        Task {
            do {
                try await activeWorkout.startWorkout(name: generatedWorkoutName, exercises: exercises)
                
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

struct MuscleGroupCard: View {
    let muscleGroup: MuscleGroup
    let isSelected: Bool
    let exerciseCount: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                // Emoji
                Text(muscleGroup.emoji)
                    .font(.system(size: 40))
                
                // Name
                Text(muscleGroup.name)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(isSelected ? .white : .primary)
                
                // Exercise count
                Text("\(exerciseCount) exercises")
                    .font(.caption)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? 
                          LinearGradient(colors: [Color.blue, Color.blue.opacity(0.8)], 
                                       startPoint: .topLeading, endPoint: .bottomTrailing) :
                          LinearGradient(colors: [Color(.systemGray6)], 
                                       startPoint: .topLeading, endPoint: .bottomTrailing))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 2)
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .shadow(color: isSelected ? .blue.opacity(0.2) : .clear, radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ExerciseCard: View {
    let exercise: Exercise
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .secondary)
                
                // Exercise name
                Text(exercise.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(isSelected ? .white : .primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Arrow or check
                Image(systemName: "chevron.right")
                    .font(.subheadline)
                    .foregroundColor(isSelected ? .white.opacity(0.7) : .secondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue : Color(.systemGray6))
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}