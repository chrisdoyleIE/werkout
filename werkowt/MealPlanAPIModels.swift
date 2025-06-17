import Foundation

// MARK: - Claude API Response Models
struct ClaudeAPIResponse: Codable {
    let content: [ClaudeContent]
}

struct ClaudeContent: Codable {
    let type: String
    let text: String
}

// MARK: - Meal Plan Response Models
struct GeneratedMealPlan: Codable {
    let title: String
    let description: String
    let totalDays: Int
    let dailyMeals: [DailyMeal]
    let shoppingList: [String]?
    let totalNutrition: NutritionSummary?
}

struct DailyMeal: Codable {
    let day: Int
    let date: String
    let meals: [Meal]
    let dailyNutrition: NutritionSummary?
}

struct Meal: Codable {
    let type: MealType
    let name: String
    let description: String
    let ingredients: [String]
    let instructions: [String]
    let prepTime: Int? // minutes
    let nutrition: NutritionInfo?
}

struct NutritionInfo: Codable {
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let fiber: Double?
    let sugar: Double?
}

struct NutritionSummary: Codable {
    let totalCalories: Double
    let totalProtein: Double
    let totalCarbs: Double
    let totalFat: Double
}

enum MealType: String, Codable, CaseIterable {
    case breakfast = "breakfast"
    case lunch = "lunch"
    case dinner = "dinner"
    case snack = "snack"
    
    var displayName: String {
        switch self {
        case .breakfast: return "Breakfast"
        case .lunch: return "Lunch"
        case .dinner: return "Dinner"
        case .snack: return "Snack"
        }
    }
    
    var icon: String {
        switch self {
        case .breakfast: return "sunrise.fill"
        case .lunch: return "sun.max.fill"
        case .dinner: return "moon.fill"
        case .snack: return "leaf.fill"
        }
    }
}

// MARK: - Error Types
enum ClaudeAPIError: Error, LocalizedError {
    case invalidURL
    case noAPIKey
    case invalidResponse
    case jsonParsingError
    case networkError(Error)
    case invalidMealPlanFormat
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .noAPIKey:
            return "No API key configured"
        case .invalidResponse:
            return "Invalid response from Claude API"
        case .jsonParsingError:
            return "Failed to parse meal plan data"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidMealPlanFormat:
            return "Claude returned an invalid meal plan format"
        }
    }
}