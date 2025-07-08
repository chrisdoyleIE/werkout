import Foundation

// MARK: - Core Food Models

struct FoodItem: Identifiable, Codable {
    let id: UUID
    let name: String
    let brand: String?
    let barcode: String?
    let caloriesPer100g: Double
    let proteinPer100g: Double
    let carbsPer100g: Double
    let fatPer100g: Double
    let fiberPer100g: Double?
    let sugarPer100g: Double?
    let sodiumPer100g: Double?
    let isVerified: Bool
    let sourceUrl: String?
    let lastVerifiedAt: Date?
    let createdByUserId: UUID?
    let createdAt: Date
    let updatedAt: Date
    
    // New meal-related properties
    let isUserRecipe: Bool?
    let servingSizeName: String?
    let servingSizeGrams: Double?
    let useCount: Int?
    let lastUsedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case brand
        case barcode
        case caloriesPer100g = "calories_per_100g"
        case proteinPer100g = "protein_per_100g"
        case carbsPer100g = "carbs_per_100g"
        case fatPer100g = "fat_per_100g"
        case fiberPer100g = "fiber_per_100g"
        case sugarPer100g = "sugar_per_100g"
        case sodiumPer100g = "sodium_per_100g"
        case isVerified = "is_verified"
        case sourceUrl = "source_url"
        case lastVerifiedAt = "last_verified_at"
        case createdByUserId = "created_by_user_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case isUserRecipe = "is_user_recipe"
        case servingSizeName = "serving_size_name"
        case servingSizeGrams = "serving_size_grams"
        case useCount = "use_count"
        case lastUsedAt = "last_used_at"
    }
    
    init(
        id: UUID = UUID(),
        name: String,
        brand: String? = nil,
        barcode: String? = nil,
        caloriesPer100g: Double,
        proteinPer100g: Double,
        carbsPer100g: Double,
        fatPer100g: Double,
        fiberPer100g: Double? = nil,
        sugarPer100g: Double? = nil,
        sodiumPer100g: Double? = nil,
        isVerified: Bool = false,
        sourceUrl: String? = nil,
        lastVerifiedAt: Date? = nil,
        createdByUserId: UUID? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isUserRecipe: Bool? = nil,
        servingSizeName: String? = nil,
        servingSizeGrams: Double? = nil,
        useCount: Int? = nil,
        lastUsedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.brand = brand
        self.barcode = barcode
        self.caloriesPer100g = caloriesPer100g
        self.proteinPer100g = proteinPer100g
        self.carbsPer100g = carbsPer100g
        self.fatPer100g = fatPer100g
        self.fiberPer100g = fiberPer100g
        self.sugarPer100g = sugarPer100g
        self.sodiumPer100g = sodiumPer100g
        self.isVerified = isVerified
        self.sourceUrl = sourceUrl
        self.lastVerifiedAt = lastVerifiedAt
        self.createdByUserId = createdByUserId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isUserRecipe = isUserRecipe
        self.servingSizeName = servingSizeName
        self.servingSizeGrams = servingSizeGrams
        self.useCount = useCount
        self.lastUsedAt = lastUsedAt
    }
    
    var displayName: String {
        if let brand = brand, !brand.isEmpty {
            return "\(brand) \(name)"
        }
        return name
    }
    
    func calculateNutrition(for grams: Double) -> NutritionInfo {
        let factor = grams / 100.0
        return NutritionInfo(
            calories: caloriesPer100g * factor,
            protein: proteinPer100g * factor,
            carbs: carbsPer100g * factor,
            fat: fatPer100g * factor,
            fiber: (fiberPer100g ?? 0) * factor,
            sugar: (sugarPer100g ?? 0) * factor,
            sodium: (sodiumPer100g ?? 0) * factor
        )
    }
}

struct FoodEntry: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    let foodItemId: UUID
    let consumedDate: Date
    let mealType: MealType
    let quantityGrams: Double
    let calories: Double
    let proteinG: Double
    let carbsG: Double
    let fatG: Double
    let notes: String?
    let source: FoodEntrySource
    let confidenceScore: Double
    let createdAt: Date
    
    // New meal grouping properties
    let mealGroupId: UUID?
    let mealGroupName: String?
    let isMealTemplate: Bool?
    
    var foodItem: FoodItem?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case foodItemId = "food_item_id"
        case consumedDate = "consumed_date"
        case mealType = "meal_type"
        case quantityGrams = "quantity_grams"
        case calories
        case proteinG = "protein_g"
        case carbsG = "carbs_g"
        case fatG = "fat_g"
        case notes
        case source
        case confidenceScore = "confidence_score"
        case createdAt = "created_at"
        case mealGroupId = "meal_group_id"
        case mealGroupName = "meal_group_name"
        case isMealTemplate = "is_meal_template"
        // foodItem is not encoded/decoded as it's populated separately
    }
    
    init(
        id: UUID = UUID(),
        userId: UUID,
        foodItemId: UUID,
        consumedDate: Date = Date(),
        mealType: MealType,
        quantityGrams: Double,
        calories: Double,
        proteinG: Double,
        carbsG: Double,
        fatG: Double,
        notes: String? = nil,
        source: FoodEntrySource = .manual,
        confidenceScore: Double = 1.0,
        createdAt: Date = Date(),
        mealGroupId: UUID? = nil,
        mealGroupName: String? = nil,
        isMealTemplate: Bool? = nil,
        foodItem: FoodItem? = nil
    ) {
        self.id = id
        self.userId = userId
        self.foodItemId = foodItemId
        self.consumedDate = consumedDate
        self.mealType = mealType
        self.quantityGrams = quantityGrams
        self.calories = calories
        self.proteinG = proteinG
        self.carbsG = carbsG
        self.fatG = fatG
        self.notes = notes
        self.source = source
        self.confidenceScore = confidenceScore
        self.createdAt = createdAt
        self.mealGroupId = mealGroupId
        self.mealGroupName = mealGroupName
        self.isMealTemplate = isMealTemplate
        self.foodItem = foodItem
    }
}

