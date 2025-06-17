import SwiftUI

struct ShoppingDashboardView: View {
    @EnvironmentObject var shoppingListManager: ShoppingListManager
    @EnvironmentObject var mealPlanManager: MealPlanManager
    
    @State private var selectedShoppingList: ShoppingList?
    @State private var showingShoppingListDetail = false
    
    var activeShoppingLists: [ShoppingList] {
        shoppingListManager.shoppingLists.filter { list in
            // Show lists for active meal plans or lists with remaining items
            if let mealPlan = mealPlanManager.mealPlans.first(where: { $0.id == list.mealPlanId }) {
                let now = Date()
                return (mealPlan.startDate <= now && mealPlan.endDate >= now) || !list.remainingItems.isEmpty
            }
            return !list.remainingItems.isEmpty
        }
    }
    
    var completedShoppingLists: [ShoppingList] {
        shoppingListManager.shoppingLists.filter { list in
            list.remainingItems.isEmpty && !activeShoppingLists.contains(where: { $0.id == list.id })
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Overview Section
                overviewSection
                
                // Active Shopping Lists
                if !activeShoppingLists.isEmpty {
                    activeListsSection
                } else {
                    emptyStateSection
                }
                
                // Completed Lists (collapsible)
                if !completedShoppingLists.isEmpty {
                    completedListsSection
                }
                
                Spacer(minLength: 100)
            }
            .padding()
        }
        .sheet(isPresented: $showingShoppingListDetail) {
            if let selectedList = selectedShoppingList {
                ShoppingListDetailView(shoppingList: selectedList)
                    .environmentObject(shoppingListManager)
                    .environmentObject(mealPlanManager)
            }
        }
    }
    
    private var overviewSection: some View {
        VStack(spacing: 16) {
            HStack {
                Label("Shopping Overview", systemImage: "cart.fill")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            HStack(spacing: 16) {
                overviewCard(
                    title: "Active Lists",
                    value: "\(activeShoppingLists.count)",
                    icon: "cart",
                    color: .blue
                )
                
                overviewCard(
                    title: "Total Items",
                    value: "\(activeShoppingLists.reduce(0) { $0 + $1.items.count })",
                    icon: "list.bullet",
                    color: .orange
                )
                
                overviewCard(
                    title: "Completed",
                    value: "\(activeShoppingLists.reduce(0) { $0 + $1.completedItems.count })",
                    icon: "checkmark.circle",
                    color: .green
                )
            }
        }
    }
    
    private func overviewCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var activeListsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Active Shopping Lists", systemImage: "cart.badge.plus")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(activeShoppingLists.count)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            LazyVStack(spacing: 12) {
                ForEach(activeShoppingLists, id: \.id) { shoppingList in
                    shoppingListCard(shoppingList)
                }
            }
        }
    }
    
    private var emptyStateSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "cart")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Active Shopping Lists")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            Text("Create a meal plan to generate shopping lists automatically")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Create Meal Plan") {
                // Navigate to meal planning
            }
            .font(.subheadline)
            .foregroundColor(.blue)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
        }
        .padding(40)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var completedListsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Recently Completed", systemImage: "checkmark.circle.fill")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(completedShoppingLists.count)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            LazyVStack(spacing: 12) {
                ForEach(completedShoppingLists.prefix(3), id: \.id) { shoppingList in
                    completedShoppingListCard(shoppingList)
                }
            }
        }
    }
    
    private func shoppingListCard(_ shoppingList: ShoppingList) -> some View {
        Button(action: {
            selectedShoppingList = shoppingList
            showingShoppingListDetail = true
        }) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(shoppingList.mealPlanTitle)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .lineLimit(1)
                        
                        Text(shoppingList.completionText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Progress circle
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 3)
                            .frame(width: 32, height: 32)
                        
                        Circle()
                            .trim(from: 0, to: shoppingList.completionPercentage)
                            .stroke(Color.blue, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            .frame(width: 32, height: 32)
                            .rotationEffect(.degrees(-90))
                        
                        Text("\(Int(shoppingList.completionPercentage * 100))%")
                            .font(.caption2)
                            .fontWeight(.bold)
                    }
                }
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 6)
                            .cornerRadius(3)
                        
                        Rectangle()
                            .fill(Color.blue)
                            .frame(width: geometry.size.width * shoppingList.completionPercentage, height: 6)
                            .cornerRadius(3)
                    }
                }
                .frame(height: 6)
                
                // Quick preview of items
                HStack {
                    if !shoppingList.remainingItems.isEmpty {
                        Text("Next: \(shoppingList.remainingItems.prefix(2).map { $0.name }.joined(separator: ", "))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    } else {
                        Text("All items completed! 🎉")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        shoppingListManager.resetShoppingList(shoppingList)
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(16)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
        .contextMenu {
            Button("Open Shopping List") {
                selectedShoppingList = shoppingList
                showingShoppingListDetail = true
            }
            
            Button("Reset List") {
                shoppingListManager.resetShoppingList(shoppingList)
            }
            
            Button("Delete List", role: .destructive) {
                shoppingListManager.deleteShoppingList(shoppingList)
            }
        }
    }
    
    private func completedShoppingListCard(_ shoppingList: ShoppingList) -> some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(shoppingList.mealPlanTitle)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("Completed")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button("Reset") {
                shoppingListManager.resetShoppingList(shoppingList)
            }
            .font(.caption)
            .foregroundColor(.blue)
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Shopping List Detail View
struct ShoppingListDetailView: View {
    let shoppingList: ShoppingList
    @EnvironmentObject var shoppingListManager: ShoppingListManager
    @EnvironmentObject var mealPlanManager: MealPlanManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Progress Header
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(shoppingList.mealPlanTitle)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text(shoppingList.completionText)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // Large progress circle
                        ZStack {
                            Circle()
                                .stroke(Color.gray.opacity(0.2), lineWidth: 6)
                                .frame(width: 60, height: 60)
                            
                            Circle()
                                .trim(from: 0, to: shoppingList.completionPercentage)
                                .stroke(Color.blue, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                                .frame(width: 60, height: 60)
                                .rotationEffect(.degrees(-90))
                            
                            Text("\(Int(shoppingList.completionPercentage * 100))%")
                                .font(.headline)
                                .fontWeight(.bold)
                        }
                    }
                    
                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 8)
                                .cornerRadius(4)
                            
                            Rectangle()
                                .fill(Color.blue)
                                .frame(width: geometry.size.width * shoppingList.completionPercentage, height: 8)
                                .cornerRadius(4)
                        }
                    }
                    .frame(height: 8)
                }
                .padding()
                .background(Color(.systemGray6))
                
                // Shopping Items
                List {
                    ForEach(Array(shoppingList.categorizedItems.keys.sorted()), id: \.self) { category in
                        Section(category) {
                            ForEach(shoppingList.categorizedItems[category] ?? [], id: \.id) { item in
                                shoppingItemRow(item)
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())
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
                    Button("Reset") {
                        shoppingListManager.resetShoppingList(shoppingList)
                    }
                }
            }
        }
    }
    
    private func shoppingItemRow(_ item: ShoppingListItem) -> some View {
        HStack {
            Button(action: {
                shoppingListManager.toggleItemCompletion(item)
            }) {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(item.isCompleted ? .green : .gray)
                    .font(.title3)
            }
            .buttonStyle(PlainButtonStyle())
            
            Text(item.name)
                .strikethrough(item.isCompleted)
                .foregroundColor(item.isCompleted ? .secondary : .primary)
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ShoppingDashboardView()
        .environmentObject(ShoppingListManager())
        .environmentObject(MealPlanManager())
}