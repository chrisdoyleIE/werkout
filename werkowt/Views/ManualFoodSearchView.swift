import SwiftUI

struct ManualFoodSearchView: View {
    let selectedMealType: MealType
    
    @StateObject private var supabaseService = SupabaseService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText = ""
    @State private var searchResults: [FoodItem] = []
    @State private var isSearching = false
    @State private var selectedFood: FoodItem?
    @State private var showingQuantityInput = false
    @State private var quantity: String = ""
    @State private var isLoading = false
    
    private let searchDebouncer = Debouncer()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        
                        TextField("Search for food...", text: $searchText)
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
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    
                    if isSearching {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
                .padding()
                
                // Recent foods section (when no search)
                if searchText.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Foods")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .padding(.horizontal)
                        
                        if supabaseService.recentFoods.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "clock")
                                    .font(.system(size: 32))
                                    .foregroundColor(.secondary)
                                
                                Text("No recent foods")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 32)
                        } else {
                            ScrollView {
                                LazyVStack(spacing: 8) {
                                    ForEach(supabaseService.recentFoods) { food in
                                        FoodItemRowView(food: food) {
                                            selectedFood = food
                                            showingQuantityInput = true
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                } else {
                    // Search results
                    if searchResults.isEmpty && !isSearching && !searchText.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 32))
                                .foregroundColor(.secondary)
                            
                            Text("No results found")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text("Try a different search term")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 8) {
                                ForEach(searchResults) { food in
                                    FoodItemRowView(food: food) {
                                        selectedFood = food
                                        showingQuantityInput = true
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                
                Spacer()
            }
            .navigationTitle("Manual Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
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
    
    private func performSearch(query: String) async {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
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
            await MainActor.run {
                searchResults = results
                isSearching = false
            }
        } catch {
            await MainActor.run {
                searchResults = []
                isSearching = false
            }
            print("Search error: \(error)")
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
}

struct FoodItemRowView: View {
    let food: FoodItem
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Food icon
                Image(systemName: "fork.knife.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.blue)
                
                // Food info
                VStack(alignment: .leading, spacing: 4) {
                    Text(food.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Text("Per 100g: \(String(format: "%.0f", food.caloriesPer100g)) cal")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Nutrition summary
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 8) {
                        NutritionBadge(
                            value: String(format: "%.1f", food.proteinPer100g),
                            unit: "P",
                            color: .green
                        )
                        
                        NutritionBadge(
                            value: String(format: "%.1f", food.carbsPer100g),
                            unit: "C",
                            color: .orange
                        )
                        
                        NutritionBadge(
                            value: String(format: "%.1f", food.fatPer100g),
                            unit: "F",
                            color: .purple
                        )
                    }
                    
                    if food.isVerified {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                            
                            Text("Verified")
                                .font(.caption2)
                                .foregroundColor(.green)
                        }
                    }
                }
                
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
                    .stroke(Color(.systemGray4), lineWidth: 0.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct NutritionBadge: View {
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 1) {
            Text(value)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(color)
            
            Text(unit)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(minWidth: 20)
    }
}

struct QuantityInputView: View {
    let food: FoodItem
    let mealType: MealType
    let onSave: (Double) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var quantity: String = ""
    @State private var selectedUnit: WeightUnit = .grams
    @FocusState private var isTextFieldFocused: Bool
    
    enum WeightUnit: String, CaseIterable {
        case grams = "g"
        case ounces = "oz"
        case pounds = "lbs"
        
        var conversionToGrams: Double {
            switch self {
            case .grams:
                return 1.0
            case .ounces:
                return 28.3495
            case .pounds:
                return 453.592
            }
        }
        
        var displayName: String {
            switch self {
            case .grams:
                return "Grams"
            case .ounces:
                return "Ounces"
            case .pounds:
                return "Pounds"
            }
        }
    }
    
    private var quantityInGrams: Double {
        guard let value = Double(quantity) else { return 0 }
        return value * selectedUnit.conversionToGrams
    }
    
    private var calculatedNutrition: NutritionInfo {
        return food.calculateNutrition(for: quantityInGrams)
    }
    
    var body: some View {
        NavigationView {
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
                    
                    HStack {
                        TextField("Amount", text: $quantity)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .focused($isTextFieldFocused)
                        
                        Picker("Unit", selection: $selectedUnit) {
                            ForEach(WeightUnit.allCases, id: \.self) { unit in
                                Text(unit.displayName).tag(unit)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                    
                    if quantityInGrams > 0 {
                        Text("= \(String(format: "%.1f", quantityInGrams))g")
                            .font(.caption)
                            .foregroundColor(.secondary)
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
                                color: .red
                            )
                            
                            NutritionRowView(
                                title: "Protein",
                                value: String(format: "%.1f", calculatedNutrition.protein),
                                unit: "g",
                                color: .green
                            )
                            
                            NutritionRowView(
                                title: "Carbs",
                                value: String(format: "%.1f", calculatedNutrition.carbs),
                                unit: "g",
                                color: .orange
                            )
                            
                            NutritionRowView(
                                title: "Fat",
                                value: String(format: "%.1f", calculatedNutrition.fat),
                                unit: "g",
                                color: .purple
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
                        .background(quantityInGrams > 0 ? Color.blue : Color.gray)
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
                isTextFieldFocused = true
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

// MARK: - Debouncer for search
class Debouncer {
    private var workItem: DispatchWorkItem?
    
    func debounce(delay: TimeInterval = 0.5, action: @escaping () -> Void) {
        workItem?.cancel()
        let newWorkItem = DispatchWorkItem(block: action)
        workItem = newWorkItem
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: newWorkItem)
    }
}

#Preview {
    ManualFoodSearchView(selectedMealType: .lunch)
}