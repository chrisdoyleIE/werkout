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
    
    let initialFoodName: String?
    let onFoodSaved: ((String) -> Void)?
    
    // Food identity
    @State private var foodName = ""
    @State private var brandName = ""
    
    // Serving size system
    @State private var selectedServingSize: ServingSize = ServingSize.standardServingSizes.first!
    @StateObject private var servingSizeManager = ServingSizeManager()
    @State private var showingServingSizePicker = false
    @State private var isLoadingServingSuggestion = false
    
    // Nutrition values (per serving)
    @State private var calories: String = ""
    @State private var protein: String = ""
    @State private var carbs: String = ""
    @State private var fat: String = ""
    
    // AI and estimation states
    @State private var useAIEstimation = true
    @State private var isEstimatingWithAI = false
    @State private var isAIEstimated = false
    @State private var aiConfidence: Double = 0.0
    @State private var showingFixPanel = false
    @State private var userFeedback = ""
    
    // UI states
    @State private var isSaving = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var capturedPhotoReference: UIImage?
    
    // Auto-estimation debouncer
    @State private var estimationTask: Task<Void, Never>?
    
    // Progressive flow state
    @State private var currentStep: CreationStep = .foodName
    @State private var showingBrandPrompt = false
    
    enum CreationStep {
        case foodName
        case brandAndDetails
        case servingAndNutrition
    }
    
    init(initialFoodName: String? = nil, capturedPhotoReference: UIImage? = nil, onFoodSaved: ((String) -> Void)? = nil) {
        self.initialFoodName = initialFoodName
        self.onFoodSaved = onFoodSaved
        self._capturedPhotoReference = State(initialValue: capturedPhotoReference)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Progressive Flow Content
                    switch currentStep {
                    case .foodName:
                        FoodNameStep(
                            foodName: $foodName,
                            isEstimating: $isEstimatingWithAI,
                            capturedPhotoReference: capturedPhotoReference,
                            onNext: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    currentStep = .brandAndDetails
                                }
                            }
                        )
                        
                    case .brandAndDetails:
                        BrandDetailsStep(
                            foodName: $foodName,
                            brandName: $brandName,
                            useAIEstimation: $useAIEstimation,
                            isAIEstimated: $isAIEstimated,
                            aiConfidence: $aiConfidence,
                            showingFixPanel: $showingFixPanel,
                            isEstimating: $isEstimatingWithAI,
                            isLoadingServingSuggestion: $isLoadingServingSuggestion,
                            onNext: {
                                Task {
                                    // Always get AI serving size suggestion
                                    await suggestServingSizeFromAI()
                                    
                                    // Then estimate nutrition if requested
                                    if useAIEstimation {
                                        await estimateWithAI()
                                    }
                                    
                                    await MainActor.run {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            currentStep = .servingAndNutrition
                                        }
                                    }
                                }
                            },
                            onBack: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    currentStep = .foodName
                                }
                            }
                        )
                        
                    case .servingAndNutrition:
                        ServingNutritionStep(
                            selectedServingSize: $selectedServingSize,
                            showingServingSizePicker: $showingServingSizePicker,
                            servingSizeManager: servingSizeManager,
                            foodName: foodName,
                            calories: $calories,
                            protein: $protein,
                            carbs: $carbs,
                            fat: $fat,
                            isAIEstimated: isAIEstimated,
                            showingFixPanel: $showingFixPanel,
                            userFeedback: $userFeedback,
                            isEstimating: $isEstimatingWithAI,
                            isSaving: $isSaving,
                            onReEstimate: {
                                Task {
                                    await reEstimateWithFeedback()
                                }
                            },
                            onBack: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    currentStep = .brandAndDetails
                                }
                            },
                            onSave: {
                                saveFood()
                            }
                        )
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding()
            }
            .navigationTitle("Create Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        estimationTask?.cancel()
                        dismiss()
                    }
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
            .sheet(isPresented: $showingServingSizePicker) {
                ServingSizePickerSheet(
                    selectedServingSize: $selectedServingSize,
                    foodName: foodName,
                    servingSizeManager: servingSizeManager
                )
            }
        }
        .onAppear {
            if let initialName = initialFoodName {
                foodName = initialName
                selectedServingSize = ServingSize.suggestedDefaultServing(for: initialName, foodCategory: nil)
                // Skip to brand step if we have initial food name
                currentStep = .brandAndDetails
            }
        }
    }
    
    // MARK: - Serving size suggestion
    
    private func suggestServingSizeFromAI() async {
        guard !foodName.isEmpty else { return }
        
        await MainActor.run {
            isLoadingServingSuggestion = true
        }
        
        do {
            let suggestion = try await ClaudeAPIClient.shared.suggestServingSize(
                foodName: foodName,
                brand: brandName.isEmpty ? nil : brandName
            )
            
            await MainActor.run {
                let volumeML = suggestion.servingCategory == .volume ? suggestion.grams_equivalent : nil
                
                selectedServingSize = ServingSize(
                    name: suggestion.serving_name,
                    gramsEquivalent: suggestion.grams_equivalent,
                    volumeML: volumeML,
                    category: suggestion.servingCategory,
                    isStandard: false
                )
                
                isLoadingServingSuggestion = false
            }
        } catch {
            await MainActor.run {
                // Fall back to current logic on error
                selectedServingSize = ServingSize.suggestedDefaultServing(for: foodName, foodCategory: nil)
                isLoadingServingSuggestion = false
            }
            print("Error getting AI serving suggestion: \(error)")
        }
    }
    
    // MARK: - Nutrition estimation
    
    private func reEstimateWithFeedback() async {
        await estimateWithAI(userFeedback: userFeedback)
        withAnimation(.easeInOut(duration: 0.3)) {
            showingFixPanel = false
        }
        userFeedback = ""
    }
    
    private func estimateWithAI(userFeedback: String? = nil) async {
        guard !foodName.isEmpty else { return }
        
        await MainActor.run {
            isEstimatingWithAI = true
        }
        
        do {
            let nutrition = try await ClaudeAPIClient.shared.estimateNutrition(
                foodName: foodName,
                brand: brandName.isEmpty ? nil : brandName,
                userFeedback: userFeedback
            )
            
            await MainActor.run {
                // Calculate values for the serving size
                let multiplier = selectedServingSize.gramsEquivalent / 100.0
                calories = String(Int(nutrition.calories * multiplier))
                protein = String(format: "%.1f", nutrition.protein * multiplier)
                carbs = String(format: "%.1f", nutrition.carbs * multiplier)
                fat = String(format: "%.1f", nutrition.fat * multiplier)
                
                isAIEstimated = true
                aiConfidence = 0.9 // Default confidence, could be extracted from API response
                isEstimatingWithAI = false
            }
        } catch {
            await MainActor.run {
                alertMessage = "Failed to estimate nutrition: \(error.localizedDescription)"
                showingAlert = true
                isEstimatingWithAI = false
                isAIEstimated = false
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
                let multiplier = 100.0 / selectedServingSize.gramsEquivalent
                
                let foodItem = FoodItem(
                    name: foodName,
                    brand: brandName.isEmpty ? nil : brandName,
                    caloriesPer100g: caloriesValue * multiplier,
                    proteinPer100g: proteinValue * multiplier,
                    carbsPer100g: carbsValue * multiplier,
                    fatPer100g: fatValue * multiplier,
                    servingSizeName: selectedServingSize.name,
                    servingSizeGrams: selectedServingSize.gramsEquivalent
                )
                
                try await supabaseService.createFoodItem(foodItem)
                
                await MainActor.run {
                    // Call completion callback with the final food name
                    onFoodSaved?(foodName)
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
    let onMealSaved: ((String) -> Void)?
    
    @State private var mealName = ""
    @State private var searchText = ""
    @State private var selectedFoods: [MealFood] = []
    @State private var currentStep: MealCreationStep = .nameEntry
    @State private var showingFoodCreator = false
    @State private var editingFood: MealFood?
    @State private var isSaving = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    enum MealCreationStep {
        case nameEntry
        case foodAddition
    }
    
    struct MealFood: Identifiable {
        let id = UUID()
        let food: FoodItem
        var quantity: Double
        var unit: FoodUnit
        
        var nutritionInfo: NutritionInfo {
            let quantityInGrams = quantity * unit.conversionToGrams
            return food.calculateNutrition(for: quantityInGrams)
        }
    }
    
    init(onMealSaved: ((String) -> Void)? = nil) {
        self.onMealSaved = onMealSaved
    }
    
    var totalNutrition: NutritionInfo {
        selectedFoods.reduce(NutritionInfo.zero) { total, mealFood in
            total + mealFood.nutritionInfo
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Progressive Steps
                switch currentStep {
                case .nameEntry:
                    MealNameEntryStep(
                        mealName: $mealName,
                        onNext: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                currentStep = .foodAddition
                            }
                        }
                    )
                    
                case .foodAddition:
                    MealBuilderStep(
                        mealName: mealName,
                        searchText: $searchText,
                        selectedFoods: $selectedFoods,
                        showingFoodCreator: $showingFoodCreator,
                        editingFood: $editingFood,
                        totalNutrition: totalNutrition,
                        onBack: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                currentStep = .nameEntry
                            }
                        },
                        onSave: {
                            saveMeal()
                        },
                        isSaving: $isSaving
                    )
                }
                
                Spacer()
            }
            .navigationTitle("Create Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingFoodCreator) {
                FoodCreatorView(
                    initialFoodName: searchText.isEmpty ? nil : searchText,
                    onFoodSaved: { finalFoodName in
                        // Add the newly created food to search results
                        searchText = finalFoodName
                        Task {
                            // Refresh search or add to selectedFoods
                        }
                    }
                )
            }
            .sheet(item: $editingFood) { mealFood in
                QuantityEditSheet(mealFood: mealFood, selectedFoods: $selectedFoods)
            }
            .alert("Error", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
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
                    // Call completion callback with the meal name
                    onMealSaved?(mealName)
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

// MARK: - Meal Creation Steps

struct MealNameEntryStep: View {
    @Binding var mealName: String
    let onNext: () -> Void
    
    private var isValidMealName: Bool {
        let trimmedName = mealName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedName.count >= 2
    }
    
    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 24) {
                // Hero icon
                Image(systemName: "rectangle.stack.badge.plus")
                    .font(.system(size: 48, weight: .medium))
                    .foregroundColor(.primary)
                    .opacity(0.8)
                
                VStack(spacing: 16) {
                    Text("Create Your Meal")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    
                    Text("Give your meal a name to get started")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            VStack(spacing: 24) {
                TextField("Enter meal name", text: $mealName)
                    .font(.system(size: 18, weight: .medium))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                
                Button(action: onNext) {
                    HStack {
                        Text("Continue")
                            .font(.system(size: 16, weight: .semibold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(isValidMealName ? Color.primary : Color(.systemGray4))
                    .cornerRadius(12)
                }
                .disabled(!isValidMealName)
            }
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 40)
    }
}

struct MealBuilderStep: View {
    let mealName: String
    @Binding var searchText: String
    @Binding var selectedFoods: [MealCreatorView.MealFood]
    @Binding var showingFoodCreator: Bool
    @Binding var editingFood: MealCreatorView.MealFood?
    let totalNutrition: NutritionInfo
    let onBack: () -> Void
    let onSave: () -> Void
    @Binding var isSaving: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "rectangle.stack.badge.plus")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text(mealName)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Spacer()
                }
                
                if !selectedFoods.isEmpty {
                    MealSummaryCard(
                        selectedFoods: selectedFoods,
                        totalNutrition: totalNutrition,
                        onEditFood: { food in
                            editingFood = food
                        },
                        onRemoveFood: { food in
                            selectedFoods.removeAll { $0.id == food.id }
                        }
                    )
                }
            }
            .padding(.horizontal)
            .padding(.top, 16)
            
            // Divider between selected foods and search
            if !selectedFoods.isEmpty {
                Rectangle()
                    .fill(Color(.systemGray5))
                    .frame(height: 1)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
            }
            
            // Food Search Section
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                }
                .padding(.horizontal)
                
                FoodSearchCore(
                    searchText: $searchText,
                    onFoodSelected: { food in
                        // Add selected food with default quantity
                        let mealFood = MealCreatorView.MealFood(
                            food: food,
                            quantity: 100,
                            unit: .grams
                        )
                        selectedFoods.append(mealFood)
                        searchText = ""
                    },
                    onCreateFood: {
                        showingFoodCreator = true
                    },
                    onCreateMeal: {
                        // Not applicable in meal creation context
                    },
                    showCreateMeal: false
                )
                .padding(.horizontal)
            }
            
            // Bottom Actions
            VStack(spacing: 12) {
                if !selectedFoods.isEmpty {
                    Text("Total: \(Int(totalNutrition.calories)) cal • \(String(format: "%.1f", totalNutrition.protein))g protein")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 12) {
                    Button(action: onBack) {
                        HStack {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Back")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .frame(maxWidth: .infinity, maxHeight: 52)
                    
                    Button(action: onSave) {
                        HStack {
                            if isSaving {
                                ProgressView()
                                    .scaleEffect(0.9)
                                    .foregroundColor(.white)
                                Text("Saving...")
                                    .font(.system(size: 18, weight: .bold))
                            } else {
                                Text("Save Meal")
                                    .font(.system(size: 18, weight: .bold))
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 16, weight: .bold))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background((!selectedFoods.isEmpty && !isSaving) ? Color.primary : Color(.systemGray4))
                        .cornerRadius(16)
                    }
                    .frame(maxWidth: .infinity, maxHeight: 56)
                    .disabled(selectedFoods.isEmpty || isSaving)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
            .background(Color(.systemBackground))
        }
    }
}

struct MealSummaryCard: View {
    let selectedFoods: [MealCreatorView.MealFood]
    let totalNutrition: NutritionInfo
    let onEditFood: (MealCreatorView.MealFood) -> Void
    let onRemoveFood: (MealCreatorView.MealFood) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "list.bullet")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text("Added Foods (\(selectedFoods.count))")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            VStack(spacing: 8) {
                ForEach(selectedFoods) { mealFood in
                    MealFoodCard(
                        mealFood: mealFood,
                        onEdit: { onEditFood(mealFood) },
                        onRemove: { onRemoveFood(mealFood) }
                    )
                }
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct MealFoodCard: View {
    let mealFood: MealCreatorView.MealFood
    let onEdit: () -> Void
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "circle.fill")
                .font(.system(size: 16))
                .foregroundColor(.primary.opacity(0.7))
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(mealFood.food.displayName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text("\(Int(mealFood.quantity))\(mealFood.unit.abbreviation)")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("\(Int(mealFood.nutritionInfo.calories)) cal")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
            
            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(PlainButtonStyle())
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
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

// MARK: - Progressive Flow Steps

struct FoodNameStep: View {
    @Binding var foodName: String
    @Binding var isEstimating: Bool
    let capturedPhotoReference: UIImage?
    let onNext: () -> Void
    
    private var isValidFoodName: Bool {
        let trimmedName = foodName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedName.count >= 2 && !trimmedName.allSatisfy { $0.isWhitespace }
    }
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 16) {
                Text("What are you eating?")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                // Photo reference section
                if let photo = capturedPhotoReference {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Photo Reference")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Image(uiImage: photo)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 100)
                            .cornerRadius(8)
                            .clipped()
                    }
                }
                
                // Food name input
                TextField("Enter food name", text: $foodName)
                    .font(.system(size: 18, weight: .medium))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                
                Text("Enter the full name of the food for better accuracy (e.g., 'Granny Smith Apple' instead of 'Apple')")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                
                if isEstimating {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Looking up nutrition information...")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.top, 8)
                }
            }
            .padding(24)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(.systemGray5), lineWidth: 0.5)
            )
            
            Button(action: onNext) {
                HStack {
                    Text("Continue")
                        .font(.system(size: 16, weight: .semibold))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(isValidFoodName ? Color.primary : Color(.systemGray4))
                .cornerRadius(12)
            }
            .disabled(!isValidFoodName)
        }
    }
}

