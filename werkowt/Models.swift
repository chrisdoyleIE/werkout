import Foundation
import os

// MARK: - UI Models
struct ExerciseWithSets {
    let exercise: Exercise
    let sets: [WorkoutSet]
    let isCompleted: Bool
    
    var latestSet: WorkoutSet? {
        sets.max(by: { $0.setNumber < $1.setNumber })
    }
}

struct PreviousSessionData {
    let exerciseId: String
    let sets: [WorkoutSet]
    let sessionDate: Date
    
    var formattedSets: String {
        return sets.map { set in
            if let weight = set.weightKg, let reps = set.reps {
                return "\(String(format: "%.1f", weight))kg×\(reps)"
            } else if let reps = set.reps {
                return "\(reps) reps"
            } else if let duration = set.durationSeconds {
                let minutes = duration / 60
                let seconds = duration % 60
                return minutes > 0 ? "\(minutes)m \(seconds)s" : "\(seconds)s"
            } else {
                return "Unknown"
            }
        }.joined(separator: ", ")
    }
}

// MARK: - Active Workout State
class ActiveWorkout: ObservableObject {
    @Published var session: WorkoutSession?
    @Published var exercises: [ExerciseWithSets] = []
    @Published var currentExerciseIndex: Int = 0
    @Published var isActive: Bool = false
    @Published var startTime: Date?
    
    var currentExercise: ExerciseWithSets? {
        guard currentExerciseIndex < exercises.count else { return nil }
        return exercises[currentExerciseIndex]
    }
    
    func startWorkout(name: String, exercises: [Exercise]) async throws {
        guard let userId = await AuthManager.shared.userId else {
            throw WorkoutError.notAuthenticated
        }
        
        guard !exercises.isEmpty else {
            throw WorkoutError.noExercisesSelected
        }
        
        do {
            let session = try await WorkoutDataManager.shared.createWorkoutSession(name: name)
            
            await MainActor.run {
                self.session = session
                self.exercises = exercises.map { ExerciseWithSets(exercise: $0, sets: [], isCompleted: false) }
                self.currentExerciseIndex = 0
                self.startTime = Date()
                self.isActive = true
            }
            
        } catch {
            await MainActor.run {
                self.session = WorkoutSession(
                    id: UUID(),
                    userId: userId,
                    name: name,
                    startedAt: Date(),
                    endedAt: nil,
                    durationMinutes: nil,
                    createdAt: Date()
                )
                
                self.exercises = exercises.map { ExerciseWithSets(exercise: $0, sets: [], isCompleted: false) }
                self.currentExerciseIndex = 0
                self.startTime = Date()
                self.isActive = true
            }
        }
    }
    
    func addSet(exerciseId: String, reps: Int, weight: Double, wentToFailure: Bool = false) {
        guard let sessionId = session?.id else { return }
        
        let setNumber = (exercises.first { $0.exercise.id == exerciseId }?.sets.count ?? 0) + 1
        
        let newSet = WorkoutSet.weightSet(
            workoutSessionId: sessionId,
            exerciseId: exerciseId,
            setNumber: setNumber,
            reps: reps,
            weightKg: weight,
            wentToFailure: wentToFailure
        )
        
        addSetToExercise(newSet)
    }
    
    func addBodyweightSet(exerciseId: String, reps: Int, wentToFailure: Bool = false) {
        guard let sessionId = session?.id else { return }
        
        let setNumber = (exercises.first { $0.exercise.id == exerciseId }?.sets.count ?? 0) + 1
        
        let newSet = WorkoutSet.bodyweightSet(
            workoutSessionId: sessionId,
            exerciseId: exerciseId,
            setNumber: setNumber,
            reps: reps,
            wentToFailure: wentToFailure
        )
        
        addSetToExercise(newSet)
    }
    
    func addTimedSet(exerciseId: String, durationSeconds: Int, wentToFailure: Bool = false) {
        guard let sessionId = session?.id else { return }
        
        let setNumber = (exercises.first { $0.exercise.id == exerciseId }?.sets.count ?? 0) + 1
        
        let newSet = WorkoutSet.timedSet(
            workoutSessionId: sessionId,
            exerciseId: exerciseId,
            setNumber: setNumber,
            durationSeconds: durationSeconds,
            wentToFailure: wentToFailure
        )
        
        addSetToExercise(newSet)
    }
    
    func deleteSet(_ setToDelete: WorkoutSet) {
        // Find the exercise and remove the set
        if let exerciseIndex = exercises.firstIndex(where: { $0.exercise.id == setToDelete.exerciseId }) {
            let updatedSets = exercises[exerciseIndex].sets.filter { $0.id != setToDelete.id }
            
            // Renumber the remaining sets
            let renumberedSets = updatedSets.enumerated().map { index, set in
                WorkoutSet(
                    id: set.id,
                    workoutSessionId: set.workoutSessionId,
                    exerciseId: set.exerciseId,
                    setNumber: index + 1, // Renumber starting from 1
                    reps: set.reps,
                    weightKg: set.weightKg,
                    durationSeconds: set.durationSeconds,
                    restSeconds: set.restSeconds,
                    completedAt: set.completedAt
                )
            }
            
            exercises[exerciseIndex] = ExerciseWithSets(
                exercise: exercises[exerciseIndex].exercise,
                sets: renumberedSets,
                isCompleted: exercises[exerciseIndex].isCompleted
            )
        }
        
        // Delete from Supabase in background
        Task {
            do {
                try await WorkoutDataManager.shared.deleteSet(setToDelete)
            } catch {
                Logger.error("Failed to delete set from Supabase: \(error)", category: Logger.workout)
                // TODO: Add to pending sync queue for retry
            }
        }
    }
    
    private func addSetToExercise(_ newSet: WorkoutSet) {
        // Update UI immediately
        if let index = exercises.firstIndex(where: { $0.exercise.id == newSet.exerciseId }) {
            exercises[index] = ExerciseWithSets(
                exercise: exercises[index].exercise,
                sets: exercises[index].sets + [newSet],
                isCompleted: exercises[index].isCompleted
            )
        }
        
        // Save to Supabase in background
        Task {
            do {
                try await WorkoutDataManager.shared.addSet(newSet)
                // Check and update personal records for weight-based exercises
                if newSet.weightKg != nil {
                    try await WorkoutDataManager.shared.checkAndUpdatePersonalRecord(for: newSet)
                }
            } catch {
                Logger.error("Failed to save set to Supabase: \(error)", category: Logger.workout)
                // TODO: Add to pending sync queue
            }
        }
    }
    
    func finishWorkout() {
        guard let session = self.session else { return }
        
        let endTime = Date()
        let duration = Int(endTime.timeIntervalSince(startTime ?? endTime) / 60)
        
        // Update session with end time and duration in Supabase
        Task {
            do {
                try await WorkoutDataManager.shared.finishWorkoutSession(session)
            } catch {
                Logger.error("Failed to finish workout session: \(error)", category: Logger.workout)
            }
        }
        
        self.session = nil
        self.exercises = []
        self.isActive = false
        self.startTime = nil
    }
}

