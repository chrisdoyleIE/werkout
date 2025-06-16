import SwiftUI

struct WorkoutCreatorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var activeWorkout: ActiveWorkout
    @EnvironmentObject var exerciseDataManager: ExerciseDataManager
    @EnvironmentObject var workoutDataManager: WorkoutDataManager
    
    @State private var selectedExercises: Set<String> = []
    @State private var selectedMuscleGroups: Set<String> = []
    @State private var isCreatingWorkout = false
    @State private var showingClassLogger = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        if !selectedMuscleGroups.isEmpty {
                            VStack(spacing: 4) {
                                Text("Your Workout")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                    .textCase(.uppercase)
                                    .tracking(1)
                                
                                Text(generatedWorkoutName)
                                    .font(.largeTitle)
                                    .fontWeight(.black)
                                    .foregroundColor(.blue)
                                    .multilineTextAlignment(.center)
                            }
                        } else {
                            VStack(spacing: 4) {
                                Text("Create Workout")
                                    .font(.largeTitle)
                                    .fontWeight(.black)
                                
                                Text("Select muscle groups to target")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        if selectedExercises.count > 0 {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.caption)
                                
                                Text("\(selectedExercises.count) exercise\(selectedExercises.count == 1 ? "" : "s") ready")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.green)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(12)
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
                    
                    // Log Gym Class Button (show only if no muscle groups selected)
                    if selectedMuscleGroups.isEmpty {
                        VStack(spacing: 16) {
                            HStack {
                                VStack(spacing: 4) {
                                    Rectangle()
                                        .fill(Color(.systemGray4))
                                        .frame(height: 1)
                                    
                                    Text("OR")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, 12)
                                        .background(Color(.systemBackground))
                                    
                                    Rectangle()
                                        .fill(Color(.systemGray4))
                                        .frame(height: 1)
                                }
                            }
                            .padding(.horizontal)
                            
                            Button(action: {
                                showingClassLogger = true
                            }) {
                                HStack {
                                    Image(systemName: "figure.strengthtraining.functional")
                                        .font(.title3)
                                    Text("LOG GYM CLASS")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.purple)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.purple.opacity(0.1))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                                )
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Exercise Selection (only show if muscle groups selected)
                    if !selectedMuscleGroups.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Choose Your Exercises")
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
                                Text(isCreatingWorkout ? "Starting..." : "Start \(generatedWorkoutName)")
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
            .sheet(isPresented: $showingClassLogger) {
                QuickClassLoggerView(onComplete: {
                    // Dismiss the WorkoutCreatorView after gym class is logged
                    dismiss()
                })
                .environmentObject(workoutDataManager)
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
    
    var muscleGroupIcon: String {
        switch muscleGroup.id {
        case "chest": return "figure.strengthtraining.traditional"
        case "back": return "figure.climbing"
        case "legs": return "figure.walk"
        case "core": return "scope"
        case "arms": return "dumbbell.fill"
        case "shoulders": return "arrow.up.and.down.and.arrow.left.and.right"
        default: return "dumbbell.fill"
        }
    }
    
    var muscleGroupColor: Color {
        switch muscleGroup.id {
        case "chest": return .blue
        case "back": return .blue
        case "legs": return .blue
        case "core": return .blue
        case "arms": return .blue
        case "shoulders": return .blue
        default: return .gray
        }
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                // Icon in colored circle
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.white.opacity(0.2) : muscleGroupColor.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: muscleGroupIcon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(isSelected ? .white : muscleGroupColor)
                }
                
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
                          LinearGradient(colors: [muscleGroupColor, muscleGroupColor.opacity(0.8)], 
                                       startPoint: .topLeading, endPoint: .bottomTrailing) :
                          LinearGradient(colors: [Color(.systemGray6)], 
                                       startPoint: .topLeading, endPoint: .bottomTrailing))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? muscleGroupColor.opacity(0.3) : Color.clear, lineWidth: 2)
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .shadow(color: isSelected ? muscleGroupColor.opacity(0.3) : .clear, radius: 8, x: 0, y: 4)
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
