import SwiftUI
import PhotosUI

// MARK: - Enums and Type Definitions

enum NutritionSource {
    case nutritionLabel  // PhotosPicker for nutrition label
    case webLookup      // AI/database search
    case manual         // User enters manually
}

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
    @State private var selectedServingSize: ServingSize = ServingSize(from: MasterServingSize.grams100)
    @StateObject private var servingSizeManager = ServingSizeManager()
    @State private var showingServingSizePicker = false
    @State private var isLoadingServingSuggestion = false
    
    // Nutrition values (per serving)
    @State private var calories: String = ""
    @State private var protein: String = ""
    @State private var carbs: String = ""
    @State private var fat: String = ""
    
    // Raw nutrition data from label scanning
    @State private var rawNutritionData: RawNutritionData?
    
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
    
    // Auto-estimation debouncer
    @State private var estimationTask: Task<Void, Never>?
    
    // Progressive flow state
    @State private var currentStep: CreationStep = .foodDetails
    @State private var selectedNutritionSource: NutritionSource = .webLookup
    @State private var showingBrandPrompt = false
    
    enum CreationStep {
        case foodDetails
        case servingAndNutrition
    }
    
    // PhotosPicker states
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var capturedImage: UIImage?
    @State private var isProcessingPhoto = false
    @State private var showPhotosPicker = false
    
    init(initialFoodName: String? = nil, onFoodSaved: ((String) -> Void)? = nil) {
        self.initialFoodName = initialFoodName
        self.onFoodSaved = onFoodSaved
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Step Progress Indicator
                    StepProgressView(currentStep: currentStep)
                    
                    // Progressive Flow Content
                    switch currentStep {
                    case .foodDetails:
                        FoodDetailsStep(
                            foodName: $foodName,
                            brandName: $brandName,
                            selectedNutritionSource: $selectedNutritionSource,
                            selectedPhotoItem: $selectedPhotoItem,
                            capturedImage: capturedImage,
                            isProcessingPhoto: $isProcessingPhoto,
                            isEstimating: $isEstimatingWithAI,
                            isLoadingServingSuggestion: $isLoadingServingSuggestion,
                            showPhotosPicker: $showPhotosPicker,
                            onNext: {
                                Task {
                                    Logger.debug("FoodCreator: Continue tapped with source: \(selectedNutritionSource)", category: Logger.food)
                                    
                                    // Handle nutrition label scanning - open camera but don't return early
                                    if selectedNutritionSource == .nutritionLabel && capturedImage == nil {
                                        Logger.debug("FoodCreator: Opening camera for nutrition label capture", category: Logger.food)
                                        await MainActor.run {
                                            showPhotosPicker = true
                                        }
                                        // Don't return early - user needs to capture photo first, then we'll progress
                                        Logger.debug("FoodCreator: Camera opened, waiting for photo capture before proceeding", category: Logger.food)
                                        return
                                    }
                                    
                                    // If we have a captured image for nutrition label, proceed normally
                                    if selectedNutritionSource == .nutritionLabel && capturedImage != nil {
                                        Logger.debug("FoodCreator: Photo already captured, proceeding to next step", category: Logger.food)
                                    }
                                    
                                    // Continue with processing
                                    Logger.debug("FoodCreator: Moving from foodDetails to servingAndNutrition step", category: Logger.food)
                                    
                                    // Always get AI serving size suggestion
                                    await suggestServingSizeFromAI()
                                    
                                    // Handle nutrition source logic
                                    switch selectedNutritionSource {
                                    case .nutritionLabel:
                                        if capturedImage != nil {
                                            await estimateWithAI() // Process label with Claude
                                            Logger.debug("FoodCreator: Processed nutrition label with AI", category: Logger.food)
                                        }
                                    case .webLookup:
                                        await estimateWithAI() // Search databases with Claude
                                        Logger.debug("FoodCreator: Searched databases with AI", category: Logger.food)
                                    case .manual:
                                        Logger.debug("FoodCreator: Manual entry selected, skipping AI estimation", category: Logger.food)
                                        // Skip AI estimation, user will enter manually
                                    }
                                    
                                    await MainActor.run {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            currentStep = .servingAndNutrition
                                        }
                                    }
                                }
                            }
                        )
                        
                    case .servingAndNutrition:
                        ServingNutritionStep(
                            selectedServingSize: $selectedServingSize,
                            showingServingSizePicker: $showingServingSizePicker,
                            servingSizeManager: servingSizeManager,
                            foodName: foodName,
                            brandName: brandName,
                            selectedNutritionSource: selectedNutritionSource,
                            capturedImage: capturedImage,
                            calories: $calories,
                            protein: $protein,
                            carbs: $carbs,
                            fat: $fat,
                            rawNutritionData: rawNutritionData,
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
                                    currentStep = .foodDetails
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
            .sheet(isPresented: $showPhotosPicker) {
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    CameraView(selectedImage: $capturedImage)
                } else {
                    PhotoLibraryFallbackView(selectedPhotoItem: $selectedPhotoItem)
                }
            }
        }
        .onAppear {
            Logger.debug("FoodCreator: View appeared with initialFoodName: '\(initialFoodName ?? "nil")'", category: Logger.food)
            if let initialName = initialFoodName {
                foodName = initialName
                selectedServingSize = ServingSize(from: MasterServingSize.grams100)
                Logger.debug("FoodCreator: Pre-filled food name, staying on foodDetails step", category: Logger.food)
            }
        }
        .onChange(of: selectedPhotoItem) { _, newValue in
            Logger.debug("FoodCreator: selectedPhotoItem changed, newValue: \(newValue != nil)", category: Logger.food)
            
            guard let newValue = newValue else {
                Logger.debug("FoodCreator: selectedPhotoItem is nil, clearing capturedImage", category: Logger.food)
                capturedImage = nil
                return
            }
            
            isProcessingPhoto = true
            Logger.debug("FoodCreator: Starting photo processing", category: Logger.food)
            
            Task {
                do {
                    Logger.debug("FoodCreator: Loading transferable data from PhotosPickerItem", category: Logger.food)
                    
                    if let data = try await newValue.loadTransferable(type: Data.self) {
                        Logger.debug("FoodCreator: Successfully loaded data, size: \(data.count) bytes", category: Logger.food)
                        
                        if let image = UIImage(data: data) {
                            Logger.debug("FoodCreator: Successfully created UIImage from data", category: Logger.food)
                            
                            await MainActor.run {
                                capturedImage = image
                                isProcessingPhoto = false
                                Logger.debug("FoodCreator: Image set, processing complete", category: Logger.food)
                                
                                // Auto-set nutrition source to nutrition label when photo is captured
                                selectedNutritionSource = .nutritionLabel
                                Logger.debug("FoodCreator: Auto-set nutrition source to nutrition label", category: Logger.food)
                                
                                // Auto-populate food name if empty and we have initial name
                                if foodName.isEmpty && initialFoodName?.isEmpty == false {
                                    foodName = initialFoodName ?? ""
                                    Logger.debug("FoodCreator: Pre-filled food name: \(foodName)", category: Logger.food)
                                }
                                
                                // Automatically progress to next step after photo is captured from fallback library
                                Logger.debug("FoodCreator: Auto-progressing to nutrition step after photo capture from library", category: Logger.food)
                                progressToNutritionStep()
                            }
                        } else {
                            Logger.error("FoodCreator: Failed to create UIImage from data", category: Logger.food)
                            await MainActor.run {
                                isProcessingPhoto = false
                            }
                        }
                    } else {
                        Logger.error("FoodCreator: Failed to load transferable data from PhotosPickerItem", category: Logger.food)
                        await MainActor.run {
                            isProcessingPhoto = false
                        }
                    }
                } catch {
                    Logger.error("FoodCreator: Error processing photo: \(error.localizedDescription)", category: Logger.food)
                    await MainActor.run {
                        isProcessingPhoto = false
                    }
                }
            }
        }
        .onChange(of: capturedImage) { _, newImage in
            Logger.debug("FoodCreator: capturedImage changed, newImage exists: \(newImage != nil)", category: Logger.food)
            
            // If we got an image from the camera and we're scanning nutrition label, progress to next step
            if newImage != nil && selectedNutritionSource == .nutritionLabel && currentStep == .foodDetails {
                Logger.debug("FoodCreator: Photo captured from camera, auto-progressing to nutrition step", category: Logger.food)
                progressToNutritionStep()
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
                selectedServingSize = ServingSize(from: MasterServingSize.grams100)
                isLoadingServingSuggestion = false
            }
            print("Error getting AI serving suggestion: \(error)")
        }
    }
    
    // MARK: - Helper Functions
    
    private func progressToNutritionStep() {
        Task {
            Logger.debug("FoodCreator: Moving from foodDetails to servingAndNutrition step after photo capture", category: Logger.food)
            
            // Always get AI serving size suggestion
            await suggestServingSizeFromAI()
            
            // Handle nutrition source logic
            switch selectedNutritionSource {
            case .nutritionLabel:
                if capturedImage != nil {
                    await estimateWithAI() // Process label with Claude
                    Logger.debug("FoodCreator: Processed nutrition label with AI", category: Logger.food)
                }
            case .webLookup:
                await estimateWithAI() // Search databases with Claude
                Logger.debug("FoodCreator: Searched databases with AI", category: Logger.food)
            case .manual:
                Logger.debug("FoodCreator: Manual entry selected, skipping AI estimation", category: Logger.food)
                // Keep existing nutrition values or defaults
            }
            
            await MainActor.run {
                currentStep = .servingAndNutrition
                showPhotosPicker = false // Ensure picker is dismissed
                Logger.debug("FoodCreator: Successfully moved to servingAndNutrition step", category: Logger.food)
            }
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
            let nutrition: NutritionInfo
            
            // Handle different nutrition sources
            if selectedNutritionSource == .nutritionLabel, let image = capturedImage {
                // Process nutrition label image with Claude (no web search)
                Logger.debug("FoodCreator: Processing nutrition label with Claude", category: Logger.food)
                let rawData = try await ClaudeAPIClient.shared.extractRawNutritionFromLabel(
                    image: image,
                    foodName: foodName,
                    brand: brandName.isEmpty ? nil : brandName
                )
                await MainActor.run {
                    rawNutritionData = rawData
                }
                nutrition = rawData.nutrition
            } else {
                // Search databases with Claude (with web search enabled)
                Logger.debug("FoodCreator: Searching databases with Claude", category: Logger.food)
                nutrition = try await ClaudeAPIClient.shared.estimateNutrition(
                    foodName: foodName,
                    brand: brandName.isEmpty ? nil : brandName,
                    userFeedback: userFeedback
                )
            }
            
            await MainActor.run {
                // Calculate values for the serving size
                let multiplier = selectedServingSize.gramsEquivalent / 100.0
                calories = String(Int(nutrition.calories * multiplier))
                protein = String(format: "%.1f", nutrition.protein * multiplier)
                carbs = String(format: "%.1f", nutrition.carbs * multiplier)
                fat = String(format: "%.1f", nutrition.fat * multiplier)
                
                isAIEstimated = true
                aiConfidence = selectedNutritionSource == .nutritionLabel ? 0.95 : 0.85 // Higher confidence for label
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
        Logger.debug("FoodCreator: saveFood called with name: '\(foodName)', brand: '\(brandName)'", category: Logger.food)
        
        guard let caloriesValue = Double(calories),
              let proteinValue = Double(protein),
              let carbsValue = Double(carbs),
              let fatValue = Double(fat) else {
            Logger.error("FoodCreator: Invalid nutrition values - calories: '\(calories)', protein: '\(protein)', carbs: '\(carbs)', fat: '\(fat)'", category: Logger.food)
            alertMessage = "Please enter valid numbers for all nutrition values"
            showingAlert = true
            return
        }
        
        Logger.debug("FoodCreator: Valid nutrition values confirmed, starting save process", category: Logger.food)
        isSaving = true
        
        Task {
            do {
                // Calculate per 100g values
                let multiplier = 100.0 / selectedServingSize.gramsEquivalent
                
                // Use Claude's serving suggestions if available from nutrition label, otherwise use selected serving size
                let finalServingName: String
                let finalServingGrams: Double
                
                if let rawData = rawNutritionData,
                   let claudeServingName = rawData.suggestedServingSize,
                   let claudeServingGrams = rawData.suggestedServingGrams {
                    finalServingName = claudeServingName
                    finalServingGrams = claudeServingGrams
                    Logger.debug("FoodCreator: Using Claude's serving suggestion: \(claudeServingName) (\(claudeServingGrams)g)", category: Logger.food)
                } else {
                    finalServingName = selectedServingSize.name
                    finalServingGrams = selectedServingSize.gramsEquivalent
                    Logger.debug("FoodCreator: Using selected serving size: \(finalServingName) (\(finalServingGrams)g)", category: Logger.food)
                }
                
                let foodItem = FoodItem(
                    name: foodName,
                    brand: brandName.isEmpty ? nil : brandName,
                    caloriesPer100g: caloriesValue * multiplier,
                    proteinPer100g: proteinValue * multiplier,
                    carbsPer100g: carbsValue * multiplier,
                    fatPer100g: fatValue * multiplier,
                    servingSizeName: finalServingName,
                    servingSizeGrams: finalServingGrams
                )
                
                Logger.debug("FoodCreator: Calling supabaseService.createFoodItem", category: Logger.food)
                try await supabaseService.createFoodItem(foodItem)
                
                Logger.debug("FoodCreator: Food item saved successfully", category: Logger.food)
                await MainActor.run {
                    // Call completion callback with the final food name
                    onFoodSaved?(foodName)
                    Logger.debug("FoodCreator: Calling onFoodSaved callback and dismissing", category: Logger.food)
                    dismiss()
                }
            } catch {
                Logger.error("FoodCreator: Failed to save food: \(error.localizedDescription)", category: Logger.food)
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

struct FoodDetailsStep: View {
    @Binding var foodName: String
    @Binding var brandName: String
    @Binding var selectedNutritionSource: NutritionSource
    @Binding var selectedPhotoItem: PhotosPickerItem?
    let capturedImage: UIImage?
    @Binding var isProcessingPhoto: Bool
    @Binding var isEstimating: Bool
    @Binding var isLoadingServingSuggestion: Bool
    @Binding var showPhotosPicker: Bool
    let onNext: () -> Void
    
    private var isValidFoodName: Bool {
        let trimmedName = foodName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedName.count >= 2 && !trimmedName.allSatisfy { $0.isWhitespace }
    }
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                Text("What are you eating?")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                // Food name and brand inputs
                VStack(spacing: 12) {
                    TextField("Enter food name", text: $foodName)
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
                }
                
                Text("Enter the full name for better accuracy (e.g., 'Honey Nut Cheerios' vs just 'Cereal')")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Nutrition source selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("How should we get nutrition info?")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    // Nutrition Label Option
                    nutritionSourceButton(
                        source: .nutritionLabel,
                        icon: "camera.viewfinder",
                        title: "Scan nutrition label",
                        subtitle: "Take a photo of the nutrition facts panel",
                        isSelected: selectedNutritionSource == .nutritionLabel
                    ) {
                        Logger.debug("FoodDetailsStep: Nutrition label source selected", category: Logger.food)
                        selectedNutritionSource = .nutritionLabel
                    }
                    
                    // Show captured image preview when nutrition label is selected and image exists
                    if selectedNutritionSource == .nutritionLabel, let photo = capturedImage {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Captured Nutrition Label")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            Image(uiImage: photo)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 120)
                                .cornerRadius(12)
                                .clipped()
                            
                            Button("Remove Photo") {
                                Logger.debug("FoodDetailsStep: Removing captured photo", category: Logger.food)
                                selectedPhotoItem = nil
                            }
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                        }
                        .padding(.leading, 24)
                    }
                    
                    // Web Lookup Option
                    nutritionSourceButton(
                        source: .webLookup,
                        icon: "magnifyingglass.circle",
                        title: "Auto-search databases",
                        subtitle: "We'll find nutrition info online automatically",
                        isSelected: selectedNutritionSource == .webLookup
                    ) {
                        Logger.debug("FoodDetailsStep: Web lookup source selected", category: Logger.food)
                        selectedNutritionSource = .webLookup
                    }
                    
                    // Manual Entry Option
                    nutritionSourceButton(
                        source: .manual,
                        icon: "square.and.pencil",
                        title: "Enter manually",
                        subtitle: "Type in the nutrition values yourself",
                        isSelected: selectedNutritionSource == .manual
                    ) {
                        Logger.debug("FoodDetailsStep: Manual entry source selected", category: Logger.food)
                        selectedNutritionSource = .manual
                    }
                }
                
                // Status indicators
                if isLoadingServingSuggestion {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Suggesting natural serving size...")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
                
                if isEstimating && selectedNutritionSource == .webLookup {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Looking up nutrition information...")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        Spacer()
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
            
            // Continue button
            Button(action: onNext) {
                HStack {
                    if isEstimating || isLoadingServingSuggestion {
                        ProgressView()
                            .scaleEffect(0.8)
                            .foregroundColor(.white)
                        Text(isLoadingServingSuggestion ? "Suggesting serving size..." : buttonLoadingText)
                            .font(.system(size: 16, weight: .semibold))
                    } else {
                        Text(buttonText)
                            .font(.system(size: 16, weight: .semibold))
                        Image(systemName: buttonIcon)
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
    
    private func nutritionSourceButton(
        source: NutritionSource,
        icon: String,
        title: String,
        subtitle: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Radio button indicator
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? Color.primary : Color(.systemGray3))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(isSelected ? Color.primary.opacity(0.05) : Color(.systemGray6))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.primary.opacity(0.3) : Color.clear, lineWidth: 1)
            )
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var buttonText: String {
        switch selectedNutritionSource {
        case .nutritionLabel:
            return capturedImage != nil ? "Process Label" : "Open Camera"
        case .webLookup:
            return "Search & Continue"
        case .manual:
            return "Continue"
        }
    }
    
    private var buttonIcon: String {
        switch selectedNutritionSource {
        case .nutritionLabel:
            return capturedImage != nil ? "camera.viewfinder" : "camera"
        case .webLookup:
            return "magnifyingglass.circle"
        case .manual:
            return "arrow.right"
        }
    }
    
    private var buttonLoadingText: String {
        switch selectedNutritionSource {
        case .nutritionLabel:
            return "Reading nutrition label..."
        case .webLookup:
            return "Searching databases..."
        case .manual:
            return "Preparing..."
        }
    }
}


struct ServingNutritionStep: View {
    @Binding var selectedServingSize: ServingSize
    @Binding var showingServingSizePicker: Bool
    @ObservedObject var servingSizeManager: ServingSizeManager
    let foodName: String
    let brandName: String
    let selectedNutritionSource: NutritionSource
    let capturedImage: UIImage?
    @Binding var calories: String
    @Binding var protein: String
    @Binding var carbs: String
    @Binding var fat: String
    let rawNutritionData: RawNutritionData?
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
            // Nutrition Source Info Card
            nutritionSourceInfoCard
            
            // Serving Size Card
            SmartServingCard(
                selectedServingSize: $selectedServingSize,
                showingServingSizePicker: $showingServingSizePicker,
                servingSizeManager: servingSizeManager,
                foodName: foodName
            )
            
            // Nutrition Display (adapted based on source)
            if selectedNutritionSource == .nutritionLabel, let rawData = rawNutritionData {
                // Two-column display for nutrition labels
                TwoColumnNutritionView(
                    nutritionDisplay: NutritionDisplayData(
                        rawNutrition: rawData,
                        servingSize: selectedServingSize
                    )
                )
            } else {
                // Traditional single nutrition card for other sources
                NutritionCard(
                    calories: $calories,
                    protein: $protein,
                    carbs: $carbs,
                    fat: $fat,
                    selectedServingSize: selectedServingSize,
                    isAIEstimated: isAIEstimated && selectedNutritionSource == .webLookup
                )
            }
            
            // Fix Panel (only show for web lookup)
            if showingFixPanel && selectedNutritionSource == .webLookup {
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
                                .font(.system(size: 16, weight: .semibold))
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 14, weight: .semibold))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background((!foodName.isEmpty && !calories.isEmpty && !isSaving) ? Color.primary : Color(.systemGray4))
                    .cornerRadius(12)
                }
                .disabled(foodName.isEmpty || calories.isEmpty || isSaving)
            }
        }
    }
    
    private var nutritionSourceInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: sourceIcon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(sourceColor)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(sourceTitle)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text(sourceDescription)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
            }
            
            // Show captured image for nutrition label
            if selectedNutritionSource == .nutritionLabel, let image = capturedImage {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Captured Label")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 80)
                        .cornerRadius(8)
                        .clipped()
                }
            }
        }
        .padding(16)
        .background(sourceBackgroundColor)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(sourceColor.opacity(0.2), lineWidth: 1)
        )
    }
    
    private var sourceIcon: String {
        switch selectedNutritionSource {
        case .nutritionLabel: return "camera.viewfinder"
        case .webLookup: return "magnifyingglass"
        case .manual: return "pencil"
        }
    }
    
    private var sourceTitle: String {
        switch selectedNutritionSource {
        case .nutritionLabel: return "From Nutrition Label"
        case .webLookup: return "From Web Search"
        case .manual: return "Manual Entry"
        }
    }
    
    private var sourceDescription: String {
        switch selectedNutritionSource {
        case .nutritionLabel: return "Values detected from your nutrition label photo"
        case .webLookup: return "Values found in nutrition databases"
        case .manual: return "You're entering all values manually"
        }
    }
    
    private var sourceColor: Color {
        switch selectedNutritionSource {
        case .nutritionLabel: return Color.green
        case .webLookup: return Color.blue
        case .manual: return Color.orange
        }
    }
    
    private var sourceBackgroundColor: Color {
        return sourceColor.opacity(0.05)
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
        // Return a few basic serving sizes for now
        return [
            ServingSize(from: MasterServingSize.grams100),
            ServingSize(from: MasterServingSize.grams50),
            ServingSize(from: MasterServingSize.portion)
        ]
    }
    
    private func getStandardServings() -> [ServingSize] {
        return [
            ServingSize(from: MasterServingSize.grams100),
            ServingSize(from: MasterServingSize.grams50),
            ServingSize(from: MasterServingSize.grams25),
            ServingSize(from: MasterServingSize.portion),
            ServingSize(from: MasterServingSize.piece)
        ]
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

// MARK: - Two-Column Nutrition Display
struct TwoColumnNutritionView: View {
    let nutritionDisplay: NutritionDisplayData
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("Nutrition Information")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            // Two-column layout
            HStack(spacing: 16) {
                // Left Column - Raw (100g)
                NutritionColumnView(
                    title: nutritionDisplay.rawNutrition.originalUnit,
                    subtitle: nutritionDisplay.rawNutrition.source,
                    nutrition: nutritionDisplay.rawNutrition.nutrition,
                    isRaw: true
                )
                
                // Right Column - Serving
                NutritionColumnView(
                    title: nutritionDisplay.servingSize.name,
                    subtitle: "Calculated portion",
                    nutrition: nutritionDisplay.servingNutrition,
                    isRaw: false
                )
            }
            
            // Confidence indicator
            if nutritionDisplay.rawNutrition.confidence < 0.8 {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.orange)
                        .font(.system(size: 12))
                    Text("Low confidence - please verify values")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct NutritionColumnView: View {
    let title: String
    let subtitle: String
    let nutrition: NutritionInfo
    let isRaw: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            // Column header
            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isRaw ? .primary : .blue)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(minHeight: 32, alignment: .center)
            }
            
            Divider()
            
            // Nutrition values
            VStack(spacing: 8) {
                NutritionRowView(title: "Calories", value: "\(Int(nutrition.calories))", unit: "cal", color: .primary)
                NutritionRowView(title: "Protein", value: String(format: "%.1f", nutrition.protein), unit: "g", color: .primary)
                NutritionRowView(title: "Carbs", value: String(format: "%.1f", nutrition.carbs), unit: "g", color: .primary)
                NutritionRowView(title: "Fat", value: String(format: "%.1f", nutrition.fat), unit: "g", color: .primary)
                
                if let fiber = nutrition.fiber, fiber > 0 {
                    NutritionRowView(title: "Fiber", value: String(format: "%.1f", fiber), unit: "g", color: .primary)
                }
                if let sugar = nutrition.sugar, sugar > 0 {
                    NutritionRowView(title: "Sugar", value: String(format: "%.1f", sugar), unit: "g", color: .primary)
                }
                if let sodium = nutrition.sodium, sodium > 0 {
                    NutritionRowView(title: "Sodium", value: String(format: "%.1f", sodium), unit: "mg", color: .primary)
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 280)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isRaw ? Color.primary.opacity(0.2) : Color.blue.opacity(0.3), lineWidth: 1)
        )
    }
}


// MARK: - Step Progress Indicator
struct StepProgressView: View {
    let currentStep: FoodCreatorView.CreationStep
    
    private var currentStepNumber: Int {
        switch currentStep {
        case .foodDetails: return 1
        case .servingAndNutrition: return 2
        }
    }
    
    private var stepTitle: String {
        switch currentStep {
        case .foodDetails: return "Food Details"
        case .servingAndNutrition: return "Nutrition"
        }
    }
    
    var body: some View {
        HStack {
            ForEach(1...2, id: \.self) { stepNumber in
                HStack(spacing: 4) {
                    Circle()
                        .fill(stepNumber <= currentStepNumber ? Color.blue : Color(.systemGray4))
                        .frame(width: 8, height: 8)
                    
                    if stepNumber < 2 {
                        Rectangle()
                            .fill(stepNumber < currentStepNumber ? Color.blue : Color(.systemGray4))
                            .frame(height: 2)
                    }
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("Step \(currentStepNumber) of 2")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text(stepTitle)
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Preview
#Preview("Food Creator") {
    FoodCreatorView()
}

#Preview("Meal Creator") {
    MealCreatorView()
}
