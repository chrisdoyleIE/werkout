import Foundation

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