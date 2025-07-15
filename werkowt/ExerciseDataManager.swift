import Foundation
import os

class ExerciseDataManager: ObservableObject {
    @Published var muscleGroups: [MuscleGroup] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    static let shared = ExerciseDataManager()
    
    private init() {
        loadExercises()
    }
    
    func loadExercises() {
        isLoading = true
        error = nil
        
        // Load from new ExerciseDatabase instead of JSON
        do {
            self.muscleGroups = convertEnhancedExercisesToMuscleGroups()
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    private func convertEnhancedExercisesToMuscleGroups() -> [MuscleGroup] {
        var muscleGroups: [MuscleGroup] = []
        
        // Define muscle group info
        let muscleGroupInfo: [(String, String, String)] = [
            ("chest", "Chest", "💪"),
            ("back", "Back", "🦾"),
            ("legs", "Legs", "🦵"),
            ("shoulders", "Shoulders", "🏔️"),
            ("arms", "Arms", "💪"),
            ("core", "Core", "⚡")
        ]
        
        for (id, name, emoji) in muscleGroupInfo {
            if let enhancedExercises = ExerciseDatabase.exercises[id] {
                let exercises = enhancedExercises.map { enhancedExercise in
                    Exercise(
                        id: enhancedExercise.id,
                        name: enhancedExercise.name,
                        instructions: enhancedExercise.instructions,
                        type: convertCategoryToType(enhancedExercise.category)
                    )
                }
                
                let muscleGroup = MuscleGroup(
                    id: id,
                    name: name,
                    emoji: emoji,
                    exercises: exercises
                )
                muscleGroups.append(muscleGroup)
            }
        }
        
        return muscleGroups
    }
    
    private func convertCategoryToType(_ category: ExerciseCategory) -> ExerciseType {
        switch category {
        case .bodyweight: return .bodyweight
        case .compound, .isolation: return .weight
        case .cardio: return .timed
        }
    }
    
    func getAllExercises() -> [Exercise] {
        return muscleGroups.flatMap { $0.exercises }
    }
    
    func getExercise(by id: String) -> Exercise? {
        return getAllExercises().first { $0.id == id }
    }
    
    func getExercises(for muscleGroupId: String) -> [Exercise] {
        return muscleGroups.first { $0.id == muscleGroupId }?.exercises ?? []
    }
    
    func getMuscleGroup(for exerciseId: String) -> MuscleGroup? {
        return muscleGroups.first { muscleGroup in
            muscleGroup.exercises.contains { $0.id == exerciseId }
        }
    }
    
    func searchExercises(query: String) -> [Exercise] {
        guard !query.isEmpty else { return getAllExercises() }
        
        return getAllExercises().filter { exercise in
            exercise.name.localizedCaseInsensitiveContains(query) ||
            exercise.instructions.localizedCaseInsensitiveContains(query)
        }
    }
    
    // MARK: - Enhanced Exercise Data Access
    func getEnhancedExercise(by id: String) -> EnhancedExercise? {
        for (_, exercises) in ExerciseDatabase.exercises {
            if let exercise = exercises.first(where: { $0.id == id }) {
                return exercise
            }
        }
        return nil
    }
    
    func getEnhancedExercises(for muscleGroupId: String) -> [EnhancedExercise] {
        return ExerciseDatabase.exercises[muscleGroupId] ?? []
    }
    
    func getAllEnhancedExercises() -> [EnhancedExercise] {
        return ExerciseDatabase.exercises.values.flatMap { $0 }
    }
    
    // MARK: - Filtering Methods
    func filterExercises(
        muscleGroups: [String] = [],
        equipment: Set<ExerciseEquipment> = [],
        categories: Set<ExerciseCategory> = [],
        searchQuery: String = ""
    ) -> [EnhancedExercise] {
        var exercises: [EnhancedExercise] = []
        
        // Get exercises from specified muscle groups or all if none specified
        if muscleGroups.isEmpty {
            exercises = getAllEnhancedExercises()
        } else {
            exercises = muscleGroups.flatMap { getEnhancedExercises(for: $0) }
        }
        
        // Apply equipment filter
        if !equipment.isEmpty {
            exercises = exercises.filter { equipment.contains($0.equipment) }
        }
        
        // Apply category filter
        if !categories.isEmpty {
            exercises = exercises.filter { categories.contains($0.category) }
        }
        
        
        // Apply search query
        if !searchQuery.isEmpty {
            exercises = exercises.filter { exercise in
                exercise.name.localizedCaseInsensitiveContains(searchQuery) ||
                exercise.instructions.localizedCaseInsensitiveContains(searchQuery) ||
                exercise.tips.joined(separator: " ").localizedCaseInsensitiveContains(searchQuery)
            }
        }
        
        return exercises
    }
    
    func getExercisesByCategory(for muscleGroupId: String) -> [ExerciseCategory: [EnhancedExercise]] {
        let exercises = getEnhancedExercises(for: muscleGroupId)
        return Dictionary(grouping: exercises) { $0.category }
    }
    
    func getExercisesByEquipment(for muscleGroupId: String) -> [ExerciseEquipment: [EnhancedExercise]] {
        let exercises = getEnhancedExercises(for: muscleGroupId)
        return Dictionary(grouping: exercises) { $0.equipment }
    }
}

