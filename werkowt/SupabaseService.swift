import Foundation
import Supabase

// MARK: - Supabase Database Models

struct DBMacroGoals: Codable {
    let id: UUID?
    let userId: UUID
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let createdAt: Date?
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case calories, protein, carbs, fat
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    func toMacroGoals() -> MacroGoals {
        return MacroGoals(calories: calories, protein: protein, carbs: carbs, fat: fat)
    }
}

struct DBMealPlan: Codable {
    let id: UUID?
    let userId: UUID
    let title: String
    let description: String?
    let startDate: Date
    let numberOfDays: Int
    let mealPlanText: String
    let isAIGenerated: Bool
    let generatedContent: Data? // JSON data
    let createdAt: Date?
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title, description
        case startDate = "start_date"
        case numberOfDays = "number_of_days"
        case mealPlanText = "meal_plan_text"
        case isAIGenerated = "is_ai_generated"
        case generatedContent = "generated_content"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    func toMealPlan() -> MealPlan? {
        guard let id = id else { return nil }
        
        var generatedMealPlan: GeneratedMealPlan?
        if let contentData = generatedContent {
            generatedMealPlan = try? JSONDecoder().decode(GeneratedMealPlan.self, from: contentData)
        }
        
        return MealPlan(
            id: id,
            startDate: startDate,
            numberOfDays: numberOfDays,
            mealPlanText: mealPlanText,
            createdAt: createdAt ?? Date(),
            isAIGenerated: isAIGenerated,
            generatedMealPlan: generatedMealPlan
        )
    }
}

struct DBShoppingList: Codable {
    let id: UUID?
    let userId: UUID
    let mealPlanId: UUID
    let mealPlanTitle: String
    let createdAt: Date?
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case mealPlanId = "meal_plan_id"
        case mealPlanTitle = "meal_plan_title"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct DBShoppingListItem: Codable {
    let id: UUID?
    let shoppingListId: UUID
    let name: String
    let amount: String
    let category: String
    let isCompleted: Bool
    let createdAt: Date?
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case shoppingListId = "shopping_list_id"
        case name, amount, category
        case isCompleted = "is_completed"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    func toShoppingListItem(mealPlanId: UUID) -> ShoppingListItem {
        let shoppingCategory = ShoppingCategory(rawValue: category) ?? .other
        var item = ShoppingListItem(name: name, amount: amount, category: shoppingCategory, mealPlanId: mealPlanId)
        item.isCompleted = isCompleted
        return item
    }
}

struct DBFoodItem: Codable {
    let id: UUID?
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
    let createdAt: Date?
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name, brand, barcode
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
    }
    
    init(from foodItem: FoodItem) {
        self.id = foodItem.id
        self.name = foodItem.name
        self.brand = foodItem.brand
        self.barcode = foodItem.barcode
        self.caloriesPer100g = foodItem.caloriesPer100g
        self.proteinPer100g = foodItem.proteinPer100g
        self.carbsPer100g = foodItem.carbsPer100g
        self.fatPer100g = foodItem.fatPer100g
        self.fiberPer100g = foodItem.fiberPer100g
        self.sugarPer100g = foodItem.sugarPer100g
        self.sodiumPer100g = foodItem.sodiumPer100g
        self.isVerified = foodItem.isVerified
        self.sourceUrl = foodItem.sourceUrl
        self.lastVerifiedAt = foodItem.lastVerifiedAt
        self.createdByUserId = foodItem.createdByUserId
        self.createdAt = foodItem.createdAt
        self.updatedAt = foodItem.updatedAt
    }
    
    func toFoodItem() -> FoodItem {
        return FoodItem(
            id: id ?? UUID(),
            name: name,
            brand: brand,
            barcode: barcode,
            caloriesPer100g: caloriesPer100g,
            proteinPer100g: proteinPer100g,
            carbsPer100g: carbsPer100g,
            fatPer100g: fatPer100g,
            fiberPer100g: fiberPer100g,
            sugarPer100g: sugarPer100g,
            sodiumPer100g: sodiumPer100g,
            isVerified: isVerified,
            sourceUrl: sourceUrl,
            lastVerifiedAt: lastVerifiedAt,
            createdByUserId: createdByUserId,
            createdAt: createdAt ?? Date(),
            updatedAt: updatedAt ?? Date()
        )
    }
}

