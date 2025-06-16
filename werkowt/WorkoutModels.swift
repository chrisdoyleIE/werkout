import Foundation

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

struct BodyWeightEntry: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let weightKg: Double
    let recordedAt: Date
    let notes: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case weightKg = "weight_kg"
        case recordedAt = "recorded_at"
        case notes
    }
    
    init(id: UUID = UUID(), userId: UUID, weightKg: Double, recordedAt: Date = Date(), notes: String? = nil) {
        self.id = id
        self.userId = userId
        self.weightKg = weightKg
        self.recordedAt = recordedAt
        self.notes = notes
    }
}