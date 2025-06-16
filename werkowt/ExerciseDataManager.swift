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
        
        guard let url = Bundle.main.url(forResource: "exercises", withExtension: "json") else {
            error = ExerciseDataError.fileNotFound
            isLoading = false
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let exerciseData = try JSONDecoder().decode(ExerciseData.self, from: data)
            self.muscleGroups = exerciseData.muscleGroups
        } catch {
            self.error = error
        }
        
        isLoading = false
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
}