struct DBFoodEntry: Codable {
    let id: UUID?
    let userId: UUID
    let foodItemId: UUID
    let consumedDate: Date
    let mealType: String
    let quantityGrams: Double
    let calories: Double
    let proteinG: Double
    let carbsG: Double
    let fatG: Double
    let notes: String?
    let source: String
    let confidenceScore: Double
    let createdAt: Date?
    
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
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decodeIfPresent(UUID.self, forKey: .id)
        userId = try container.decode(UUID.self, forKey: .userId)
        foodItemId = try container.decode(UUID.self, forKey: .foodItemId)
        mealType = try container.decode(String.self, forKey: .mealType)
        quantityGrams = try container.decode(Double.self, forKey: .quantityGrams)
        calories = try container.decode(Double.self, forKey: .calories)
        proteinG = try container.decode(Double.self, forKey: .proteinG)
        carbsG = try container.decode(Double.self, forKey: .carbsG)
        fatG = try container.decode(Double.self, forKey: .fatG)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        source = try container.decode(String.self, forKey: .source)
        confidenceScore = try container.decode(Double.self, forKey: .confidenceScore)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        
        // Special handling for consumed_date which may come as "yyyy-MM-dd"
        if let dateString = try? container.decode(String.self, forKey: .consumedDate) {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            formatter.timeZone = TimeZone(identifier: "UTC")
            
            if let date = formatter.date(from: dateString) {
                self.consumedDate = date
            } else {
                // Try ISO8601 format
                let isoFormatter = ISO8601DateFormatter()
                isoFormatter.formatOptions = [.withInternetDateTime]
                if let date = isoFormatter.date(from: dateString) {
                    self.consumedDate = date
                } else {
                    throw DecodingError.dataCorruptedError(forKey: .consumedDate, in: container, debugDescription: "Unable to decode consumed_date: \(dateString)")
                }
            }
        } else {
            // Try to decode as Date directly
            self.consumedDate = try container.decode(Date.self, forKey: .consumedDate)
        }
    }
    
    init(from foodEntry: FoodEntry) {
        self.id = foodEntry.id
        self.userId = foodEntry.userId
        self.foodItemId = foodEntry.foodItemId
        self.consumedDate = foodEntry.consumedDate
        self.mealType = foodEntry.mealType.rawValue
        self.quantityGrams = foodEntry.quantityGrams
        self.calories = foodEntry.calories
        self.proteinG = foodEntry.proteinG
        self.carbsG = foodEntry.carbsG
        self.fatG = foodEntry.fatG
        self.notes = foodEntry.notes
        self.source = foodEntry.source.rawValue
        self.confidenceScore = foodEntry.confidenceScore
        self.createdAt = foodEntry.createdAt
    }
    
    init(
        id: UUID?,
        userId: UUID,
        foodItemId: UUID,
        consumedDate: Date,
        mealType: String,
        quantityGrams: Double,
        calories: Double,
        proteinG: Double,
        carbsG: Double,
        fatG: Double,
        notes: String?,
        source: String,
        confidenceScore: Double,
        createdAt: Date?
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
    }
    
    func toFoodEntry() -> FoodEntry {
        return FoodEntry(
            id: id ?? UUID(),
            userId: userId,
            foodItemId: foodItemId,
            consumedDate: consumedDate,
            mealType: MealType(rawValue: mealType) ?? .snack,
            quantityGrams: quantityGrams,
            calories: calories,
            proteinG: proteinG,
            carbsG: carbsG,
            fatG: fatG,
            notes: notes,
            source: FoodEntrySource(rawValue: source) ?? .manual,
            confidenceScore: confidenceScore,
            createdAt: createdAt ?? Date()
        )
    }
}

// MARK: - Service Error Types

enum SupabaseServiceError: Error, LocalizedError {
    case notAuthenticated
    case networkError(Error)
    case decodingError(Error)
    case encodingError(Error)
    case notFound
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User not authenticated"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Data decoding error: \(error.localizedDescription)"
        case .encodingError(let error):
            return "Data encoding error: \(error.localizedDescription)"
        case .notFound:
            return "Resource not found"
        case .invalidData:
            return "Invalid data provided"
        }
    }
}

// MARK: - Supabase Service

@MainActor
class SupabaseService: ObservableObject {
    static let shared = SupabaseService()
    
    private let supabase = SupabaseManager.shared.client
    
    // MARK: - Published Properties for Food Tracking
    @Published var todaysEntries: [FoodEntry] = []
    @Published var recentFoods: [FoodItem] = []
    @Published var isFoodTrackingLoading = false
    @Published var foodTrackingErrorMessage: String?
    
    // MARK: - Cache Properties
    private var macroAchievementsCache: [Date: MacroData] = [:]
    private var cacheTimestamp: Date = Date.distantPast
    private let cacheValidityDuration: TimeInterval = 300 // 5 minutes
    
    private init() {}
    
    private var currentUserId: UUID? {
        supabase.auth.currentUser?.id
    }
    
    func ensureAuthenticated() throws -> UUID {
        guard let userId = currentUserId else {
            throw SupabaseServiceError.notAuthenticated
        }
        return userId
    }
    
    // MARK: - Macro Goals CRUD
    
