import SwiftUI

// MARK: - Food Unit Definition
enum FoodUnit: String, CaseIterable {
    case grams = "g"
    case ounces = "oz"
    case pounds = "lbs"
    case cups = "cups"
    case tablespoons = "tbsp"
    case teaspoons = "tsp"
    case pieces = "pieces"
    
    var displayName: String {
        switch self {
        case .grams: return "grams"
        case .ounces: return "ounces"
        case .pounds: return "pounds"
        case .cups: return "cups"
        case .tablespoons: return "tablespoons"
        case .teaspoons: return "teaspoons"
        case .pieces: return "pieces"
        }
    }
    
    var abbreviation: String {
        return rawValue
    }
    
    var conversionToGrams: Double {
        switch self {
        case .grams: return 1.0
        case .ounces: return 28.3495
        case .pounds: return 453.592
        case .cups: return 240.0  // Approximate for liquids
        case .tablespoons: return 15.0
        case .teaspoons: return 5.0
        case .pieces: return 1.0  // Context-dependent
        }
    }
}

// MARK: - Food Creator View
struct FoodCreatorView: View {
    @Environment(\.dismiss) private var dismiss
    private let supabaseService = SupabaseService.shared
    
    @State private var foodName = ""
    @State private var brandName = ""
    @State private var servingSizeName = "100g"
    @State private var servingSizeGrams: Double = 100
    
    // Macros per serving
    @State private var calories: String = ""
    @State private var protein: String = ""
    @State private var carbs: String = ""
    @State private var fat: String = ""
    
    @State private var isEstimatingWithAI = false
    @State private var isSaving = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Food Details") {
                    TextField("Food Name", text: $foodName)
                    TextField("Brand (optional)", text: $brandName)
                }
                
                Section("Serving Size") {
                    TextField("Serving Name", text: $servingSizeName)
                    HStack {
                        TextField("Grams", value: $servingSizeGrams, format: .number)
                            .keyboardType(.decimalPad)
                        Text("g")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Nutrition per Serving") {
                    HStack {
                        TextField("Calories", text: $calories)
                            .keyboardType(.decimalPad)
                        Text("cal")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        TextField("Protein", text: $protein)
                            .keyboardType(.decimalPad)
                        Text("g")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        TextField("Carbs", text: $carbs)
                            .keyboardType(.decimalPad)
                        Text("g")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        TextField("Fat", text: $fat)
                            .keyboardType(.decimalPad)
                        Text("g")
                            .foregroundColor(.secondary)
                    }
                    
                    Button(action: estimateWithAI) {
                        HStack {
                            Image(systemName: "wand.and.stars")
                            Text("Estimate with AI")
                            if isEstimatingWithAI {
                                Spacer()
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                    }
                    .disabled(foodName.isEmpty || isEstimatingWithAI)
                }
            }
            .navigationTitle("Create Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveFood()
                    }
                    .disabled(foodName.isEmpty || calories.isEmpty || isSaving)
                }
            }
            .alert("Error", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            .overlay {
                if isSaving {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    ProgressView("Saving...")
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(10)
                }
            }
        }
    }
    
    private func estimateWithAI() {
        guard !foodName.isEmpty else { return }
        
        isEstimatingWithAI = true
        
        Task {
            do {
                let nutrition = try await ClaudeAPIClient.shared.estimateNutrition(
                    foodName: foodName,
                    brand: brandName.isEmpty ? nil : brandName
                )
                
                await MainActor.run {
                    // Calculate values for the serving size
                    let multiplier = servingSizeGrams / 100.0
                    calories = String(Int(nutrition.calories * multiplier))
                    protein = String(format: "%.1f", nutrition.protein * multiplier)
                    carbs = String(format: "%.1f", nutrition.carbs * multiplier)
                    fat = String(format: "%.1f", nutrition.fat * multiplier)
                    
                    isEstimatingWithAI = false
                }
            } catch {
                await MainActor.run {
                    alertMessage = "Failed to estimate nutrition: \(error.localizedDescription)"
                    showingAlert = true
                    isEstimatingWithAI = false
                }
            }
        }
    }
    
    private func saveFood() {
        guard let caloriesValue = Double(calories),
              let proteinValue = Double(protein),
              let carbsValue = Double(carbs),
              let fatValue = Double(fat) else {
            alertMessage = "Please enter valid numbers for all nutrition values"
            showingAlert = true
            return
        }
        
        isSaving = true
        
        Task {
            do {
                // Calculate per 100g values
                let multiplier = 100.0 / servingSizeGrams
                
                let foodItem = FoodItem(
                    name: foodName,
                    brand: brandName.isEmpty ? nil : brandName,
                    caloriesPer100g: caloriesValue * multiplier,
                    proteinPer100g: proteinValue * multiplier,
                    carbsPer100g: carbsValue * multiplier,
                    fatPer100g: fatValue * multiplier,
                    servingSizeName: servingSizeName,
                    servingSizeGrams: servingSizeGrams
                )
                
                try await supabaseService.createFoodItem(foodItem)
                
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    alertMessage = "Failed to save food: \(error.localizedDescription)"
                    showingAlert = true
                    isSaving = false
                }
            }
        }
    }
}