struct BrandDetailsStep: View {
    @Binding var foodName: String
    @Binding var brandName: String
    @Binding var useAIEstimation: Bool
    @Binding var isAIEstimated: Bool
    @Binding var aiConfidence: Double
    @Binding var showingFixPanel: Bool
    @Binding var isEstimating: Bool
    @Binding var isLoadingServingSuggestion: Bool
    let onNext: () -> Void
    let onBack: () -> Void
    
    private var isValidFoodName: Bool {
        let trimmedName = foodName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedName.count >= 2 && !trimmedName.allSatisfy { $0.isWhitespace }
    }
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Help us be more accurate")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("Adding a brand helps us find the exact nutrition information for your food")
                        .font(.system(size: 16))
                        .foregroundColor(Color(red: 0.33, green: 0.33, blue: 0.33))
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                TextField("Food name", text: $foodName)
                    .font(.system(size: 18, weight: .medium))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                
                TextField("Brand name (optional)", text: $brandName)
                    .font(.system(size: 18, weight: .medium))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                
                // AI Estimation Toggle
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "wand.and.stars.inverse")
                            .font(.system(size: 20))
                            .foregroundColor(useAIEstimation ? Color.purple : Color(.systemGray3))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("AI Nutrition Estimation")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primary)
                            
                            Text("Automatically estimate nutrition values")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $useAIEstimation)
                            .toggleStyle(SwitchToggleStyle(tint: Color.purple))
                            .scaleEffect(0.9)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    if !useAIEstimation {
                        Text("You'll enter nutrition values manually in the next step")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 4)
                    }
                }
                
                // Serving size prediction status
                if isLoadingServingSuggestion {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Suggesting natural serving size...")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.top, 8)
                }
                
                // AI Status (only show when AI estimation is enabled)
                if useAIEstimation {
                    if isEstimating {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Re-estimating with brand information...")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                    } else if isAIEstimated {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Nutrition estimated")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.primary)
                            
                            Text("(\(Int(aiConfidence * 100))% confidence)")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Button("Adjust") {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showingFixPanel.toggle()
                                }
                            }
                            .font(.system(size: 14))
                            .foregroundColor(.blue)
                        }
                        .padding(.top, 8)
                    }
                }
            }
            .padding(24)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(.systemGray5), lineWidth: 0.5)
            )
            
            HStack(spacing: 12) {
                Button(action: onBack) {
                    HStack {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                
                Button(action: onNext) {
                    HStack {
                        if isEstimating || isLoadingServingSuggestion {
                            ProgressView()
                                .scaleEffect(0.8)
                                .foregroundColor(.white)
                            Text(isLoadingServingSuggestion ? "Suggesting serving size..." : "Getting nutrition info...")
                                .font(.system(size: 16, weight: .semibold))
                        } else {
                            Text(useAIEstimation ? "Estimate & Continue" : "Continue")
                                .font(.system(size: 16, weight: .semibold))
                            Image(systemName: useAIEstimation ? "wand.and.stars" : "arrow.right")
                                .font(.system(size: 14, weight: .semibold))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(isValidFoodName && !isEstimating && !isLoadingServingSuggestion ? Color.primary : Color(.systemGray4))
                    .cornerRadius(12)
                }
                .disabled(!isValidFoodName || isEstimating || isLoadingServingSuggestion)
            }
        }
    }
}

struct ServingNutritionStep: View {
    @Binding var selectedServingSize: ServingSize
    @Binding var showingServingSizePicker: Bool
    @ObservedObject var servingSizeManager: ServingSizeManager
    let foodName: String
    @Binding var calories: String
    @Binding var protein: String
    @Binding var carbs: String
    @Binding var fat: String
    let isAIEstimated: Bool
    @Binding var showingFixPanel: Bool
    @Binding var userFeedback: String
    @Binding var isEstimating: Bool
    @Binding var isSaving: Bool
    let onReEstimate: () -> Void
    let onBack: () -> Void
    let onSave: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // Serving Size Card
            SmartServingCard(
                selectedServingSize: $selectedServingSize,
                showingServingSizePicker: $showingServingSizePicker,
                servingSizeManager: servingSizeManager,
                foodName: foodName
            )
            
            // Nutrition Card
            NutritionCard(
                calories: $calories,
                protein: $protein,
                carbs: $carbs,
                fat: $fat,
                selectedServingSize: selectedServingSize,
                isAIEstimated: isAIEstimated
            )
            
            // Fix Panel (expandable)
            if showingFixPanel {
                FixFeedbackPanel(
                    userFeedback: $userFeedback,
                    isEstimating: $isEstimating,
                    onReEstimate: onReEstimate
                )
                .transition(.opacity.combined(with: .scale))
            }
            
            HStack(spacing: 12) {
                Button(action: onBack) {
                    HStack {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .frame(maxWidth: .infinity, maxHeight: 52)
                
                Button(action: onSave) {
                    HStack {
                        if isSaving {
                            ProgressView()
                                .scaleEffect(0.9)
                                .foregroundColor(.white)
                            Text("Saving...")
                                .font(.system(size: 18, weight: .bold))
                        } else {
                            Text("Save Food")
                                .font(.system(size: 18, weight: .bold))
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16, weight: .bold))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background((!foodName.isEmpty && !calories.isEmpty && !isSaving) ? Color.primary : Color(.systemGray4))
                    .cornerRadius(16)
                }
                .frame(maxWidth: .infinity, maxHeight: 56)
                .disabled(foodName.isEmpty || calories.isEmpty || isSaving)
            }
        }
    }
}

struct NutritionComparisonTable: View {
    let calories: String
    let protein: String 
    let carbs: String
    let fat: String
    let selectedServingSize: ServingSize
    let calculatePer100g: (Double) -> Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Nutrition Comparison")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
            
            VStack(spacing: 6) {
                // Header
                HStack {
                    Text("Nutrient")
                        .font(.system(size: 12, weight: .medium))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("Per Serving")
                        .font(.system(size: 12, weight: .medium))
                        .frame(maxWidth: .infinity, alignment: .center)
                    Text("Per 100g")
                        .font(.system(size: 12, weight: .medium))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .foregroundColor(.secondary)
                .padding(.bottom, 4)
                
                Divider()
                
                // Nutrition rows
                if let cal = Double(calories) {
                    NutritionComparisonRow(
                        nutrient: "Calories",
                        perServing: "\(Int(cal)) cal",
                        per100g: "\(Int(calculatePer100g(cal))) cal"
                    )
                }
                
                if let prot = Double(protein) {
                    NutritionComparisonRow(
                        nutrient: "Protein",
                        perServing: "\(String(format: "%.1f", prot))g",
                        per100g: "\(String(format: "%.1f", calculatePer100g(prot)))g"
                    )
                }
                
                if let carbsVal = Double(carbs) {
                    NutritionComparisonRow(
                        nutrient: "Carbs",
                        perServing: "\(String(format: "%.1f", carbsVal))g",
                        per100g: "\(String(format: "%.1f", calculatePer100g(carbsVal)))g"
                    )
                }
                
                if let fatVal = Double(fat) {
                    NutritionComparisonRow(
                        nutrient: "Fat",
                        perServing: "\(String(format: "%.1f", fatVal))g",
                        per100g: "\(String(format: "%.1f", calculatePer100g(fatVal)))g"
                    )
                }
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct NutritionComparisonRow: View {
    let nutrient: String
    let perServing: String
    let per100g: String
    
    var body: some View {
        HStack {
            Text(nutrient)
                .font(.system(size: 13))
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(perServing)
                .font(.system(size: 13, weight: .medium))
                .frame(maxWidth: .infinity, alignment: .center)
            Text(per100g)
                .font(.system(size: 13, weight: .medium))
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .foregroundColor(.primary)
    }
}

// MARK: - Shared Food Search Components

struct FoodSearchBar: View {
    @Binding var searchText: String
    let placeholder: String
    let onClear: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField(placeholder, text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !searchText.isEmpty {
                Button(action: onClear) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}


struct FoodSearchCore: View {
    @Binding var searchText: String
    let onFoodSelected: (FoodItem) -> Void
    let onCreateFood: () -> Void
    let onCreateMeal: () -> Void
    let showCreateMeal: Bool
    
    @StateObject private var supabaseService = SupabaseService.shared
    @State private var searchResults: [FoodItem] = []
    @State private var isSearching = false
    @State private var recentItems: [RecentFoodItem] = []
    
    var body: some View {
        VStack(spacing: 16) {
            // Search Bar
            FoodSearchBar(
                searchText: $searchText,
                placeholder: "Search foods...",
                onClear: {
                    searchText = ""
                    searchResults = []
                }
            )
            
            ScrollView {
                VStack(spacing: 16) {
                    // Recent Items Section
                    if searchText.isEmpty && !recentItems.isEmpty {
                        FoodSearchSection(
                            title: "Recent",
                            items: {
                                ForEach(recentItems.prefix(5)) { item in
                                    RecentItemRow(item: item) {
                                        // Handle recent item selection
                                        if let foodItem = convertToFoodItem(item) {
                                            onFoodSelected(foodItem)
                                        }
                                    }
                                }
                            }
                        )
                    }
                    
                    // Database Search Results
                    if !searchText.isEmpty && !searchResults.isEmpty {
                        FoodSearchSection(
                            title: "From Database",
                            items: {
                                ForEach(searchResults) { food in
                                    DatabaseFoodRow(food: food) {
                                        onFoodSelected(food)
                                    }
                                }
                            }
                        )
                    }
                    
                    // Create New Options
                    if !searchText.isEmpty {
                        FoodSearchSection(
                            title: "Can't find it?",
                            items: {
                                VStack(spacing: 8) {
                                    CreateFoodRow(foodName: searchText) {
                                        onCreateFood()
                                    }
                                    
                                    if showCreateMeal {
                                        CreateMealRow {
                                            onCreateMeal()
                                        }
                                    }
                                }
                            }
                        )
                    }
                    
                    // Empty search state
                    if searchText.isEmpty && recentItems.isEmpty {
                        MealCreationEmptyState()
                            .padding(.top, 40)
                    }
                    
                    // No results state
                    if !searchText.isEmpty && searchResults.isEmpty && !isSearching {
                        NoResultsView(query: searchText)
                            .padding(.top, 40)
                    }
                }
            }
            
            if isSearching {
                ProgressView()
                    .padding()
            }
        }
        .onChange(of: searchText) { _, newValue in
            Task {
                await performSearch(query: newValue)
            }
        }
        .task {
            await loadRecentItems()
        }
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
    
    private func loadRecentItems() async {
        do {
            let items = try await supabaseService.getRecentFoodsAndMeals(
                days: 7,
                mealType: nil
            )
            await MainActor.run {
                recentItems = items
            }
        } catch {
            print("Failed to load recent items: \(error)")
        }
    }
    
    private func convertToFoodItem(_ recentItem: RecentFoodItem) -> FoodItem? {
        // Convert RecentFoodItem to FoodItem for consistency
        // This is a placeholder - actual conversion depends on your data models
        return FoodItem(
            id: UUID(),
            name: recentItem.name,
            brand: nil,
            caloriesPer100g: recentItem.caloriesPerServing,
            proteinPer100g: recentItem.proteinPerServing,
            carbsPer100g: 0, // Would need actual values
            fatPer100g: 0,   // Would need actual values
            servingSizeName: "100g",
            servingSizeGrams: 100
        )
    }
}

// MARK: - Empty State Components

struct MealCreationEmptyState: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass.circle")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(.secondary.opacity(0.7))
            
            VStack(spacing: 12) {
                Text("Search for foods to add")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.primary)
                
                VStack(spacing: 8) {
                    Text("• Type a food name to search our database")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    
                    Text("• Create custom foods if you can't find them")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    
                    Text("• Build your meal by adding multiple foods")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .multilineTextAlignment(.leading)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 40)
    }
}

// MARK: - Card Components

struct FoodIdentityCard: View {
    @Binding var foodName: String
    @Binding var brandName: String
    @Binding var isAIEstimated: Bool
    @Binding var aiConfidence: Double
    @Binding var showingFixPanel: Bool
    @Binding var isEstimating: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Food Identity")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                TextField("Food name", text: $foodName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.system(size: 16, weight: .medium))
                
                TextField("Brand (optional)", text: $brandName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.system(size: 16))
                
                // AI Status Badge
                if isEstimating {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Estimating nutrition...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                } else if isAIEstimated {
                    HStack {
                        Image(systemName: "wand.and.stars.inverse")
                            .foregroundColor(.blue)
                        Text("AI Estimated")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                        
                        Text("(\(Int(aiConfidence * 100))% confidence)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Button("Fix") {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showingFixPanel.toggle()
                            }
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                }
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.systemGray5), lineWidth: 0.5)
        )
    }
}

struct SmartServingCard: View {
    @Binding var selectedServingSize: ServingSize
    @Binding var showingServingSizePicker: Bool
    @ObservedObject var servingSizeManager: ServingSizeManager
    let foodName: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Choose Your Serving")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                Button(action: {
                    showingServingSizePicker = true
                }) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Serving")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(selectedServingSize.shortDisplayText)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.down")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
                
                if let volumeML = selectedServingSize.volumeML {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Volume")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(Int(volumeML))ml")
                                .font(.system(size: 14, weight: .medium))
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.systemGray5), lineWidth: 0.5)
        )
    }
}