    func getMacroGoals() async throws -> MacroGoals? {
        let userId = try ensureAuthenticated()
        
        do {
            let response: [DBMacroGoals] = try await supabase
                .from("macro_goals")
                .select()
                .eq("user_id", value: userId)
                .execute()
                .value
            
            return response.first?.toMacroGoals()
        } catch {
            throw SupabaseServiceError.networkError(error)
        }
    }
    
    func saveMacroGoals(_ goals: MacroGoals) async throws {
        let userId = try ensureAuthenticated()
        
        let dbGoals = DBMacroGoals(
            id: nil,
            userId: userId,
            calories: goals.calories,
            protein: goals.protein,
            carbs: goals.carbs,
            fat: goals.fat,
            createdAt: nil,
            updatedAt: nil
        )
        
        do {
            try await supabase
                .from("macro_goals")
                .upsert(dbGoals)
                .execute()
        } catch {
            throw SupabaseServiceError.networkError(error)
        }
    }
    
    // MARK: - Meal Plans CRUD
    
    func getMealPlans() async throws -> [MealPlan] {
        let userId = try ensureAuthenticated()
        
        do {
            let response: [DBMealPlan] = try await supabase
                .from("meal_plans")
                .select()
                .eq("user_id", value: userId)
                .order("created_at", ascending: false)
                .execute()
                .value
            
            return response.compactMap { $0.toMealPlan() }
        } catch {
            throw SupabaseServiceError.networkError(error)
        }
    }
    
    func saveMealPlan(_ mealPlan: MealPlan) async throws {
        let userId = try ensureAuthenticated()
        
        var generatedContentData: Data?
        if let generatedPlan = mealPlan.generatedMealPlan {
            do {
                generatedContentData = try JSONEncoder().encode(generatedPlan)
            } catch {
                throw SupabaseServiceError.encodingError(error)
            }
        }
        
        let dbMealPlan = DBMealPlan(
            id: mealPlan.id,
            userId: userId,
            title: mealPlan.generatedMealPlan?.title ?? "Meal Plan",
            description: mealPlan.generatedMealPlan?.description,
            startDate: mealPlan.startDate,
            numberOfDays: mealPlan.numberOfDays,
            mealPlanText: mealPlan.mealPlanText,
            isAIGenerated: mealPlan.isAIGenerated,
            generatedContent: generatedContentData,
            createdAt: mealPlan.createdAt,
            updatedAt: nil
        )
        
        do {
            try await supabase
                .from("meal_plans")
                .upsert(dbMealPlan)
                .execute()
        } catch {
            throw SupabaseServiceError.networkError(error)
        }
    }
    
    func deleteMealPlan(_ mealPlan: MealPlan) async throws {
        let userId = try ensureAuthenticated()
        
        do {
            try await supabase
                .from("meal_plans")
                .delete()
                .eq("id", value: mealPlan.id)
                .eq("user_id", value: userId)
                .execute()
        } catch {
            throw SupabaseServiceError.networkError(error)
        }
    }
    
    // MARK: - Shopping Lists CRUD
    
    func getShoppingLists() async throws -> [ShoppingList] {
        let userId = try ensureAuthenticated()
        
        do {
            // Get shopping lists
            let listsResponse: [DBShoppingList] = try await supabase
                .from("shopping_lists")
                .select()
                .eq("user_id", value: userId)
                .order("created_at", ascending: false)
                .execute()
                .value
            
            var shoppingLists: [ShoppingList] = []
            
            for dbList in listsResponse {
                guard let listId = dbList.id else { continue }
                
                // Get items for this shopping list
                let itemsResponse: [DBShoppingListItem] = try await supabase
                    .from("shopping_list_items")
                    .select()
                    .eq("shopping_list_id", value: listId)
                    .execute()
                    .value
                
                let items = itemsResponse.map { $0.toShoppingListItem(mealPlanId: dbList.mealPlanId) }
                
                // Create ShoppingList with items
                let shoppingList = ShoppingList(
                    id: listId,
                    mealPlanId: dbList.mealPlanId,
                    mealPlanTitle: dbList.mealPlanTitle,
                    items: items,
                    createdAt: dbList.createdAt ?? Date()
                )
                
                shoppingLists.append(shoppingList)
            }
            
            return shoppingLists
        } catch {
            throw SupabaseServiceError.networkError(error)
        }
    }
    
