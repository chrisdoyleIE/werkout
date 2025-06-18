import SwiftUI

struct IntegratedShoppingListView: View {
    let mealPlan: MealPlan
    @Environment(\.dismiss) private var dismiss
    @StateObject private var settingsManager = SettingsManager()
    @State private var checkedItems: Set<String> = []
    
    private let storeCategories: [String: [String]] = [
        "Produce": ["vegetables", "fruits", "herbs", "leafy", "onion", "garlic", "tomato", "tomatoes", "potato", "potatoes", "carrot", "carrots", "bell pepper", "bell peppers", "peppers", "pepper", "cucumber", "lettuce", "spinach", "broccoli", "cauliflower", "zucchini", "mushroom", "mushrooms", "avocado", "lemon", "lemons", "lime", "limes", "apple", "apples", "banana", "bananas", "berries", "cilantro", "parsley", "basil", "thyme", "rosemary", "ginger", "celery"],
        "Meat & Seafood": ["chicken", "beef", "pork", "fish", "salmon", "tuna", "shrimp", "turkey", "lamb", "bacon", "sausage", "ground", "cod", "halibut", "tilapia", "mahi", "sea bass", "trout", "sardines", "anchovies", "crab", "lobster", "scallops", "mussels", "clams", "chicken breast", "chicken thighs", "ground beef", "ground turkey", "pork chops", "lamb chops", "filet", "steak"],
        "Dairy & Eggs": ["milk", "cheese", "yogurt", "butter", "cream", "eggs", "sour cream", "cottage cheese", "mozzarella", "cheddar", "parmesan", "feta", "goat cheese", "ricotta", "heavy cream", "half and half", "greek yogurt"],
        "Pantry": ["rice", "pasta", "bread", "flour", "sugar", "salt", "pepper", "oil", "vinegar", "spices", "canned", "dried", "beans", "lentils", "quinoa", "oats", "nuts", "seeds", "honey", "maple syrup", "vanilla", "baking powder", "baking soda", "olive oil", "coconut oil", "soy sauce", "hot sauce", "mustard", "ketchup", "mayo", "mayonnaise"],
        "Frozen": ["frozen", "ice cream", "frozen vegetables", "frozen fruit", "frozen berries", "frozen peas", "frozen corn"],
        "Other": []
    ]
    
    var categorizedItems: [String: [String]] {
        guard let shoppingList = mealPlan.generatedMealPlan?.shoppingList else {
            return [:]
        }
        
        var categorized: [String: [String]] = [:]
        
        for category in storeCategories.keys {
            categorized[category] = []
        }
        
        for item in shoppingList {
            let lowercaseItem = item.lowercased()
            var categorized_item = false
            
            for (category, keywords) in storeCategories {
                if keywords.contains(where: { lowercaseItem.contains($0) }) {
                    categorized[category]?.append(item)
                    categorized_item = true
                    break
                }
            }
            
            if !categorized_item {
                categorized["Other"]?.append(item)
            }
        }
        
        // Remove empty categories
        return categorized.filter { !$0.value.isEmpty }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header info
                    VStack(alignment: .leading, spacing: 8) {
                        Text(mealPlan.generatedMealPlan?.title ?? "Shopping List")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("\(mealPlan.dateRange) • \(totalItemsCount) items")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        if checkedItems.count > 0 {
                            Text("\(checkedItems.count) of \(totalItemsCount) items checked")
                                .font(.caption)
                                .foregroundColor(.green)
                                .fontWeight(.medium)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Categorized shopping list
                    ForEach(Array(categorizedItems.keys.sorted()), id: \.self) { category in
                        if let items = categorizedItems[category], !items.isEmpty {
                            categorySection(category: category, items: items)
                        }
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding(.vertical)
            }
            .navigationTitle("Shopping List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            checkedItems.removeAll()
                        }) {
                            Label("Uncheck All", systemImage: "square")
                        }
                        
                        Button(action: {
                            if let shoppingList = mealPlan.generatedMealPlan?.shoppingList {
                                checkedItems = Set(shoppingList)
                            }
                        }) {
                            Label("Check All", systemImage: "checkmark.square")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
    }
    
    private var totalItemsCount: Int {
        mealPlan.generatedMealPlan?.shoppingList?.count ?? 0
    }
    
    private func categorySection(category: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(category, systemImage: categoryIcon(for: category))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(categoryColor(for: category))
                
                Spacer()
                
                Text("\(items.count)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(categoryColor(for: category))
                    .cornerRadius(8)
            }
            
            VStack(spacing: 8) {
                ForEach(items, id: \.self) { item in
                    shoppingListItem(item)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private func shoppingListItem(_ item: String) -> some View {
        Button(action: {
            if checkedItems.contains(item) {
                checkedItems.remove(item)
            } else {
                checkedItems.insert(item)
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: checkedItems.contains(item) ? "checkmark.square.fill" : "square")
                    .font(.title3)
                    .foregroundColor(checkedItems.contains(item) ? .green : .gray)
                
                Text(item)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .strikethrough(checkedItems.contains(item))
                    .opacity(checkedItems.contains(item) ? 0.6 : 1.0)
                
                Spacer()
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func categoryIcon(for category: String) -> String {
        switch category {
        case "Produce": return "leaf"
        case "Meat & Seafood": return "fish"
        case "Dairy & Eggs": return "drop"
        case "Pantry": return "archivebox"
        case "Frozen": return "snowflake"
        default: return "bag"
        }
    }
    
    private func categoryColor(for category: String) -> Color {
        switch category {
        case "Produce": return .green
        case "Meat & Seafood": return .red
        case "Dairy & Eggs": return .blue
        case "Pantry": return .orange
        case "Frozen": return .cyan
        default: return .gray
        }
    }
}

#Preview {
    IntegratedShoppingListView(mealPlan: MealPlan(
        startDate: Date(),
        numberOfDays: 4,
        userPreferences: "Sample preferences",
        generatedMealPlan: GeneratedMealPlan(
            title: "4-Day Balanced Meal Plan",
            description: "Healthy and delicious meals",
            totalDays: 4,
            dailyMeals: [],
            shoppingList: [
                "2 lbs chicken breast",
                "1 lb ground beef",
                "12 eggs",
                "1 gallon milk",
                "2 cups broccoli",
                "3 bell peppers",
                "2 lbs rice",
                "1 loaf bread",
                "2 tbsp olive oil",
                "Salt and pepper",
                "1 lb frozen vegetables",
                "2 cups cheddar cheese"
            ],
            categorizedShoppingList: nil,
            mealPrepInstructions: nil,
            totalNutrition: nil
        ),
        createdAt: Date()
    ))
}