import SwiftUI

struct IntegratedShoppingListView: View {
    let mealPlan: MealPlan
    @Environment(\.dismiss) private var dismiss
    @StateObject private var settingsManager = SettingsManager()
    @State private var checkedItems: Set<String> = []
    
    var categorizedItems: [String: [ShoppingListItemDetail]] {
        guard let shoppingList = mealPlan.generatedMealPlan?.shoppingList else {
            return [:]
        }
        
        // Use the categories that Claude already assigned
        let groupedItems = Dictionary(grouping: shoppingList) { $0.category }
        
        // Convert to string keys for compatibility with existing UI
        var categorized: [String: [ShoppingListItemDetail]] = [:]
        for (category, items) in groupedItems {
            categorized[category.displayName] = items
        }
        
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
                                checkedItems = Set(shoppingList.map { $0.name })
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
    
    private func categorySection(category: String, items: [ShoppingListItemDetail]) -> some View {
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
                ForEach(items, id: \.name) { item in
                    shoppingListItem(item)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private func shoppingListItem(_ item: ShoppingListItemDetail) -> some View {
        Button(action: {
            if checkedItems.contains(item.name) {
                checkedItems.remove(item.name)
            } else {
                checkedItems.insert(item.name)
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: checkedItems.contains(item.name) ? "checkmark.square.fill" : "square")
                    .font(.title3)
                    .foregroundColor(checkedItems.contains(item.name) ? .green : .gray)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .strikethrough(checkedItems.contains(item.name))
                        .opacity(checkedItems.contains(item.name) ? 0.6 : 1.0)
                    
                    if !item.amount.isEmpty {
                        Text(item.amount)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .strikethrough(checkedItems.contains(item.name))
                            .opacity(checkedItems.contains(item.name) ? 0.6 : 1.0)
                    }
                }
                
                Spacer()
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func categoryIcon(for category: String) -> String {
        switch category {
        case "Dairy": return "drop.fill"
        case "Meat & Fish": return "fish.fill"
        case "Fruit & Veg": return "leaf.fill"
        case "Store Cupboard": return "archivebox.fill"
        case "Frozen": return "snowflake"
        case "Breads & Grains": return "takeoutbag.and.cup.and.straw.fill"
        case "Other": return "bag.fill"
        default: return "bag.fill"
        }
    }
    
    private func categoryColor(for category: String) -> Color {
        switch category {
        case "Dairy": return .blue
        case "Meat & Fish": return .red
        case "Fruit & Veg": return .green
        case "Store Cupboard": return .orange
        case "Frozen": return .cyan
        case "Breads & Grains": return .brown
        case "Other": return .gray
        default: return .gray
        }
    }
}
