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
    
    private init() {}
    
    private var currentUserId: UUID? {
        supabase.auth.currentUser?.id
    }
    
    private func ensureAuthenticated() throws -> UUID {
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
}