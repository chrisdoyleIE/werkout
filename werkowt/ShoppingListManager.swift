import Foundation

struct ShoppingListItem: Identifiable, Codable {
    let id = UUID()
    let name: String
    let amount: String
    let category: ShoppingCategory
    var isCompleted: Bool = false
    let mealPlanId: UUID
    
    init(name: String, amount: String = "", category: ShoppingCategory = .other, mealPlanId: UUID) {
        self.name = name
        self.amount = amount
        self.category = category
        self.mealPlanId = mealPlanId
    }
    
    // Legacy initializer for backward compatibility
    init(name: String, category: String? = nil, mealPlanId: UUID) {
        self.name = name
        self.amount = ""
        self.category = ShoppingCategory(rawValue: category ?? "Other") ?? .other
        self.mealPlanId = mealPlanId
    }
}

struct ShoppingList: Identifiable, Codable {
    let id: UUID
    let mealPlanId: UUID
    let mealPlanTitle: String
    var items: [ShoppingListItem]
    let createdAt: Date
    
    var completedItems: [ShoppingListItem] {
        items.filter { $0.isCompleted }
    }
    
    var remainingItems: [ShoppingListItem] {
        items.filter { !$0.isCompleted }
    }
    
    var completionPercentage: Double {
        guard !items.isEmpty else { return 0 }
        return Double(completedItems.count) / Double(items.count)
    }
    
    var completionText: String {
        "\(completedItems.count) of \(items.count) completed"
    }
    
    var categorizedItems: [ShoppingCategory: [ShoppingListItem]] {
        Dictionary(grouping: items) { $0.category }
    }
    
    // Initializer for creating from MealPlan
    init(mealPlan: MealPlan) {
        self.id = UUID()
        self.mealPlanId = mealPlan.id
        self.mealPlanTitle = mealPlan.generatedMealPlan?.title ?? "Meal Plan"
        self.createdAt = Date()
        
        // Create items from meal plan
        var shoppingItems: [ShoppingListItem] = []
        
        if let generatedPlan = mealPlan.generatedMealPlan {
            // Use new structured shopping list if available
            if let structuredList = generatedPlan.shoppingList {
                for itemDetail in structuredList {
                    shoppingItems.append(ShoppingListItem(
                        name: itemDetail.name,
                        amount: itemDetail.amount,
                        category: itemDetail.category,
                        mealPlanId: mealPlan.id
                    ))
                }
            }
            // Fall back to legacy categorized shopping list
            else if let categorizedList = generatedPlan.categorizedShoppingList {
                for (categoryString, items) in categorizedList {
                    let category = ShoppingCategory(rawValue: categoryString) ?? .other
                    for item in items {
                        shoppingItems.append(ShoppingListItem(
                            name: item,
                            amount: "",
                            category: category,
                            mealPlanId: mealPlan.id
                        ))
                    }
                }
            }
        }
        
        self.items = shoppingItems
    }
    
    // Initializer for database loading
    init(id: UUID, mealPlanId: UUID, mealPlanTitle: String, items: [ShoppingListItem], createdAt: Date) {
        self.id = id
        self.mealPlanId = mealPlanId
        self.mealPlanTitle = mealPlanTitle
        self.items = items
        self.createdAt = createdAt
    }
}

class ShoppingListManager: ObservableObject {
    @Published var shoppingLists: [ShoppingList] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let supabaseService = SupabaseService.shared
    
    init() {
        Task {
            await loadShoppingLists()
        }
    }
    
    @MainActor
    func createShoppingList(for mealPlan: MealPlan) async -> ShoppingList {
        // Check if shopping list already exists for this meal plan
        if let existingList = shoppingLists.first(where: { $0.mealPlanId == mealPlan.id }) {
            return existingList
        }
        
        // Try to load from database first
        do {
            if let existingList = try await supabaseService.getShoppingList(for: mealPlan.id) {
                if !shoppingLists.contains(where: { $0.id == existingList.id }) {
                    shoppingLists.append(existingList)
                }
                return existingList
            }
        } catch {
            self.error = error
        }
        
        // Create new list if none exists
        let newList = ShoppingList(mealPlan: mealPlan)
        do {
            try await supabaseService.saveShoppingList(newList)
            shoppingLists.append(newList)
        } catch {
            self.error = error
        }
        return newList
    }
    
    @MainActor
    func toggleItemCompletion(_ item: ShoppingListItem) async {
        guard let listIndex = shoppingLists.firstIndex(where: { $0.items.contains { $0.id == item.id } }),
              let itemIndex = shoppingLists[listIndex].items.firstIndex(where: { $0.id == item.id }) else {
            return
        }
        
        shoppingLists[listIndex].items[itemIndex].isCompleted.toggle()
        
        do {
            try await supabaseService.updateShoppingListItem(
                shoppingLists[listIndex].items[itemIndex],
                in: shoppingLists[listIndex]
            )
        } catch {
            // Revert the change if database update fails
            shoppingLists[listIndex].items[itemIndex].isCompleted.toggle()
            self.error = error
        }
    }
    
    @MainActor
    func resetShoppingList(_ shoppingList: ShoppingList) async {
        guard let listIndex = shoppingLists.firstIndex(where: { $0.id == shoppingList.id }) else {
            return
        }
        
        for itemIndex in shoppingLists[listIndex].items.indices {
            shoppingLists[listIndex].items[itemIndex].isCompleted = false
        }
        
        do {
            try await supabaseService.saveShoppingList(shoppingLists[listIndex])
        } catch {
            self.error = error
        }
    }
    
    @MainActor
    func deleteShoppingList(_ shoppingList: ShoppingList) async {
        do {
            try await supabaseService.deleteShoppingList(shoppingList)
            shoppingLists.removeAll { $0.id == shoppingList.id }
        } catch {
            self.error = error
        }
    }
    
    func getShoppingList(for mealPlanId: UUID) -> ShoppingList? {
        return shoppingLists.first { $0.mealPlanId == mealPlanId }
    }
    
    @MainActor
    private func loadShoppingLists() async {
        isLoading = true
        do {
            shoppingLists = try await supabaseService.getShoppingLists()
        } catch {
            self.error = error
        }
        isLoading = false
    }
    
    @MainActor
    func refreshShoppingLists() async {
        await loadShoppingLists()
    }
}