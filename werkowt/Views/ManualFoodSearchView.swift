import SwiftUI

struct ManualFoodSearchView: View {
    @StateObject private var supabaseService = SupabaseService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedMealType: MealType = ManualFoodSearchView.mealTypeForCurrentTime()
    @State private var searchText = ""
    @State private var recentItems: [RecentFoodItem] = []
    @State private var searchResults: [FoodItem] = []
    @State private var isSearching = false
    @State private var selectedFood: FoodItem?
    @State private var selectedMeal: RecentFoodItem?
    @State private var showingQuantityInput = false
    @State private var showingMealDetail = false
    @State private var showingFoodCreator = false
    @State private var showingMealCreator = false
    @State private var isLoading = false
    
    private let searchDebouncer = Debouncer()
    
    private static func mealTypeForCurrentTime() -> MealType {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5...10:
            return .breakfast
        case 11...15:
            return .lunch
        case 16...21:
            return .dinner
        default:
            return .snack
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search foods or meals...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .onChange(of: searchText) { newValue in
                            searchDebouncer.debounce {
                                Task {
                                    await performSearch(query: newValue)
                                }
                            }
                        }
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            searchResults = []
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding()
                
                // Meal type picker
                VStack(spacing: 12) {
                    HStack {
                        Text("Add to:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    
                    // 2x2 Grid for better spacing
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 8),
                        GridItem(.flexible(), spacing: 8)
                    ], spacing: 8) {
                        ForEach(MealType.allCases, id: \.self) { mealType in
                            Button(action: {
                                selectedMealType = mealType
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: mealType.icon)
                                        .font(.system(size: 14))
                                    Text(mealType.displayName)
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(selectedMealType == mealType ? Color.primary : Color(.systemGray5))
                                .foregroundColor(selectedMealType == mealType ? .white : .primary)
                                .cornerRadius(12)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Section 1: Recent Foods and Meals
                        if !recentItems.isEmpty {
                            FoodSearchSection(
                                title: searchText.isEmpty ? "Recent" : "Your Foods & Meals",
                                items: {
                                    ForEach(filteredRecentItems) { item in
                                        RecentItemRow(item: item) {
                                            if item.isMeal {
                                                selectedMeal = item
                                                showingMealDetail = true
                                            } else {
                                                // Convert to FoodItem for quantity input
                                                selectedFood = FoodItem(
                                                    id: item.itemId,
                                                    name: item.name,
                                                    brand: item.brand,
                                                    caloriesPer100g: (item.caloriesPerServing / (item.avgQuantity ?? 100)) * 100,
                                                    proteinPer100g: (item.proteinPerServing / (item.avgQuantity ?? 100)) * 100,
                                                    carbsPer100g: 0, // Would need to fetch full details
                                                    fatPer100g: 0    // Would need to fetch full details
                                                )
                                                showingQuantityInput = true
                                            }
                                        }
                                    }
                                }
                            )
                        }
                        
                        // Section 2: Database Search Results
                        if !searchText.isEmpty && !searchResults.isEmpty {
                            FoodSearchSection(
                                title: "From Database",
                                items: {
                                    ForEach(searchResults) { food in
                                        DatabaseFoodRow(food: food) {
                                            selectedFood = food
                                            showingQuantityInput = true
                                        }
                                    }
                                }
                            )
                        }
                        
                        // Section 3: Create New Options
                        if !searchText.isEmpty {
                            FoodSearchSection(
                                title: "Can't find it?",
                                items: {
                                    VStack(spacing: 8) {
                                        CreateFoodRow(foodName: searchText) {
                                            Logger.debug("ManualFoodSearch: Create New Food tapped for: '\(searchText)'", category: Logger.food)
                                            Logger.debug("ManualFoodSearch: Presenting FoodCreatorView with searchText: '\(searchText)'", category: Logger.food)
                                            showingFoodCreator = true
                                        }
                                        
                                        CreateMealRow {
                                            Logger.debug("ManualFoodSearch: Create Meal tapped", category: Logger.food)
                                            showingMealCreator = true
                                        }
                                    }
                                }
                            )
                        }
                        
                        // Empty state
                        if searchText.isEmpty && recentItems.isEmpty {
                            EmptyStateView()
                                .padding(.top, 80)
                        }
                        
                        // No results state
                        if !searchText.isEmpty && searchResults.isEmpty && !isSearching {
                            NoResultsView(query: searchText)
                                .padding(.top, 80)
                        }
                    }
                    .padding(.bottom, 20)
                }
                
                if isSearching {
                    ProgressView()
                        .padding()
                }
            }
            .navigationTitle("Add Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .task {
                await loadRecentItems()
            }
        }
        .sheet(isPresented: $showingQuantityInput) {
            if let food = selectedFood {
                QuantityInputView(
                    food: food,
                    mealType: selectedMealType,
                    onSave: { quantity in
                        Task {
                            await logFood(food: food, quantity: quantity)
                        }
                    }
                )
            }
        }
        .sheet(isPresented: $showingMealDetail) {
            if let meal = selectedMeal {
                FoodTrackingMealDetailView(
                    meal: meal,
                    mealType: selectedMealType,
                    onLog: { scaleFactor in
                        Task {
                            await logMeal(meal: meal, scaleFactor: scaleFactor)
                        }
                    }
                )
            }
        }
        .sheet(isPresented: $showingFoodCreator) {
            FoodCreatorView(
                initialFoodName: searchText.isEmpty ? nil : searchText,
                onFoodSaved: { finalFoodName in
                    Logger.debug("ManualFoodSearch: Food saved with name: '\(finalFoodName)'", category: Logger.food)
                    // Update search text with the final food name
                    searchText = finalFoodName
                    // Refresh search results to show the newly created food
                    Task {
                        await performSearch(query: finalFoodName)
                    }
                }
            )
        }
        .sheet(isPresented: $showingMealCreator) {
            MealCreatorView(
                onMealSaved: { finalMealName in
                    // Update search text with the final meal name
                    searchText = finalMealName
                    // Refresh search results to show the newly created meal
                    Task {
                        await loadRecentItems()
                    }
                }
            )
        }
        .overlay(
            Group {
                if isLoading {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    ProgressView("Saving...")
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(10)
                }
            }
        )
    }
    
    private var filteredRecentItems: [RecentFoodItem] {
        if searchText.isEmpty {
            return recentItems
        }
        
        let query = searchText.lowercased()
        return recentItems.filter { item in
            item.name.lowercased().contains(query) ||
            (item.brand?.lowercased().contains(query) ?? false)
        }
    }
    
    private func loadRecentItems() async {
        Logger.debug("ManualFoodSearch: loadRecentItems started", category: Logger.food)
        do {
            let items = try await supabaseService.getRecentFoodsAndMeals(
                days: 7,
                mealType: nil
            )
            Logger.debug("ManualFoodSearch: Loaded \(items.count) recent items", category: Logger.food)
            await MainActor.run {
                recentItems = items
            }
        } catch {
            Logger.error("ManualFoodSearch: Error loading recent items: \(error.localizedDescription)", category: Logger.food)
        }
    }
    
    private func performSearch(query: String) async {
        Logger.debug("ManualFoodSearch: performSearch called with query: '\(query)'", category: Logger.food)
        
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            Logger.debug("ManualFoodSearch: Empty query, clearing results", category: Logger.food)
            await MainActor.run {
                searchResults = []
                isSearching = false
            }
            return
        }
        
        await MainActor.run {
            isSearching = true
        }
        
        do {
            let results = try await supabaseService.searchFoods(query: query, limit: 20)
            Logger.debug("ManualFoodSearch: Found \(results.count) search results for query: '\(query)'", category: Logger.food)
            await MainActor.run {
                searchResults = results
                isSearching = false
            }
        } catch {
            Logger.error("ManualFoodSearch: Search error for query '\(query)': \(error.localizedDescription)", category: Logger.food)
            await MainActor.run {
                searchResults = []
                isSearching = false
            }
        }
    }
    
    private func logFood(food: FoodItem, quantity: Double) async {
        await MainActor.run {
            isLoading = true
        }
        
        do {
            let userId = try supabaseService.ensureAuthenticated()
            let nutrition = food.calculateNutrition(for: quantity)
            
            let entry = FoodEntry(
                userId: userId,
                foodItemId: food.id,
                mealType: selectedMealType,
                quantityGrams: quantity,
                calories: nutrition.calories,
                proteinG: nutrition.protein,
                carbsG: nutrition.carbs,
                fatG: nutrition.fat,
                source: .manual,
                foodItem: food
            )
            
            try await supabaseService.logFoodEntry(entry)
            
            await MainActor.run {
                isLoading = false
                dismiss()
            }
        } catch {
            await MainActor.run {
                isLoading = false
            }
            print("Error logging food: \(error)")
        }
    }
    
    private func logMeal(meal: RecentFoodItem, scaleFactor: Double) async {
        await MainActor.run {
            isLoading = true
        }
        
        do {
            // Use the new meal template logging function
            try await supabaseService.logMealFromTemplate(
                mealGroupId: meal.itemId,
                mealType: selectedMealType,
                scaleFactor: scaleFactor
            )
            
            await MainActor.run {
                isLoading = false
                dismiss()
            }
        } catch {
            await MainActor.run {
                isLoading = false
            }
            print("Error logging meal: \(error)")
        }
    }
}

