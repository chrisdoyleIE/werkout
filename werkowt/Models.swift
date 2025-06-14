import Foundation

// MARK: - Error Types
enum WorkoutError: Error, LocalizedError {
    case notAuthenticated
    case noExercisesSelected
    case sessionCreationFailed
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Please log in to create workouts"
        case .noExercisesSelected:
            return "Please select at least one exercise"
        case .sessionCreationFailed:
            return "Failed to create workout session"
        }
    }
}

// MARK: - Exercise Data Models
struct Exercise: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let instructions: String
}

struct MuscleGroup: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let emoji: String
    let exercises: [Exercise]
}

struct ExerciseData: Codable {
    let muscleGroups: [MuscleGroup]
}

// MARK: - Workout Data Models
struct WorkoutSession: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let name: String
    let startedAt: Date
    let endedAt: Date?
    let durationMinutes: Int?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, name
        case userId = "user_id"
        case startedAt = "started_at"
        case endedAt = "ended_at"
        case durationMinutes = "duration_minutes"
        case createdAt = "created_at"
    }
}

struct WorkoutSet: Codable, Identifiable {
    let id: UUID
    let workoutSessionId: UUID
    let exerciseId: String
    let setNumber: Int
    let reps: Int
    let weightLbs: Double
    let restSeconds: Int?
    let completedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case workoutSessionId = "workout_session_id"
        case exerciseId = "exercise_id"
        case setNumber = "set_number"
        case reps
        case weightLbs = "weight_lbs"
        case restSeconds = "rest_seconds"
        case completedAt = "completed_at"
    }
}

struct PersonalRecord: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let exerciseId: String
    let maxWeightLbs: Double
    let reps: Int
    let achievedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case exerciseId = "exercise_id"
        case maxWeightLbs = "max_weight_lbs"
        case reps
        case achievedAt = "achieved_at"
    }
}

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
        return sets.map { "\(Int($0.weightLbs))×\($0.reps)" }.joined(separator: ", ")
    }
}

// MARK: - Active Workout State
class ActiveWorkout: ObservableObject {
    @Published var session: WorkoutSession?
    @Published var exercises: [ExerciseWithSets] = []
    @Published var currentExerciseIndex: Int = 0
    @Published var isActive: Bool = false
    @Published var startTime: Date?
    @Published var restTimer: RestTimer = RestTimer()
    
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
    
    func addSet(exerciseId: String, reps: Int, weight: Double) {
        guard let sessionId = session?.id else { return }
        
        let setNumber = (exercises.first { $0.exercise.id == exerciseId }?.sets.count ?? 0) + 1
        
        let newSet = WorkoutSet(
            id: UUID(),
            workoutSessionId: sessionId,
            exerciseId: exerciseId,
            setNumber: setNumber,
            reps: reps,
            weightLbs: weight,
            restSeconds: nil,
            completedAt: Date()
        )
        
        // Update UI immediately
        if let index = exercises.firstIndex(where: { $0.exercise.id == exerciseId }) {
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
            } catch {
                print("Failed to save set to Supabase: \(error)")
                // TODO: Add to pending sync queue
            }
        }
        
        restTimer.start(duration: 120) // 2 minute default rest
    }
    
    func finishWorkout() {
        guard var session = self.session else { return }
        
        let endTime = Date()
        let duration = Int(endTime.timeIntervalSince(startTime ?? endTime) / 60)
        
        // Update session with end time and duration
        // This would typically save to Supabase here
        
        self.session = nil
        self.exercises = []
        self.isActive = false
        self.startTime = nil
        self.restTimer.stop()
    }
}

// MARK: - Rest Timer
class RestTimer: ObservableObject {
    @Published var timeRemaining: Int = 0
    @Published var isRunning: Bool = false
    
    private var timer: Timer?
    
    func start(duration: Int) {
        stop()
        timeRemaining = duration
        isRunning = true
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if self.timeRemaining > 0 {
                self.timeRemaining -= 1
            } else {
                self.stop()
            }
        }
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        timeRemaining = 0
    }
    
    func pause() {
        timer?.invalidate()
        timer = nil
        isRunning = false
    }
    
    func resume() {
        guard timeRemaining > 0 else { return }
        isRunning = true
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if self.timeRemaining > 0 {
                self.timeRemaining -= 1
            } else {
                self.stop()
            }
        }
    }
    
    var formattedTime: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}