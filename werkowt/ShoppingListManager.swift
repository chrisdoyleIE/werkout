import Foundation

struct ShoppingListItem: Identifiable, Codable {
    let id = UUID()
    let name: String
    let category: String?
    var isCompleted: Bool = false
    let mealPlanId: UUID
    
    init(name: String, category: String? = nil, mealPlanId: UUID) {
        self.name = name
        self.category = category
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
    
    var categorizedItems: [String: [ShoppingListItem]] {
        Dictionary(grouping: items) { $0.category ?? "Other" }
    }
    
    init(mealPlan: MealPlan) {
        self.id = UUID()
        self.mealPlanId = mealPlan.id
        self.mealPlanTitle = mealPlan.generatedMealPlan?.title ?? "Meal Plan"
        self.createdAt = Date()
        
        // Create items from meal plan
        var shoppingItems: [ShoppingListItem] = []
        
        if let generatedPlan = mealPlan.generatedMealPlan {
            // Use categorized shopping list if available
            if let categorizedList = generatedPlan.categorizedShoppingList {
                for (category, items) in categorizedList {
                    for item in items {
                        shoppingItems.append(ShoppingListItem(
                            name: item,
                            category: category,
                            mealPlanId: mealPlan.id
                        ))
                    }
                }
            }
            // Fall back to regular shopping list
            else if let regularList = generatedPlan.shoppingList {
                for item in regularList {
                    shoppingItems.append(ShoppingListItem(
                        name: item,
                        category: nil,
                        mealPlanId: mealPlan.id
                    ))
                }
            }
        }
        
        self.items = shoppingItems
    }
}

class ShoppingListManager: ObservableObject {
    @Published var shoppingLists: [ShoppingList] = []
    
    private let userDefaults = UserDefaults.standard
    private let shoppingListsKey = "ShoppingLists"
    
    init() {
        loadShoppingLists()
    }
    
    func createShoppingList(for mealPlan: MealPlan) -> ShoppingList {
        // Check if shopping list already exists for this meal plan
        if let existingList = shoppingLists.first(where: { $0.mealPlanId == mealPlan.id }) {
            return existingList
        }
        
        let newList = ShoppingList(mealPlan: mealPlan)
        shoppingLists.append(newList)
        saveShoppingLists()
        return newList
    }
    
    func toggleItemCompletion(_ item: ShoppingListItem) {
        guard let listIndex = shoppingLists.firstIndex(where: { $0.items.contains { $0.id == item.id } }),
              let itemIndex = shoppingLists[listIndex].items.firstIndex(where: { $0.id == item.id }) else {
            return
        }
        
        shoppingLists[listIndex].items[itemIndex].isCompleted.toggle()
        saveShoppingLists()
    }
    
    func resetShoppingList(_ shoppingList: ShoppingList) {
        guard let listIndex = shoppingLists.firstIndex(where: { $0.id == shoppingList.id }) else {
            return
        }
        
        for itemIndex in shoppingLists[listIndex].items.indices {
            shoppingLists[listIndex].items[itemIndex].isCompleted = false
        }
        saveShoppingLists()
    }
    
    func deleteShoppingList(_ shoppingList: ShoppingList) {
        shoppingLists.removeAll { $0.id == shoppingList.id }
        saveShoppingLists()
    }
    
    func getShoppingList(for mealPlanId: UUID) -> ShoppingList? {
        return shoppingLists.first { $0.mealPlanId == mealPlanId }
    }
    
    private func saveShoppingLists() {
        if let encoded = try? JSONEncoder().encode(shoppingLists) {
            userDefaults.set(encoded, forKey: shoppingListsKey)
        }
    }
    
    private func loadShoppingLists() {
        if let data = userDefaults.data(forKey: shoppingListsKey),
           let decoded = try? JSONDecoder().decode([ShoppingList].self, from: data) {
            shoppingLists = decoded.sorted { $0.createdAt > $1.createdAt }
        }
    }
}