// MARK: - Meal Creator View
struct MealCreatorView: View {
    @Environment(\.dismiss) private var dismiss
    private let supabaseService = SupabaseService.shared
    
    @State private var mealName = ""
    @State private var searchText = ""
    @State private var selectedFoods: [MealFood] = []
    @State private var showingFoodSearch = false
    @State private var editingFood: MealFood?
    @State private var isSaving = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    // For quantity input
    @State private var quantityInput = ""
    @State private var selectedUnit: FoodUnit = .grams
    
    struct MealFood: Identifiable {
        let id = UUID()
        let food: FoodItem
        var quantity: Double
        var unit: FoodUnit
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Form {
                    Section("Meal Details") {
                        TextField("Meal Name", text: $mealName)
                    }
                    
                    Section("Foods") {
                        if selectedFoods.isEmpty {
                            Text("No foods added yet")
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(selectedFoods) { mealFood in
                                MealFoodRow(mealFood: mealFood) {
                                    editingFood = mealFood
                                }
                            }
                            .onDelete(perform: deleteFoods)
                        }
                        
                        Button(action: { showingFoodSearch = true }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add Food")
                            }
                        }
                    }
                    
                    if !selectedFoods.isEmpty {
                        Section("Total Nutrition") {
                            MealNutritionSummaryRow(nutrition: totalNutrition)
                        }
                    }
                }
            }
            .navigationTitle("Create Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveMeal()
                    }
                    .disabled(mealName.isEmpty || selectedFoods.isEmpty || isSaving)
                }
            }
            .sheet(isPresented: $showingFoodSearch) {
                FoodSearchSheet(selectedFoods: $selectedFoods)
            }
            .sheet(item: $editingFood) { mealFood in
                QuantityEditSheet(mealFood: mealFood, selectedFoods: $selectedFoods)
            }
            .alert("Error", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            .overlay {
                if isSaving {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    ProgressView("Saving...")
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(10)
                }
            }
        }
    }
    
    private var totalNutrition: NutritionInfo {
        selectedFoods.reduce(NutritionInfo.zero) { total, mealFood in
            let foodNutrition = mealFood.food.calculateNutrition(for: mealFood.quantity)
            return total + foodNutrition
        }
    }
    
    private func deleteFoods(at offsets: IndexSet) {
        selectedFoods.remove(atOffsets: offsets)
    }
    
    private func saveMeal() {
        isSaving = true
        
        Task {
            do {
                let mealComponents = selectedFoods.map { mealFood in
                    // Convert quantity to grams based on unit
                    let quantityInGrams = mealFood.quantity * mealFood.unit.conversionToGrams
                    
                    return MealComponent(
                        foodItemId: mealFood.food.id,
                        quantityGrams: quantityInGrams,
                        foodName: mealFood.food.name,
                        brand: mealFood.food.brand,
                        caloriesPer100g: mealFood.food.caloriesPer100g,
                        proteinPer100g: mealFood.food.proteinPer100g,
                        carbsPer100g: mealFood.food.carbsPer100g,
                        fatPer100g: mealFood.food.fatPer100g
                    )
                }
                
                let _ = try await supabaseService.saveMealTemplate(
                    name: mealName,
                    foods: mealComponents
                )
                
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    alertMessage = "Failed to save meal: \(error.localizedDescription)"
                    showingAlert = true
                    isSaving = false
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct MealFoodRow: View {
    let mealFood: MealCreatorView.MealFood
    let onEdit: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(mealFood.food.displayName)
                    .font(.system(size: 16, weight: .medium))
                Text("\(Int(mealFood.quantity))\(mealFood.unit.abbreviation)")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text("\(Int(mealFood.food.calculateNutrition(for: mealFood.quantity).calories)) cal")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onEdit()
        }
    }
}

struct MealNutritionSummaryRow: View {
    let nutrition: NutritionInfo
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Calories")
                Spacer()
                Text("\(Int(nutrition.calories)) cal")
                    .fontWeight(.medium)
            }
            
            HStack {
                Text("Protein")
                Spacer()
                Text("\(Int(nutrition.protein))g")
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("Carbs")
                Spacer()
                Text("\(Int(nutrition.carbs))g")
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("Fat")
                Spacer()
                Text("\(Int(nutrition.fat))g")
                    .foregroundColor(.secondary)
            }
        }
        .font(.system(size: 14))
    }
}