// MARK: - Section Components

struct FoodSearchSection<Content: View>: View {
    let title: String
    @ViewBuilder let items: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.horizontal)
            
            VStack(spacing: 8) {
                items()
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Row Components

struct RecentItemRow: View {
    let item: RecentFoodItem
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: item.isMeal ? "square.stack.3d.up.fill" : "circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.primary.opacity(0.7))
                    .frame(width: 32)
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(item.subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Time since last used
                Text(item.lastUsed.relativeTime)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray5), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct DatabaseFoodRow: View {
    let food: FoodItem
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Verified badge or generic icon
                if food.isVerified {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.primary.opacity(0.8))
                        .frame(width: 32)
                } else {
                    Image(systemName: "circle")
                        .font(.system(size: 20))
                        .foregroundColor(.primary.opacity(0.5))
                        .frame(width: 32)
                }
                
                // Food info
                VStack(alignment: .leading, spacing: 4) {
                    Text(food.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text("Per 100g: \(Int(food.caloriesPer100g)) cal • P: \(Int(food.proteinPer100g))g")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CreateFoodRow: View {
    let foodName: String
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: "rectangle.badge.plus")
                    .font(.system(size: 20))
                    .foregroundColor(.primary)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Create new food")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text("\"\(foodName)\"")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.primary.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CreateMealRow: View {
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: "rectangle.stack.badge.plus")
                    .font(.system(size: 20))
                    .foregroundColor(.primary)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Create new meal")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text("Combine multiple foods")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.primary.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Empty States

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.5))
            
            Text("Search for foods or meals")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Start typing to find foods from your history\nor search our database")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}

struct NoResultsView: View {
    let query: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "questionmark.circle")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.5))
            
            Text("No results for \"\(query)\"")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Try a different search or create a new food")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Meal Detail View (using standalone MealDetailView)

