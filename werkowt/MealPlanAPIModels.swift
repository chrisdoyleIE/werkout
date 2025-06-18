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
    let categorizedShoppingList: [String: [String]]?
    let mealPrepInstructions: [String]?
    let totalNutrition: NutritionSummary?
}

struct DailyMeal: Codable {
    let day: Int
    let date: String
    let meals: [Meal]
    let dailyNutrition: NutritionSummary?
}

struct Meal: Codable, Identifiable {
    var id: String { name + type.rawValue }
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

// MARK: - Meal Planning Configuration Types
enum DietType: String, CaseIterable {
    case omnivore = "Omnivore"
    case vegetarian = "Vegetarian"
    case vegan = "Vegan"
    case keto = "Keto"
    case mediterranean = "Mediterranean"
    case paleo = "Paleo"
}

enum BudgetLevel: String, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
}

enum ShopType: String, CaseIterable {
    case cornerStore = "Corner Store"
    case supermarket = "Supermarket"
}

enum SkillLevel: String, CaseIterable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
}

enum PrepTime: String, CaseIterable {
    case quick = "5 min"
    case short = "15 min"
    case medium = "30 min"
    case long = "45+ min"
    
    var minutes: Int {
        switch self {
        case .quick: return 5
        case .short: return 15
        case .medium: return 30
        case .long: return 45
        }
    }
}

enum CookingFrequency: String, CaseIterable {
    case daily = "Daily"
    case everyOtherDay = "Every Other Day"
    case twicePerWeek = "Twice Per Week"
    case oncePerWeek = "Once Per Week"
    
    var description: String {
        switch self {
        case .daily: return "I prefer to cook every day"
        case .everyOtherDay: return "I like to cook every other day"
        case .twicePerWeek: return "I prefer to cook twice per week"
        case .oncePerWeek: return "I only want to cook once per week"
        }
    }
    
    var batchCookingNeeded: Bool {
        switch self {
        case .daily: return false
        case .everyOtherDay: return true
        case .twicePerWeek: return true
        case .oncePerWeek: return true
        }
    }
}

struct MealPlanningConfiguration {
    let selectedMealTypes: Set<MealType>
    let householdSize: Int
    let maxPrepTime: PrepTime
    let cookingFrequency: CookingFrequency
    let dietType: DietType
    let skillLevel: SkillLevel
    let budgetLevel: BudgetLevel
    let shopType: ShopType
    let selectedAllergens: Set<String>
    let additionalNotes: String
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