struct NutritionCard: View {
    @Binding var calories: String
    @Binding var protein: String
    @Binding var carbs: String
    @Binding var fat: String
    let selectedServingSize: ServingSize
    let isAIEstimated: Bool
    
    private var shouldShowComparisonTable: Bool {
        return selectedServingSize.gramsEquivalent != 100.0
    }
    
    private func calculatePer100g(_ value: Double) -> Double {
        let multiplier = 100.0 / selectedServingSize.gramsEquivalent
        return value * multiplier
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Nutrition (per \(selectedServingSize.shortDisplayText))")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                NutritionRow(
                    iconName: "flame.fill",
                    label: "Calories",
                    value: $calories,
                    unit: "cal",
                    isEditable: true
                )
                
                NutritionRow(
                    iconName: "figure.strengthtraining.traditional",
                    label: "Protein",
                    value: $protein,
                    unit: "g",
                    isEditable: true
                )
                
                NutritionRow(
                    iconName: "leaf.fill",
                    label: "Carbs",
                    value: $carbs,
                    unit: "g",
                    isEditable: true
                )
                
                NutritionRow(
                    iconName: "drop.fill",
                    label: "Fat",
                    value: $fat,
                    unit: "g",
                    isEditable: true
                )
                
                if shouldShowComparisonTable && !calories.isEmpty && !protein.isEmpty {
                    NutritionComparisonTable(
                        calories: calories,
                        protein: protein,
                        carbs: carbs,
                        fat: fat,
                        selectedServingSize: selectedServingSize,
                        calculatePer100g: calculatePer100g
                    )
                    .padding(.top, 8)
                }
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.systemGray5), lineWidth: 0.5)
        )
    }
}

