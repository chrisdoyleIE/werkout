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
enum ExerciseType: String, Codable, CaseIterable {
    case weight = "weight"        // Exercises with weight + reps (bench press, squats)
    case bodyweight = "bodyweight" // Exercises with just reps (push-ups, pull-ups)
    case timed = "timed"          // Exercises with duration (planks, wall sits)
}

struct Exercise: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let instructions: String
    let type: ExerciseType
    
    // For backwards compatibility with existing JSON
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        instructions = try container.decode(String.self, forKey: .instructions)
        
        // Default to weight if type not specified
        type = try container.decodeIfPresent(ExerciseType.self, forKey: .type) ?? .weight
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, name, instructions, type
    }
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
    let reps: Int?              // Optional for timed exercises
    let weightKg: Double?       // Optional for bodyweight/timed exercises  
    let durationSeconds: Int?   // For timed exercises
    let restSeconds: Int?
    let completedAt: Date
    
    init(id: UUID, workoutSessionId: UUID, exerciseId: String, setNumber: Int, 
         reps: Int?, weightKg: Double?, durationSeconds: Int?, restSeconds: Int?, completedAt: Date) {
        self.id = id
        self.workoutSessionId = workoutSessionId
        self.exerciseId = exerciseId
        self.setNumber = setNumber
        self.reps = reps
        self.weightKg = weightKg
        self.durationSeconds = durationSeconds
        self.restSeconds = restSeconds
        self.completedAt = completedAt
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case workoutSessionId = "workout_session_id"
        case exerciseId = "exercise_id"
        case setNumber = "set_number"
        case reps
        case weightKg = "weight_kg"
        case durationSeconds = "duration_seconds"
        case restSeconds = "rest_seconds"
        case completedAt = "completed_at"
    }
    
    // Convenience initializers for different exercise types
    static func weightSet(id: UUID = UUID(), workoutSessionId: UUID, exerciseId: String, 
                         setNumber: Int, reps: Int, weightKg: Double) -> WorkoutSet {
        WorkoutSet(id: id, workoutSessionId: workoutSessionId, exerciseId: exerciseId,
                  setNumber: setNumber, reps: reps, weightKg: weightKg, 
                  durationSeconds: nil, restSeconds: nil, completedAt: Date())
    }
    
    static func bodyweightSet(id: UUID = UUID(), workoutSessionId: UUID, exerciseId: String,
                             setNumber: Int, reps: Int) -> WorkoutSet {
        WorkoutSet(id: id, workoutSessionId: workoutSessionId, exerciseId: exerciseId,
                  setNumber: setNumber, reps: reps, weightKg: nil,
                  durationSeconds: nil, restSeconds: nil, completedAt: Date())
    }
    
    static func timedSet(id: UUID = UUID(), workoutSessionId: UUID, exerciseId: String,
                        setNumber: Int, durationSeconds: Int) -> WorkoutSet {
        WorkoutSet(id: id, workoutSessionId: workoutSessionId, exerciseId: exerciseId,
                  setNumber: setNumber, reps: nil, weightKg: nil,
                  durationSeconds: durationSeconds, restSeconds: nil, completedAt: Date())
    }
}

struct PersonalRecord: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let exerciseId: String
    let maxWeightKg: Double
    let reps: Int
    let achievedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case exerciseId = "exercise_id"
        case maxWeightKg = "max_weight_kg"
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
    
    func addSet(exerciseId: String, reps: Int, weight: Double) {
        guard let sessionId = session?.id else { return }
        
        let setNumber = (exercises.first { $0.exercise.id == exerciseId }?.sets.count ?? 0) + 1
        
        let newSet = WorkoutSet.weightSet(
            workoutSessionId: sessionId,
            exerciseId: exerciseId,
            setNumber: setNumber,
            reps: reps,
            weightKg: weight
        )
        
        addSetToExercise(newSet)
    }
    
    func addBodyweightSet(exerciseId: String, reps: Int) {
        guard let sessionId = session?.id else { return }
        
        let setNumber = (exercises.first { $0.exercise.id == exerciseId }?.sets.count ?? 0) + 1
        
        let newSet = WorkoutSet.bodyweightSet(
            workoutSessionId: sessionId,
            exerciseId: exerciseId,
            setNumber: setNumber,
            reps: reps
        )
        
        addSetToExercise(newSet)
    }
    
    func addTimedSet(exerciseId: String, durationSeconds: Int) {
        guard let sessionId = session?.id else { return }
        
        let setNumber = (exercises.first { $0.exercise.id == exerciseId }?.sets.count ?? 0) + 1
        
        let newSet = WorkoutSet.timedSet(
            workoutSessionId: sessionId,
            exerciseId: exerciseId,
            setNumber: setNumber,
            durationSeconds: durationSeconds
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
                print("Failed to delete set from Supabase: \(error)")
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
                print("Failed to save set to Supabase: \(error)")
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
                print("Failed to finish workout session: \(error)")
            }
        }
        
        self.session = nil
        self.exercises = []
        self.isActive = false
        self.startTime = nil
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
        
        timer = Timer(timeInterval: 1.0, repeats: true) { _ in
            DispatchQueue.main.async {
                if self.timeRemaining > 0 {
                    self.timeRemaining -= 1
                } else {
                    self.stop()
                }
            }
        }
        
        RunLoop.main.add(timer!, forMode: .common)
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
        
        timer = Timer(timeInterval: 1.0, repeats: true) { _ in
            DispatchQueue.main.async {
                if self.timeRemaining > 0 {
                    self.timeRemaining -= 1
                } else {
                    self.stop()
                }
            }
        }
        
        RunLoop.main.add(timer!, forMode: .common)
    }
    
    var formattedTime: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Exercise Timer
class ExerciseTimer: ObservableObject {
    @Published var timeRemaining: Int = 0
    @Published var isRunning: Bool = false
    
    private var timer: Timer?
    private(set) var totalDuration: Int = 0
    
    func start(duration: Int) {
        stop()
        
        totalDuration = duration
        timeRemaining = duration
        isRunning = true
        
        timer = Timer(timeInterval: 1.0, repeats: true) { _ in
            DispatchQueue.main.async {
                if self.timeRemaining > 0 {
                    self.timeRemaining -= 1
                } else {
                    self.stop()
                }
            }
        }
        
        RunLoop.main.add(timer!, forMode: .common)
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        timeRemaining = 0
        totalDuration = 0
    }
    
    func pause() {
        timer?.invalidate()
        timer = nil
        isRunning = false
    }
    
    func resume() {
        guard timeRemaining > 0 else { return }
        
        isRunning = true
        
        timer = Timer(timeInterval: 1.0, repeats: true) { _ in
            DispatchQueue.main.async {
                if self.timeRemaining > 0 {
                    self.timeRemaining -= 1
                } else {
                    self.stop()
                }
            }
        }
        
        RunLoop.main.add(timer!, forMode: .common)
    }
    
    var formattedTime: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}