    func saveShoppingList(_ shoppingList: ShoppingList) async throws {
        let userId = try ensureAuthenticated()
        
        do {
            // First, save the shopping list
            let dbShoppingList = DBShoppingList(
                id: shoppingList.id,
                userId: userId,
                mealPlanId: shoppingList.mealPlanId,
                mealPlanTitle: shoppingList.mealPlanTitle,
                createdAt: shoppingList.createdAt,
                updatedAt: nil
            )
            
            try await supabase
                .from("shopping_lists")
                .upsert(dbShoppingList)
                .execute()
            
            // Delete existing items for this shopping list
            try await supabase
                .from("shopping_list_items")
                .delete()
                .eq("shopping_list_id", value: shoppingList.id)
                .execute()
            
            // Insert new items
            if !shoppingList.items.isEmpty {
                let dbItems = shoppingList.items.map { item in
                    DBShoppingListItem(
                        id: item.id,
                        shoppingListId: shoppingList.id,
                        name: item.name,
                        amount: item.amount,
                        category: item.category.rawValue,
                        isCompleted: item.isCompleted,
                        createdAt: nil,
                        updatedAt: nil
                    )
                }
                
                try await supabase
                    .from("shopping_list_items")
                    .insert(dbItems)
                    .execute()
            }
        } catch {
            throw SupabaseServiceError.networkError(error)
        }
    }
    
    func updateShoppingListItem(_ item: ShoppingListItem, in shoppingList: ShoppingList) async throws {
        do {
            let dbItem = DBShoppingListItem(
                id: item.id,
                shoppingListId: shoppingList.id,
                name: item.name,
                amount: item.amount,
                category: item.category.rawValue,
                isCompleted: item.isCompleted,
                createdAt: nil,
                updatedAt: nil
            )
            
            try await supabase
                .from("shopping_list_items")
                .update(dbItem)
                .eq("id", value: item.id)
                .execute()
        } catch {
            throw SupabaseServiceError.networkError(error)
        }
    }
    
    func deleteShoppingList(_ shoppingList: ShoppingList) async throws {
        let userId = try ensureAuthenticated()
        
        do {
            try await supabase
                .from("shopping_lists")
                .delete()
                .eq("id", value: shoppingList.id)
                .eq("user_id", value: userId)
                .execute()
        } catch {
            throw SupabaseServiceError.networkError(error)
        }
    }
    
    func getShoppingList(for mealPlanId: UUID) async throws -> ShoppingList? {
        let userId = try ensureAuthenticated()
        
        do {
            let listsResponse: [DBShoppingList] = try await supabase
                .from("shopping_lists")
                .select()
                .eq("user_id", value: userId)
                .eq("meal_plan_id", value: mealPlanId)
                .execute()
                .value
            
            guard let dbList = listsResponse.first, let listId = dbList.id else {
                return nil
            }
            
            // Get items for this shopping list
            let itemsResponse: [DBShoppingListItem] = try await supabase
                .from("shopping_list_items")
                .select()
                .eq("shopping_list_id", value: listId)
                .execute()
                .value
            
            let items = itemsResponse.map { $0.toShoppingListItem(mealPlanId: dbList.mealPlanId) }
            
            return ShoppingList(
                id: listId,
                mealPlanId: dbList.mealPlanId,
                mealPlanTitle: dbList.mealPlanTitle,
                items: items,
                createdAt: dbList.createdAt ?? Date()
            )
        } catch {
            throw SupabaseServiceError.networkError(error)
        }
    }
    
    // MARK: - Food Items CRUD
    
