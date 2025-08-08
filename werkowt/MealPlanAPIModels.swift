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
    let shoppingList: [ShoppingListItemDetail]?
    let categorizedShoppingList: [String: [String]]? // Legacy support
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
    let sodium: Double?
    
    init(calories: Double, protein: Double, carbs: Double, fat: Double, fiber: Double? = nil, sugar: Double? = nil, sodium: Double? = nil) {
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.fiber = fiber
        self.sugar = sugar
        self.sodium = sodium
    }
    
    static let zero = NutritionInfo(
        calories: 0,
        protein: 0,
        carbs: 0,
        fat: 0,
        fiber: 0,
        sugar: 0,
        sodium: 0
    )
    
    static func + (lhs: NutritionInfo, rhs: NutritionInfo) -> NutritionInfo {
        return NutritionInfo(
            calories: lhs.calories + rhs.calories,
            protein: lhs.protein + rhs.protein,
            carbs: lhs.carbs + rhs.carbs,
            fat: lhs.fat + rhs.fat,
            fiber: (lhs.fiber ?? 0) + (rhs.fiber ?? 0),
            sugar: (lhs.sugar ?? 0) + (rhs.sugar ?? 0),
            sodium: (lhs.sodium ?? 0) + (rhs.sodium ?? 0)
        )
    }
}

// MARK: - Enhanced Nutrition Label Models

struct RawNutritionData: Codable {
    let nutrition: NutritionInfo        // Always per 100g/100ml
    let originalUnit: String           // "100g", "100ml", "per packet", etc.
    let originalServingSize: Double?   // If label shows specific serving (e.g., 30g per serving)
    let suggestedServingSize: String?  // Claude's suggested serving size name (e.g., "handful")
    let suggestedServingGrams: Double? // Claude's suggested serving size in grams
    let confidence: Double             // AI confidence in extraction
    let source: String                 // "Nutrition label from photo"
    
    init(nutrition: NutritionInfo, originalUnit: String = "100g", originalServingSize: Double? = nil, suggestedServingSize: String? = nil, suggestedServingGrams: Double? = nil, confidence: Double = 0.9, source: String = "Nutrition label from photo") {
        self.nutrition = nutrition
        self.originalUnit = originalUnit
        self.originalServingSize = originalServingSize
        self.suggestedServingSize = suggestedServingSize
        self.suggestedServingGrams = suggestedServingGrams
        self.confidence = confidence
        self.source = source
    }
}

struct NutritionDisplayData: Codable {
    let rawNutrition: RawNutritionData      // Original label data (per 100g)
    let servingNutrition: NutritionInfo     // Calculated for selected serving
    let servingSize: ServingSize            // Selected serving size
    
    init(rawNutrition: RawNutritionData, servingSize: ServingSize) {
        self.rawNutrition = rawNutrition
        self.servingSize = servingSize
        
        // Calculate serving nutrition from raw per-100g data
        let servingFactor = servingSize.gramsEquivalent / 100.0
        self.servingNutrition = NutritionInfo(
            calories: rawNutrition.nutrition.calories * servingFactor,
            protein: rawNutrition.nutrition.protein * servingFactor,
            carbs: rawNutrition.nutrition.carbs * servingFactor,
            fat: rawNutrition.nutrition.fat * servingFactor,
            fiber: (rawNutrition.nutrition.fiber ?? 0) * servingFactor,
            sugar: (rawNutrition.nutrition.sugar ?? 0) * servingFactor,
            sodium: (rawNutrition.nutrition.sodium ?? 0) * servingFactor
        )
    }
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
        case .dinner: return "sunset.fill"
        case .snack: return "star.fill"
        }
    }
}

// MARK: - Shopping Category Types
enum ShoppingCategory: String, Codable, CaseIterable {
    case dairy = "Dairy"
    case meatAndFish = "Meat & Fish"
    case fruitAndVeg = "Fruit & Veg"
    case storeCupboard = "Store Cupboard"
    case frozen = "Frozen"
    case breadsAndGrains = "Breads & Grains"
    case other = "Other"
    
    var displayName: String {
        return self.rawValue
    }
    
    var icon: String {
        switch self {
        case .dairy: return "drop.fill"
        case .meatAndFish: return "fish.fill"
        case .fruitAndVeg: return "leaf.fill"
        case .storeCupboard: return "archivebox.fill"
        case .frozen: return "snowflake"
        case .breadsAndGrains: return "takeoutbag.and.cup.and.straw.fill"
        case .other: return "bag.fill"
        }
    }
}

struct ShoppingListItemDetail: Codable {
    let name: String
    let amount: String
    let category: ShoppingCategory
    
    init(name: String, amount: String, category: ShoppingCategory) {
        self.name = name
        self.amount = amount
        self.category = category
    }
    
    // Fallback initializer for legacy string-only items
    init(name: String, category: ShoppingCategory? = nil) {
        self.name = name
        self.amount = ""
        self.category = category ?? .other
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