struct FoodSearchSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedFoods: [MealCreatorView.MealFood]
    
    @State private var searchText = ""
    @State private var selectedFood: FoodItem?
    @State private var quantity: Double = 100
    @State private var unit: FoodUnit = .grams
    
    var body: some View {
        NavigationView {
            VStack {
                // Reuse the shared search components
                SharedFoodSearchBar(
                    searchText: $searchText,
                    placeholder: "Search foods...",
                    onClear: {
                        searchText = ""
                    }
                )
                .padding()
                
                // Simplified food search results
                ScrollView {
                    Text("Food search functionality would go here")
                        .foregroundColor(.secondary)
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
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        if let food = selectedFood {
                            selectedFoods.append(
                                MealCreatorView.MealFood(
                                    food: food,
                                    quantity: quantity,
                                    unit: unit
                                )
                            )
                            dismiss()
                        }
                    }
                    .disabled(selectedFood == nil)
                }
            }
        }
    }
}

struct QuantityEditSheet: View {
    let mealFood: MealCreatorView.MealFood
    @Binding var selectedFoods: [MealCreatorView.MealFood]
    @Environment(\.dismiss) private var dismiss
    
    @State private var quantity: Double
    @State private var unit: FoodUnit
    
    init(mealFood: MealCreatorView.MealFood, selectedFoods: Binding<[MealCreatorView.MealFood]>) {
        self.mealFood = mealFood
        self._selectedFoods = selectedFoods
        self._quantity = State(initialValue: mealFood.quantity)
        self._unit = State(initialValue: mealFood.unit)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Food") {
                    Text(mealFood.food.displayName)
                        .font(.system(size: 16, weight: .medium))
                }
                
                Section("Quantity") {
                    TextField("Amount", value: $quantity, format: .number)
                        .keyboardType(.decimalPad)
                    
                    Picker("Unit", selection: $unit) {
                        ForEach(FoodUnit.allCases, id: \.self) { unit in
                            Text(unit.displayName).tag(unit)
                        }
                    }
                }
            }
            .navigationTitle("Edit Quantity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if let index = selectedFoods.firstIndex(where: { $0.id == mealFood.id }) {
                            selectedFoods[index].quantity = quantity
                            selectedFoods[index].unit = unit
                        }
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview
#Preview("Food Creator") {
    FoodCreatorView()
}

#Preview("Meal Creator") {
    MealCreatorView()
}