struct NutritionRow: View {
    let iconName: String
    let label: String
    @Binding var value: String
    let unit: String
    let isEditable: Bool
    
    var iconColor: Color {
        switch iconName {
        case "flame.fill":
            return .orange
        case "figure.strengthtraining.traditional":
            return .blue
        case "leaf.fill":
            return .green
        case "drop.fill":
            return .purple
        default:
            return .primary
        }
    }
    
    var body: some View {
        HStack {
            Image(systemName: iconName)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(iconColor)
                .frame(width: 20)
            
            Text(label)
                .font(.system(size: 16, weight: .medium))
                .frame(width: 80, alignment: .leading)
            
            Spacer()
            
            if isEditable {
                TextField("0", text: $value)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 80)
                    .multilineTextAlignment(.trailing)
            } else {
                Text(value.isEmpty ? "0" : value)
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 80, alignment: .trailing)
            }
            
            Text(unit)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .frame(width: 30, alignment: .leading)
        }
    }
}

struct FixFeedbackPanel: View {
    @Binding var userFeedback: String
    @Binding var isEstimating: Bool
    let onReEstimate: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "lightbulb")
                    .foregroundColor(.blue)
                Text("Help Claude improve this estimate:")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
            }
            
            TextField("e.g., 'This is Greek yogurt, not regular' or 'The protein seems too low'", 
                     text: $userFeedback, axis: .vertical)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .lineLimit(2...4)
            
            Button(action: onReEstimate) {
                HStack {
                    if isEstimating {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "wand.and.stars")
                    }
                    Text("Re-estimate with feedback")
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(userFeedback.isEmpty ? Color.gray : Color.blue)
                .cornerRadius(12)
            }
            .disabled(userFeedback.isEmpty || isEstimating)
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }
}