    func searchFoods(query: String, limit: Int = 20) async throws -> [FoodItem] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }
        
        do {
            let response: [DBFoodItem] = try await supabase
                .from("food_items")
                .select()
                .or("name.ilike.%\(query)%,brand.ilike.%\(query)%")
                .order("is_verified", ascending: false)
                .order("name", ascending: true)
                .limit(limit)
                .execute()
                .value
            
            return response.map { $0.toFoodItem() }
        } catch {
            throw SupabaseServiceError.networkError(error)
        }
    }
    
    func getFoodItem(by id: UUID) async throws -> FoodItem? {
        do {
            let response: [DBFoodItem] = try await supabase
                .from("food_items")
                .select()
                .eq("id", value: id)
                .execute()
                .value
            
            return response.first?.toFoodItem()
        } catch {
            throw SupabaseServiceError.networkError(error)
        }
    }
    
    func createFoodItem(_ food: FoodItem) async throws -> FoodItem {
        let userId = try ensureAuthenticated()
        
        // Check if food already exists to prevent duplicates
        let existingFoods = try await searchFoodsByNameAndBrand(
            name: food.name,
            brand: food.brand
        )
        
        if let existing = existingFoods.first {
            return existing
        }
        
        var newFood = food
        newFood = FoodItem(
            id: food.id,
            name: food.name,
            brand: food.brand,
            barcode: food.barcode,
            caloriesPer100g: food.caloriesPer100g,
            proteinPer100g: food.proteinPer100g,
            carbsPer100g: food.carbsPer100g,
            fatPer100g: food.fatPer100g,
            fiberPer100g: food.fiberPer100g,
            sugarPer100g: food.sugarPer100g,
            sodiumPer100g: food.sodiumPer100g,
            isVerified: food.isVerified,
            sourceUrl: food.sourceUrl,
            lastVerifiedAt: food.lastVerifiedAt,
            createdByUserId: userId
        )
        
        let dbFood = DBFoodItem(from: newFood)
        
        do {
            let response: [DBFoodItem] = try await supabase
                .from("food_items")
                .insert(dbFood)
                .select()
                .execute()
                .value
            
            guard let createdFood = response.first else {
                throw SupabaseServiceError.notFound
            }
            
            return createdFood.toFoodItem()
        } catch {
            throw SupabaseServiceError.networkError(error)
        }
    }
    
    func updateFoodItem(_ food: FoodItem) async throws -> FoodItem {
        let dbFood = DBFoodItem(from: food)
        
        do {
            let response: [DBFoodItem] = try await supabase
                .from("food_items")
                .update(dbFood)
                .eq("id", value: food.id)
                .select()
                .execute()
                .value
            
            guard let updatedFood = response.first else {
                throw SupabaseServiceError.notFound
            }
            
            return updatedFood.toFoodItem()
        } catch {
            throw SupabaseServiceError.networkError(error)
        }
    }
    
    private func searchFoodsByNameAndBrand(name: String, brand: String?) async throws -> [FoodItem] {
        var query = supabase
            .from("food_items")
            .select()
            .eq("name", value: name)
        
        if let brand = brand, !brand.isEmpty {
            query = query.eq("brand", value: brand)
        } else {
            query = query.is("brand", value: nil)
        }
        
        do {
            let response: [DBFoodItem] = try await query
                .execute()
                .value
            
            return response.map { $0.toFoodItem() }
        } catch {
            throw SupabaseServiceError.networkError(error)
        }
    }
    
    // MARK: - Food Entries CRUD
    
    func logFoodEntry(_ entry: FoodEntry) async throws {
        let dbEntry = DBFoodEntry(from: entry)
        
        do {
            try await supabase
                .from("food_entries")
                .insert(dbEntry)
                .execute()
            
            // Invalidate cache and reload today's entries
            invalidateCache()
            await loadTodaysEntries()
        } catch {
            throw SupabaseServiceError.networkError(error)
        }
    }
    
    func logFoodEntries(_ entries: [FoodEntry]) async throws {
        let dbEntries = entries.map { DBFoodEntry(from: $0) }
        
        do {
            try await supabase
                .from("food_entries")
                .insert(dbEntries)
                .execute()
            
            // Invalidate cache and reload today's entries
            invalidateCache()
            await loadTodaysEntries()
        } catch {
            throw SupabaseServiceError.networkError(error)
        }
    }
    
    func updateFoodEntry(_ entry: FoodEntry) async throws {
        let dbEntry = DBFoodEntry(from: entry)
        
        do {
            try await supabase
                .from("food_entries")
                .update(dbEntry)
                .eq("id", value: entry.id)
                .execute()
            
            // Invalidate cache and reload today's entries
            invalidateCache()
            await loadTodaysEntries()
        } catch {
            throw SupabaseServiceError.networkError(error)
        }
    }
    
    func deleteFoodEntry(_ entry: FoodEntry) async throws {
        let userId = try ensureAuthenticated()
        
        do {
            try await supabase
                .from("food_entries")
                .delete()
                .eq("id", value: entry.id)
                .eq("user_id", value: userId)
                .execute()
            
            // Invalidate cache and reload today's entries
            invalidateCache()
            await loadTodaysEntries()
        } catch {
            throw SupabaseServiceError.networkError(error)
        }
    }
    
    func getTodaysEntries() async throws -> [FoodEntry] {
        print("🔄 getTodaysEntries called")  // <- BREAKPOINT HERE
        let userId = try ensureAuthenticated()
        
        // Use a more lenient date range to account for timezone differences
        let now = Date()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        // Add some buffer to account for timezone differences
        let startOfYesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let endOfTomorrow = calendar.date(byAdding: .day, value: 2, to: today)!
        
        print("🔄 Querying for entries between \(startOfYesterday) and \(endOfTomorrow)")
        print("🔄 Today is: \(today)")
        
        do {
            let response: [DBFoodEntry] = try await supabase
                .from("food_entries")
                .select()
                .eq("user_id", value: userId)
                .gte("consumed_date", value: startOfYesterday)
                .lt("consumed_date", value: endOfTomorrow)
                .order("created_at", ascending: false)
                .execute()
                .value
            
            print("🔄 Raw database response count: \(response.count)")
            
            // Convert to FoodEntry with attached FoodItem and filter locally for today
            let allEntries = response.map { dbEntry in
                var entry = dbEntry.toFoodEntry()
                // Note: In a real implementation, you'd parse the joined food_items data
                // For now, we'll load food items separately if needed
                return entry
            }
            
            print("🔄 All entries count after conversion: \(allEntries.count)")
            for entry in allEntries {
                print("🔄 Entry consumed_date: \(entry.consumedDate)")
            }
            
            // Filter for today's entries locally to handle timezone differences
            let todaysEntries = allEntries.filter { entry in
                let entryDay = calendar.startOfDay(for: entry.consumedDate)
                let isToday = entryDay == today
                print("🔄 Entry \(entry.id): entryDay=\(entryDay), today=\(today), isToday=\(isToday)")
                return isToday
            }
            
            print("🔄 Filtered today's entries count: \(todaysEntries.count)")
            return todaysEntries
        } catch {
            print("❌ Error in getTodaysEntries: \(error)")
            if let decodingError = error as? DecodingError {
                print("❌ Decoding error details: \(decodingError)")
            }
            throw SupabaseServiceError.networkError(error)
        }
    }
    
    func getEntriesForDateRange(from startDate: Date, to endDate: Date) async throws -> [FoodEntry] {
        let userId = try ensureAuthenticated()
        
        do {
            let response: [DBFoodEntry] = try await supabase
                .from("food_entries")
                .select()
                .eq("user_id", value: userId)
                .gte("consumed_date", value: startDate)
                .lte("consumed_date", value: endDate)
                .order("consumed_date", ascending: false)
                .order("created_at", ascending: false)
                .execute()
                .value
            
            return response.map { $0.toFoodEntry() }
        } catch {
            throw SupabaseServiceError.networkError(error)
        }
    }
    
    func getEntriesForDate(_ date: Date) async throws -> [FoodEntry] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        print("🗓️ Getting entries for date: \(date)")
        print("🗓️ Start of day: \(startOfDay), End of day: \(endOfDay)")
        
        let entries = try await getEntriesForDateRange(from: startOfDay, to: endOfDay)
        
        print("🗓️ Found \(entries.count) entries before filtering")
        
        // Filter to ensure we only get entries for this specific day
        let filteredEntries = entries.filter { entry in
            calendar.isDate(entry.consumedDate, inSameDayAs: date)
        }
        
        print("🗓️ Found \(filteredEntries.count) entries after filtering for same day")
        
        // Load food items for entries
        var entriesWithFoodItems: [FoodEntry] = []
        for entry in filteredEntries {
            if entry.foodItem == nil {
                if let foodItem = try await getFoodItem(by: entry.foodItemId) {
                    var updatedEntry = entry
                    updatedEntry.foodItem = foodItem
                    entriesWithFoodItems.append(updatedEntry)
                } else {
                    entriesWithFoodItems.append(entry)
                }
            } else {
                entriesWithFoodItems.append(entry)
            }
        }
        
        return entriesWithFoodItems
    }
    
    func calculateMacroAchievements(for date: Date) async throws -> MacroData {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM dd"
        let dateString = dateFormatter.string(from: date)
        let startTime = Date()
        
        print("🔍 SupabaseService: Starting macro calculation for \(dateString)")
        
        print("🔍 SupabaseService: Fetching food entries for \(dateString)...")
        let entriesStartTime = Date()
        let entries = try await getEntriesForDate(date)
        let entriesDuration = Date().timeIntervalSince(entriesStartTime)
        
        print("🔍 SupabaseService: Found \(entries.count) food entries for \(dateString) in \(String(format: "%.2f", entriesDuration))s")
        
        // Get macro goals
        print("🔍 SupabaseService: Fetching macro goals for \(dateString)...")
        let goalsStartTime = Date()
        guard let goals = try await getMacroGoals() else {
            print("❌ SupabaseService: No macro goals found for \(dateString)")
            return MacroData.empty
        }
        let goalsDuration = Date().timeIntervalSince(goalsStartTime)
        print("🔍 SupabaseService: Retrieved macro goals for \(dateString) in \(String(format: "%.2f", goalsDuration))s")
        
        // Calculate totals
        let totals = entries.reduce((calories: 0.0, protein: 0.0, carbs: 0.0, fat: 0.0)) { result, entry in
            (result.calories + entry.calories,
             result.protein + entry.proteinG,
             result.carbs + entry.carbsG,
             result.fat + entry.fatG)
        }
        
        // Check achievements (consider achieved if >= 100% of goal)
        let achievements = MacroData(
            caloriesAchieved: totals.calories >= goals.calories,
            proteinAchieved: totals.protein >= goals.protein,
            carbsAchieved: totals.carbs >= goals.carbs,
            fatAchieved: totals.fat >= goals.fat
        )
        
        let totalDuration = Date().timeIntervalSince(startTime)
        print("🔍 SupabaseService: ✅ Completed macro calculation for \(dateString) in \(String(format: "%.2f", totalDuration))s - Achievements: C:\(achievements.caloriesAchieved) P:\(achievements.proteinAchieved) R:\(achievements.carbsAchieved) F:\(achievements.fatAchieved)")
        
        return achievements
    }
    
    func calculateBulkMacroAchievements(for dates: [Date]) async throws -> [Date: MacroData] {
        let startTime = Date()
        print("🔍 SupabaseService: Starting bulk macro calculation for \(dates.count) dates")
        
        guard !dates.isEmpty else {
            return [:]
        }
        
        // Get date range for bulk query
        let sortedDates = dates.sorted()
        let startDate = Calendar.current.startOfDay(for: sortedDates.first!)
        let endDate = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: sortedDates.last!))!
        
        // Single bulk query for all food entries in date range
        print("🔍 SupabaseService: Fetching food entries for date range \(startDate) to \(endDate)")
        let entriesStartTime = Date()
        let allEntries = try await getEntriesForDateRange(from: startDate, to: endDate)
        let entriesDuration = Date().timeIntervalSince(entriesStartTime)
        print("🔍 SupabaseService: Found \(allEntries.count) total food entries in \(String(format: "%.2f", entriesDuration))s")
        
        // Single query for macro goals
        print("🔍 SupabaseService: Fetching macro goals...")
        let goalsStartTime = Date()
        guard let goals = try await getMacroGoals() else {
            print("❌ SupabaseService: No macro goals found")
            return dates.reduce(into: [Date: MacroData]()) { result, date in
                result[date] = MacroData.empty
            }
        }
        let goalsDuration = Date().timeIntervalSince(goalsStartTime)
        print("🔍 SupabaseService: Retrieved macro goals in \(String(format: "%.2f", goalsDuration))s")
        
        // Group entries by date
        let calendar = Calendar.current
        let entriesByDate = Dictionary(grouping: allEntries) { entry in
            calendar.startOfDay(for: entry.consumedDate)
        }
        
        // Calculate achievements for each date
        var results: [Date: MacroData] = [:]
        
        for date in dates {
            let dayStart = calendar.startOfDay(for: date)
            let entriesForDate = entriesByDate[dayStart] ?? []
            
            // Calculate totals for this date
            let totals = entriesForDate.reduce((calories: 0.0, protein: 0.0, carbs: 0.0, fat: 0.0)) { result, entry in
                (result.calories + entry.calories,
                 result.protein + entry.proteinG,
                 result.carbs + entry.carbsG,
                 result.fat + entry.fatG)
            }
            
            // Check achievements
            let achievements = MacroData(
                caloriesAchieved: totals.calories >= goals.calories,
                proteinAchieved: totals.protein >= goals.protein,
                carbsAchieved: totals.carbs >= goals.carbs,
                fatAchieved: totals.fat >= goals.fat
            )
            
            results[date] = achievements
        }
        
        let totalDuration = Date().timeIntervalSince(startTime)
        print("🔍 SupabaseService: ✅ Completed bulk macro calculation for \(dates.count) dates in \(String(format: "%.2f", totalDuration))s")
        
        return results
    }
    
    // MARK: - Cache Management
    
    private func isCacheValid() -> Bool {
        Date().timeIntervalSince(cacheTimestamp) < cacheValidityDuration
    }
    
    private func invalidateCache() {
        macroAchievementsCache.removeAll()
        cacheTimestamp = Date.distantPast
        print("🗑️ SupabaseService: Cache invalidated")
    }
    
    func getCachedMacroAchievements(for dates: [Date]) async throws -> [Date: MacroData] {
        let startTime = Date()
        
        // Check if cache is valid and contains all requested dates
        if isCacheValid() {
            let cachedResults = dates.compactMap { date in
                macroAchievementsCache[Calendar.current.startOfDay(for: date)].map { (date, $0) }
            }
            
            if cachedResults.count == dates.count {
                print("🎯 SupabaseService: Cache hit for all \(dates.count) dates in \(String(format: "%.3f", Date().timeIntervalSince(startTime)))s")
                return Dictionary(uniqueKeysWithValues: cachedResults)
            }
        }
        
        // Cache miss or invalid - fetch new data
        print("💾 SupabaseService: Cache miss or invalid, fetching new data")
        let results = try await calculateBulkMacroAchievements(for: dates)
        
        // Update cache
        let calendar = Calendar.current
        for (date, macroData) in results {
            let dayStart = calendar.startOfDay(for: date)
            macroAchievementsCache[dayStart] = macroData
        }
        cacheTimestamp = Date()
        
        let totalTime = Date().timeIntervalSince(startTime)
        print("💾 SupabaseService: Updated cache with \(results.count) entries in \(String(format: "%.2f", totalTime))s")
        
        return results
    }
    
    // MARK: - Food Tracking Convenience Methods
    
    func loadTodaysEntries() async {
        print("🔄 loadTodaysEntries called")  // <- BREAKPOINT HERE
        do {
            isFoodTrackingLoading = true
            foodTrackingErrorMessage = nil
            print("🔄 About to call getTodaysEntries")
            let entries = try await getTodaysEntries()
            print("🔄 getTodaysEntries returned \(entries.count) entries")
            
            // Load food items for entries that don't have them
            var entriesWithFoodItems: [FoodEntry] = []
            for entry in entries {
                if entry.foodItem == nil {
                    if let foodItem = try await getFoodItem(by: entry.foodItemId) {
                        var updatedEntry = entry
                        updatedEntry.foodItem = foodItem
                        entriesWithFoodItems.append(updatedEntry)
                    } else {
                        entriesWithFoodItems.append(entry)
                    }
                } else {
                    entriesWithFoodItems.append(entry)
                }
            }
            
            todaysEntries = entriesWithFoodItems
        } catch {
            foodTrackingErrorMessage = error.localizedDescription
            print("Error loading today's entries: \(error)")
        }
        isFoodTrackingLoading = false
    }
    
    func loadRecentFoods() async {
        do {
            let userId = try ensureAuthenticated()
            
            // Get recently used food items from entries
            let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
            
            let response: [DBFoodEntry] = try await supabase
                .from("food_entries")
                .select("food_item_id")
                .eq("user_id", value: userId)
                .gte("consumed_date", value: thirtyDaysAgo)
                .order("created_at", ascending: false)
                .limit(50)
                .execute()
                .value
            
            // Get unique food item IDs
            let uniqueFoodItemIds = Array(Set(response.map { $0.foodItemId })).prefix(20)
            
            // Fetch the actual food items
            if !uniqueFoodItemIds.isEmpty {
                let foodResponse: [DBFoodItem] = try await supabase
                    .from("food_items")
                    .select()
                    .in("id", values: Array(uniqueFoodItemIds))
                    .execute()
                    .value
                
                recentFoods = foodResponse.map { $0.toFoodItem() }
            }
        } catch {
            print("Error loading recent foods: \(error)")
        }
    }
    
    func getTodaysNutritionSummary() -> NutritionInfo {
        return todaysEntries.totalNutrition()
    }
    
    func createFoodEntryFromAnalysis(
        analyzedFood: ClaudeAPIClient.AnalyzedFood,
        quantity: Double,
        mealType: MealType,
        source: FoodEntrySource
    ) async throws -> FoodEntry {
        let userId = try ensureAuthenticated()
        
        // Get or create the food item
        let foodItem: FoodItem
        if let existingId = analyzedFood.databaseId,
           let existing = try await getFoodItem(by: existingId) {
            foodItem = existing
        } else {
            // Create new food item
            let newFoodItem = FoodItem(
                name: analyzedFood.name,
                brand: analyzedFood.brand,
                caloriesPer100g: analyzedFood.nutrition.calories,
                proteinPer100g: analyzedFood.nutrition.protein,
                carbsPer100g: analyzedFood.nutrition.carbs,
                fatPer100g: analyzedFood.nutrition.fat,
                fiberPer100g: analyzedFood.nutrition.fiber,
                sugarPer100g: analyzedFood.nutrition.sugar,
                sodiumPer100g: analyzedFood.nutrition.sodium,
                isVerified: true // Claude-verified
            )
            foodItem = try await createFoodItem(newFoodItem)
        }
        
        // Calculate nutrition for the specific quantity
        let nutrition = foodItem.calculateNutrition(for: quantity)
        
        // Create food entry
        let entry = FoodEntry(
            userId: userId,
            foodItemId: foodItem.id,
            mealType: mealType,
            quantityGrams: quantity,
            calories: nutrition.calories,
            proteinG: nutrition.protein,
            carbsG: nutrition.carbs,
            fatG: nutrition.fat,
            source: source,
            confidenceScore: analyzedFood.confidence,
            foodItem: foodItem
        )
        
        try await logFoodEntry(entry)
        return entry
    }
    
    // MARK: - Integration with ClaudeAPIClient
    
    func searchFoodDatabaseForClaude(query: String, limit: Int = 10) async throws -> [[String: Any]] {
        let foods = try await searchFoods(query: query, limit: limit)
        
        return foods.map { food in
            [
                "id": food.id.uuidString,
                "name": food.name,
                "brand": food.brand as Any? ?? "",
                "calories_per_100g": food.caloriesPer100g,
                "protein_per_100g": food.proteinPer100g,
                "carbs_per_100g": food.carbsPer100g,
                "fat_per_100g": food.fatPer100g,
                "fiber_per_100g": food.fiberPer100g ?? 0,
                "sugar_per_100g": food.sugarPer100g ?? 0,
                "sodium_per_100g": food.sodiumPer100g ?? 0,
                "is_verified": food.isVerified
            ]
        }
    }
}