// MARK: - Keep existing components

struct QuantityInputView: View {
    let food: FoodItem
    let mealType: MealType
    let onSave: (Double) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedServingSize: MasterServingSize?
    @State private var customAmount: String = ""
    @State private var showingCustomInput = false
    @FocusState private var isTextFieldFocused: Bool
    
    private var foodType: FoodType {
        return FoodType.classify(foodName: food.name)
    }
    
    private var availableServingSizes: [MasterServingSize] {
        var servings: [MasterServingSize] = []
        
        // 1. Add Claude's prediction if available (highest priority)
        if let claudeServing = food.servingSizeName,
           let masterSize = MasterServingSize(rawValue: claudeServing) {
            servings.append(masterSize)
        }
        
        // 2. Add contextually appropriate serving sizes for this food type
        let preferMetric = true // TODO: Could be based on user preference or nutrition label units
        let contextualSuggestions = MasterServingSize.contextualSuggestions(for: foodType, preferMetric: preferMetric)
        
        // Only add contextual suggestions that aren't already in the list (avoid duplicates)
        for suggestion in contextualSuggestions {
            if !servings.contains(suggestion) {
                servings.append(suggestion)
            }
        }
        
        // Limit to top 6 options to keep UI clean
        return Array(servings.prefix(6))
    }
    
    private var quantityInGrams: Double {
        if showingCustomInput {
            guard let value = Double(customAmount) else { return 0 }
            return value
        } else {
            return selectedServingSize?.gramsEquivalent ?? 0
        }
    }
    