struct ServingSizePickerSheet: View {
    @Binding var selectedServingSize: ServingSize
    let foodName: String
    @ObservedObject var servingSizeManager: ServingSizeManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("Suggested for this food") {
                    ForEach(getSuggestedServings(), id: \.id) { serving in
                        ServingSizeRow(
                            serving: serving,
                            isSelected: serving.id == selectedServingSize.id
                        ) {
                            selectedServingSize = serving
                            dismiss()
                        }
                    }
                }
                
                Section("Standard servings") {
                    ForEach(getStandardServings(), id: \.id) { serving in
                        ServingSizeRow(
                            serving: serving,
                            isSelected: serving.id == selectedServingSize.id
                        ) {
                            selectedServingSize = serving
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle("Choose Serving Size")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func getSuggestedServings() -> [ServingSize] {
        let suggested = ServingSize.suggestedDefaultServing(for: foodName, foodCategory: nil)
        return [suggested]
    }
    
    private func getStandardServings() -> [ServingSize] {
        return ServingSize.standardServingSizes.filter { $0.isStandard }
    }
}

struct ServingSizeRow: View {
    let serving: ServingSize
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading) {
                    Text(serving.name)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Text("\(Int(serving.gramsEquivalent))g")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
#Preview("Food Creator") {
    FoodCreatorView()
}

#Preview("Meal Creator") {
    MealCreatorView()
}
