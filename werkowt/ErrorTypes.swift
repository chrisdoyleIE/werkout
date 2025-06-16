import Foundation

// MARK: - Error Types
enum WorkoutError: Error, LocalizedError {
    case notAuthenticated
    case noExercisesSelected
    case sessionCreationFailed
    case sessionNotFound
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User not authenticated"
        case .noExercisesSelected:
            return "Please select at least one exercise"
        case .sessionCreationFailed:
            return "Failed to create workout session"
        case .sessionNotFound:
            return "Workout session not found"
        case .invalidData:
            return "Invalid workout data"
        }
    }
}

enum ExerciseDataError: Error, LocalizedError {
    case fileNotFound
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "Exercise data file not found"
        case .decodingError:
            return "Failed to decode exercise data"
        }
    }
}