    private var calculatedNutrition: NutritionInfo {
        return food.calculateNutrition(for: quantityInGrams)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Food info
                VStack(spacing: 12) {
                    Text(food.displayName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text("for \(mealType.displayName)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Quantity input
                VStack(spacing: 16) {
                    Text("How much did you eat?")
                        .font(.headline)
                    
                    if showingCustomInput {
                        // Custom gram input
                        VStack(spacing: 12) {
                            HStack {
                                TextField("Amount in grams", text: $customAmount)
                                    .keyboardType(.decimalPad)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .focused($isTextFieldFocused)
                                Text("g")
                                    .foregroundColor(.secondary)
                            }
                            
                            Button("Choose from serving sizes") {
                                showingCustomInput = false
                                selectedServingSize = availableServingSizes.first
                            }
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        }
                    } else {
                        // Serving size selection
                        VStack(spacing: 12) {
                            Menu {
                                ForEach(availableServingSizes, id: \.self) { serving in
                                    Button(action: {
                                        selectedServingSize = serving
                                    }) {
                                        HStack {
                                            Text(serving.displayName)
                                            if serving.rawValue == food.servingSizeName {
                                                Text("✨")
                                                    .font(.caption)
                                            }
                                            Spacer()
                                            Text("\(String(format: "%.0f", serving.gramsEquivalent))g")
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                                
                                Divider()
                                
                                Button("Custom amount...") {
                                    showingCustomInput = true
                                }
                            } label: {
                                HStack {
                                    if let serving = selectedServingSize {
                                        Text(serving.displayName)
                                            .foregroundColor(.primary)
                                        if serving.rawValue == food.servingSizeName {
                                            Text("✨")
                                                .font(.caption)
                                        }
                                    } else {
                                        Text("Select serving size")
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.up.chevron.down")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            }
                            
                            // Show Claude's suggestion indicator and weight
                            if let serving = selectedServingSize {
                                HStack {
                                    if serving.rawValue == food.servingSizeName {
                                        HStack(spacing: 4) {
                                            Image(systemName: "wand.and.stars")
                                                .font(.system(size: 12))
                                                .foregroundColor(.primary)
                                            Text("Claude's suggestion")
                                                .font(.caption)
                                                .fontWeight(.medium)
                                                .foregroundColor(.primary)
                                        }
                                    }
                                    Spacer()
                                    Text("= \(String(format: "%.0f", serving.gramsEquivalent))g")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
                
                // Nutrition preview
                if quantityInGrams > 0 {
                    VStack(spacing: 12) {
                        Text("Nutrition Information")
                            .font(.headline)
                        
                        VStack(spacing: 8) {
                            NutritionRowView(
                                title: "Calories",
                                value: String(format: "%.0f", calculatedNutrition.calories),
                                color: .primary
                            )
                            
                            NutritionRowView(
                                title: "Protein",
                                value: String(format: "%.1f", calculatedNutrition.protein),
                                unit: "g",
                                color: .primary.opacity(0.8)
                            )
                            
                            NutritionRowView(
                                title: "Carbs",
                                value: String(format: "%.1f", calculatedNutrition.carbs),
                                unit: "g",
                                color: .primary.opacity(0.6)
                            )
                            
                            NutritionRowView(
                                title: "Fat",
                                value: String(format: "%.1f", calculatedNutrition.fat),
                                unit: "g",
                                color: .primary.opacity(0.4)
                            )
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }
                
                Spacer()
                
                // Save button
                Button(action: {
                    onSave(quantityInGrams)
                    dismiss()
                }) {
                    Text("Add to \(mealType.displayName)")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(quantityInGrams > 0 ? Color.primary : Color.gray)
                        .cornerRadius(12)
                }
                .disabled(quantityInGrams <= 0)
            }
            .padding()
            .navigationTitle("Add Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                // Default to first available serving size (Claude's prediction if available)
                selectedServingSize = availableServingSizes.first
            }
        }
    }
}

struct NutritionRowView: View {
    let title: String
    let value: String
    var unit: String = ""
    let color: Color
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
            
            HStack(alignment: .bottom, spacing: 2) {
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
                
                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

// MARK: - Helper Extensions

extension Date {
    var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}



#Preview {
    ManualFoodSearchView()
}