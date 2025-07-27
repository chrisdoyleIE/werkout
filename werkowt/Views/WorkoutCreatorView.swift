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
    
    // New filtering and search states
    @State private var searchQuery = ""
    @State private var selectedEquipment: Set<ExerciseEquipment> = []
    @State private var expandedSections: Set<String> = []
    @State private var selectedMuscleGroupTab: String = ""
    
    var body: some View {
        ZStack(alignment: .bottom) {
            NavigationView {
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 8) {
                            if !selectedMuscleGroups.isEmpty {
                                VStack(spacing: 4) {
                                    Text("Your Workout")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.secondary)
                                        .textCase(.uppercase)
                                    
                                    Text(generatedWorkoutName)
                                        .font(.system(size: 28, weight: .semibold))
                                        .foregroundColor(.primary)
                                        .multilineTextAlignment(.center)
                                }
                            } else {
                                VStack(spacing: 4) {
                                    Text("Create Workout")
                                        .font(.system(size: 28, weight: .semibold))
                                    
                                    Text("Select muscle groups to target")
                                        .font(.system(size: 15))
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            if selectedExercises.count > 0 {
                                HStack(spacing: 6) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.primary)
                                        .font(.caption)
                                    
                                    Text("\(selectedExercises.count) exercise\(selectedExercises.count == 1 ? "" : "s") ready")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.primary)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            }
                        }
                        .padding(.top)
                        
                        // Log Gym Class Button - Only show when no muscle groups selected
                        if selectedMuscleGroups.isEmpty {
                            Button(action: {
                                showingClassLogger = true
                            }) {
                                HStack {
                                    Image(systemName: "figure.strengthtraining.functional")
                                        .font(.system(size: 20))
                                    Text("LOG GYM CLASS")
                                        .font(.system(size: 17, weight: .semibold))
                                }
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            }
                            .padding(.horizontal)
                        }
                        
                        // OR Divider
                        if selectedMuscleGroups.isEmpty {
                            HStack {
                                VStack(spacing: 4) {
                                    Rectangle()
                                        .fill(Color(.systemGray4))
                                        .frame(height: 1)
                                    
                                    Text("OR")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, 12)
                                        .background(Color(.systemBackground))
                                    
                                    Rectangle()
                                        .fill(Color(.systemGray4))
                                        .frame(height: 1)
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Muscle Group Selection - Two Column Layout
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 8),
                            GridItem(.flexible(), spacing: 8)
                        ], spacing: 8) {
                            ForEach(exerciseDataManager.muscleGroups, id: \.id) { muscleGroup in
                                MuscleGroupRow(
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
                        
                        // Exercise Selection (only show if muscle groups selected)
                        if !selectedMuscleGroups.isEmpty {
                            VStack(alignment: .leading, spacing: 0) {
                                // Choose Your Exercises header with Clear All
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Choose Your Exercises")
                                            .font(.system(size: 20, weight: .semibold))
                                        
                                        if selectedExercises.isEmpty {
                                            Text("Tap exercises below to add them to your workout")
                                                .font(.system(size: 13))
                                                .foregroundColor(.secondary)
                                        } else {
                                            Text("\(selectedExercises.count) exercise\(selectedExercises.count == 1 ? "" : "s") selected")
                                                .font(.system(size: 13))
                                                .foregroundColor(.accentRed)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    if !selectedExercises.isEmpty {
                                        Button("Clear All") {
                                            selectedExercises.removeAll()
                                        }
                                        .font(.system(size: 15))
                                        .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.bottom, 12)
                                
                                // Muscle Group Tabs
                                let sortedMuscleGroups = selectedMuscleGroups.sorted()
                                
                                // Tab selector
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(sortedMuscleGroups, id: \.self) { muscleGroupId in
                                            if let muscleGroup = exerciseDataManager.muscleGroups.first(where: { $0.id == muscleGroupId }) {
                                                Button(action: {
                                                    selectedMuscleGroupTab = muscleGroupId
                                                    // Clear search and filters when switching tabs
                                                    searchQuery = ""
                                                    selectedEquipment.removeAll()
                                                }) {
                                                    Text(muscleGroup.name)
                                                        .font(.system(size: 15, weight: selectedMuscleGroupTab == muscleGroupId ? .semibold : .medium))
                                                        .foregroundColor(selectedMuscleGroupTab == muscleGroupId ? .white : .primary)
                                                        .padding(.horizontal, 16)
                                                        .padding(.vertical, 8)
                                                        .background(
                                                            RoundedRectangle(cornerRadius: 16)
                                                                .fill(selectedMuscleGroupTab == muscleGroupId ? Color.primary : Color(.systemGray6))
                                                        )
                                                }
                                                .buttonStyle(PlainButtonStyle())
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                                .padding(.bottom, 12)
                                
                                // Content for selected tab
                                if !selectedMuscleGroupTab.isEmpty,
                                   let selectedMuscleGroup = exerciseDataManager.muscleGroups.first(where: { $0.id == selectedMuscleGroupTab }) {
                                    
                                    VStack(spacing: 0) {
                                        // Search and filters for selected muscle group
                                        VStack(spacing: 12) {
                                            // Search Bar
                                            HStack {
                                                Image(systemName: "magnifyingglass")
                                                    .foregroundColor(.secondary)
                                                TextField("Search \(selectedMuscleGroup.name) exercises...", text: $searchQuery)
                                                    .textFieldStyle(PlainTextFieldStyle())
                                            }
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(Color(.systemGray6))
                                            .cornerRadius(8)
                                            
                                            // Equipment Filter
                                            ScrollView(.horizontal, showsIndicators: false) {
                                                HStack(spacing: 8) {
                                                    Text("Equipment:")
                                                        .font(.system(size: 13))
                                                        .foregroundColor(.secondary)
                                                    
                                                    ForEach(ExerciseEquipment.allCases, id: \.self) { equipment in
                                                        FilterTab(
                                                            title: equipment.displayName,
                                                            isSelected: selectedEquipment.contains(equipment)
                                                        ) {
                                                            if selectedEquipment.contains(equipment) {
                                                                selectedEquipment.remove(equipment)
                                                            } else {
                                                                selectedEquipment.insert(equipment)
                                                            }
                                                        }
                                                    }
                                                    
                                                    if !selectedEquipment.isEmpty {
                                                        Button("Clear") {
                                                            selectedEquipment.removeAll()
                                                        }
                                                        .font(.system(size: 13))
                                                        .foregroundColor(.primary)
                                                    }
                                                }
                                            }
                                        }
                                        .padding(.horizontal)
                                        .padding(.vertical, 12)
                                        
                                        // Exercise list for selected muscle group
                                        ScrollView {
                                            CategorySection(
                                                muscleGroup: selectedMuscleGroup,
                                                selectedExercises: $selectedExercises,
                                                expandedSections: $expandedSections,
                                                searchQuery: searchQuery,
                                                selectedEquipment: selectedEquipment
                                            )
                                            .padding(.bottom, 140) // Extra space for floating button
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Add bottom padding to prevent content from being hidden by floating button
                        if canStartWorkout {
                            Spacer()
                                .frame(height: 80)
                        }
                        
                        if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.bottom, 120) // Ensure space for floating button
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                        .font(.system(size: 17, weight: .medium))
                    }
                }
                .onChange(of: selectedMuscleGroups) { newValue in
                    // Auto-select first tab when muscle groups change
                    if !newValue.isEmpty && (selectedMuscleGroupTab.isEmpty || !newValue.contains(selectedMuscleGroupTab)) {
                        selectedMuscleGroupTab = newValue.sorted().first ?? ""
                    } else if newValue.isEmpty {
                        selectedMuscleGroupTab = ""
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
            
            // Floating Start Button - show when muscle groups selected, enable when exercises selected
            if !selectedMuscleGroups.isEmpty {
                    VStack {
                        Spacer()
                        
                        // Background overlay for better button visibility
                        VStack(spacing: 0) {
                            // Gradient overlay
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(.systemBackground).opacity(0),
                                    Color(.systemBackground).opacity(0.8),
                                    Color(.systemBackground)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: 40)
                            
                            // Button area with solid background
                            VStack {
                                Button(action: startWorkout) {
                                    HStack {
                                        if isCreatingWorkout {
                                            SwiftUI.ProgressView()
                                                .scaleEffect(0.8)
                                                .tint(.white)
                                        } else {
                                            Image(systemName: "play.fill")
                                                .font(.system(size: 18))
                                        }
                                        Text(isCreatingWorkout ? "Starting..." : 
                                             selectedExercises.isEmpty ? "Select exercises to start" : "Start \(generatedWorkoutName)")
                                            .font(.system(size: 17, weight: .semibold))
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(selectedExercises.isEmpty ? Color.gray : Color.accentRed)
                                    .cornerRadius(12)
                                    .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 6)
                                }
                                .disabled(isCreatingWorkout || selectedExercises.isEmpty)
                                .padding(.horizontal, 20)
                                .padding(.bottom, 40) // Safe area bottom padding
                            }
                            .background(Color(.systemBackground))
                        }
                    }
                    .zIndex(1000) // Ensure button is always on top
                }
        }
    }
    
    // MARK: - Private Methods
    
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

struct MuscleGroupRow: View {
    let muscleGroup: MuscleGroup
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(muscleGroup.name)
                    .font(.system(size: 17, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(isSelected ? .primary : .primary.opacity(0.8))
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.accentRed)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color(.systemGray6) : Color(.systemGray6).opacity(0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accentRed.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}


struct FilterTab: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.primary : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(8)
        }
    }
}

struct CategorySection: View {
    let muscleGroup: MuscleGroup
    @Binding var selectedExercises: Set<String>
    @Binding var expandedSections: Set<String>
    let searchQuery: String
    let selectedEquipment: Set<ExerciseEquipment>
    
    @EnvironmentObject var exerciseDataManager: ExerciseDataManager
    
    private var filteredExercises: [EnhancedExercise] {
        return exerciseDataManager.filterExercises(
            muscleGroups: [muscleGroup.id],
            equipment: selectedEquipment,
            categories: [],
            searchQuery: searchQuery
        )
    }
    
    private var exercisesByCategory: [ExerciseCategory: [EnhancedExercise]] {
        return Dictionary(grouping: filteredExercises) { $0.category }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Exercise count
            if filteredExercises.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    
                    Text("No exercises found")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    if !searchQuery.isEmpty {
                        Text("Try adjusting your search or filters")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                Text("\(filteredExercises.count) exercises")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                // Exercise List
                VStack(spacing: 8) {
                    ForEach(filteredExercises, id: \.id) { exercise in
                        CleanExerciseCard(
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
                .padding(.horizontal)
            }
        }
    }
}

struct CleanExerciseCard: View {
    let exercise: EnhancedExercise
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .primary : Color(.systemGray3))
                
                VStack(alignment: .leading, spacing: 4) {
                    // Exercise name
                    Text(exercise.name)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Equipment
                    Text(exercise.equipment.displayName)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.primary : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