enum FoodEntrySource: String, CaseIterable, Codable {
    case manual = "manual"
    case voice = "voice"
    case camera = "camera"
    case text = "text"
    case claudeSearch = "claude_search"
    case mealTemplate = "meal_template"
    
    var displayName: String {
        switch self {
        case .manual:
            return "Manual Entry"
        case .voice:
            return "Voice Input"
        case .camera:
            return "Camera/Photo"
        case .text:
            return "Text Input"
        case .claudeSearch:
            return "AI Search"
        case .mealTemplate:
            return "Meal Template"
        }
    }
    
    var icon: String {
        switch self {
        case .manual:
            return "hand.tap"
        case .voice:
            return "mic.fill"
        case .camera:
            return "camera.fill"
        case .text:
            return "textformat"
        case .claudeSearch:
            return "wand.and.stars"
        case .mealTemplate:
            return "square.stack.3d.up.fill"
        }
    }
}

// MealType and NutritionInfo are now defined in MealPlanAPIModels.swift

// MARK: - Helper Extensions

extension Array where Element == FoodEntry {
    func totalNutrition() -> NutritionInfo {
        return self.reduce(NutritionInfo.zero) { total, entry in
            let entryNutrition = NutritionInfo(
                calories: entry.calories,
                protein: entry.proteinG,
                carbs: entry.carbsG,
                fat: entry.fatG,
                fiber: 0, // Will be calculated from food item if needed
                sugar: 0,
                sodium: 0
            )
            return total + entryNutrition
        }
    }
    
    func groupedByMealType() -> [MealType: [FoodEntry]] {
        return Dictionary(grouping: self, by: \.mealType)
    }
}

// MARK: - Meal Template Models

struct MealTemplate: Identifiable, Codable {
    let mealGroupId: UUID
    let mealGroupName: String
    let userId: UUID
    let componentCount: Int
    let components: [MealComponent]
    let totalCalories: Double
    let totalProtein: Double
    let totalCarbs: Double
    let totalFat: Double
    let lastUsed: Date
    let useCount: Int
    
    var id: UUID { mealGroupId }
    
    enum CodingKeys: String, CodingKey {
        case mealGroupId = "meal_group_id"
        case mealGroupName = "meal_group_name"
        case userId = "user_id"
        case componentCount = "component_count"
        case components
        case totalCalories = "total_calories"
        case totalProtein = "total_protein"
        case totalCarbs = "total_carbs"
        case totalFat = "total_fat"
        case lastUsed = "last_used"
        case useCount = "use_count"
    }
}

struct MealComponent: Codable {
    let foodItemId: UUID
    let quantityGrams: Double
    let foodName: String
    let brand: String?
    let caloriesPer100g: Double
    let proteinPer100g: Double
    let carbsPer100g: Double
    let fatPer100g: Double
    
    enum CodingKeys: String, CodingKey {
        case foodItemId = "food_item_id"
        case quantityGrams = "quantity_grams"
        case foodName = "food_name"
        case brand
        case caloriesPer100g = "calories_per_100g"
        case proteinPer100g = "protein_per_100g"
        case carbsPer100g = "carbs_per_100g"
        case fatPer100g = "fat_per_100g"
    }
}

// Model for recent foods and meals search results
struct RecentFoodItem: Identifiable {
    let itemType: String // "food" or "meal"
    let itemId: UUID
    let name: String
    let brand: String?
    let lastUsed: Date
    let useCount: Int
    let avgQuantity: Double?
    let caloriesPerServing: Double
    let proteinPerServing: Double
    let isMeal: Bool
    let components: [MealComponent]?
    
    var id: UUID { itemId }
    
    var displayName: String {
        if isMeal {
            return "🍽️ \(name)"
        } else if let brand = brand, !brand.isEmpty {
            return "\(brand) \(name)"
        }
        return name
    }
    
    var subtitle: String {
        if isMeal {
            return "\(components?.count ?? 0) items • \(Int(caloriesPerServing)) cal"
        } else {
            let quantity = avgQuantity ?? 100
            return "\(Int(quantity))g • \(Int(caloriesPerServing)) cal"
        }
    }
}

extension FoodItem {
    static let sampleFoods: [FoodItem] = [
        FoodItem(
            name: "Banana",
            caloriesPer100g: 89,
            proteinPer100g: 1.1,
            carbsPer100g: 22.8,
            fatPer100g: 0.3,
            fiberPer100g: 2.6,
            sugarPer100g: 12.2,
            sodiumPer100g: 1,
            isVerified: true
        ),
        FoodItem(
            name: "Chicken Breast",
            caloriesPer100g: 165,
            proteinPer100g: 31.0,
            carbsPer100g: 0.0,
            fatPer100g: 3.6,
            isVerified: true
        ),
        FoodItem(
            name: "Oatmeal",
            caloriesPer100g: 389,
            proteinPer100g: 16.9,
            carbsPer100g: 66.3,
            fatPer100g: 6.9,
            fiberPer100g: 10.6,
            isVerified: true
        )
    ]
}