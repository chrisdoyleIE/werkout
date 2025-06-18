import Foundation

@MainActor
class DataMigrationHelper: ObservableObject {
    @Published var isMigrating = false
    @Published var migrationProgress = ""
    @Published var migrationError: Error?
    @Published var migrationCompleted = false
    
    private let supabaseService = SupabaseService.shared
    private let userDefaults = UserDefaults.standard
    
    static let shared = DataMigrationHelper()
    
    private init() {}
    
    // Migration keys
    private let migrationCompletedKey = "SupabaseMigrationCompleted"
    private let mealPlansKey = "SavedMealPlans"
    private let shoppingListsKey = "ShoppingLists"
    private let macroGoalsKey = "MacroGoals"
    
    var isMigrationCompleted: Bool {
        userDefaults.bool(forKey: migrationCompletedKey)
    }
    
    func performMigration() async {
        guard !isMigrationCompleted else {
            print("Migration already completed")
            return
        }
        
        isMigrating = true
        migrationError = nil
        migrationCompleted = false
        
        do {
            // Step 1: Migrate Macro Goals
            migrationProgress = "Migrating macro goals..."
            try await migrateMacroGoals()
            
            // Step 2: Migrate Meal Plans
            migrationProgress = "Migrating meal plans..."
            try await migrateMealPlans()
            
            // Step 3: Migrate Shopping Lists
            migrationProgress = "Migrating shopping lists..."
            try await migrateShoppingLists()
            
            // Step 4: Mark migration as completed
            migrationProgress = "Finalizing migration..."
            userDefaults.set(true, forKey: migrationCompletedKey)
            
            migrationProgress = "Migration completed successfully!"
            migrationCompleted = true
            
        } catch {
            migrationError = error
            migrationProgress = "Migration failed: \(error.localizedDescription)"
        }
        
        isMigrating = false
    }
    
    private func migrateMacroGoals() async throws {
        // Check if there are existing macro goals in UserDefaults
        guard let goalsData = userDefaults.dictionary(forKey: macroGoalsKey) as? [String: Double] else {
            print("No macro goals to migrate")
            return
        }
        
        let goals = MacroGoals(
            calories: goalsData["calories"] ?? MacroGoals.default.calories,
            protein: goalsData["protein"] ?? MacroGoals.default.protein,
            carbs: goalsData["carbs"] ?? MacroGoals.default.carbs,
            fat: goalsData["fat"] ?? MacroGoals.default.fat
        )
        
        try await supabaseService.saveMacroGoals(goals)
        print("Migrated macro goals: \(goals)")
    }
    
    private func migrateMealPlans() async throws {
        // Check if there are existing meal plans in UserDefaults
        guard let data = userDefaults.data(forKey: mealPlansKey),
              let mealPlans = try? JSONDecoder().decode([MealPlan].self, from: data),
              !mealPlans.isEmpty else {
            print("No meal plans to migrate")
            return
        }
        
        for mealPlan in mealPlans {
            try await supabaseService.saveMealPlan(mealPlan)
            print("Migrated meal plan: \(mealPlan.id)")
        }
        
        print("Migrated \(mealPlans.count) meal plans")
    }
    
    private func migrateShoppingLists() async throws {
        // Check if there are existing shopping lists in UserDefaults
        guard let data = userDefaults.data(forKey: shoppingListsKey),
              let shoppingLists = try? JSONDecoder().decode([ShoppingList].self, from: data),
              !shoppingLists.isEmpty else {
            print("No shopping lists to migrate")
            return
        }
        
        for shoppingList in shoppingLists {
            try await supabaseService.saveShoppingList(shoppingList)
            print("Migrated shopping list: \(shoppingList.id)")
        }
        
        print("Migrated \(shoppingLists.count) shopping lists")
    }
    
    // Helper method to clear UserDefaults data after successful migration
    func clearOldUserDefaultsData() {
        guard isMigrationCompleted else {
            print("Cannot clear data - migration not completed")
            return
        }
        
        userDefaults.removeObject(forKey: mealPlansKey)
        userDefaults.removeObject(forKey: shoppingListsKey)
        userDefaults.removeObject(forKey: macroGoalsKey)
        
        print("Cleared old UserDefaults data")
    }
    
    // For testing - reset migration state
    func resetMigrationState() {
        userDefaults.removeObject(forKey: migrationCompletedKey)
        migrationCompleted = false
        print("Reset migration state")
    }
}