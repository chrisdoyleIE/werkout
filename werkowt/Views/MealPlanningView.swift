import SwiftUI

struct MealPlanningView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var mealPlanManager: MealPlanManager
    @EnvironmentObject var macroGoalsManager: MacroGoalsManager
    @StateObject private var settingsManager = SettingsManager()
    
    // Date Selection
    @State private var startDate = Date()
    @State private var endDate = Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date()
    
    // Meal Configuration
    @State private var selectedMealTypes: Set<MealType> = [.breakfast, .lunch, .dinner]
    @State private var householdSize: Int = 1
    @State private var maxPrepTime: PrepTime = .medium
    @State private var cookingFrequency: CookingFrequency = .everyOtherDay
    
    // Dietary Preferences
    @State private var dietType: DietType = .omnivore
    @State private var skillLevel: SkillLevel = .intermediate
    @State private var selectedAllergens: Set<String> = []
    
    // Budget & Additional
    @State private var budgetLevel: BudgetLevel = .medium
    @State private var shopType: ShopType = .supermarket
    @State private var additionalNotes: String = ""
    
    // Adjusted Macro Goals for Generated Meals
    @State private var adjustedCalories: Double = 0
    @State private var adjustedProtein: Double = 0
    @State private var adjustedCarbs: Double = 0
    @State private var adjustedFat: Double = 0
    
    // UI State
    @State private var showingSuccess = false
    @State private var showingAlert = false
    @State private var errorMessage = ""
    @State private var generatedMealPlan: MealPlan?
    
    private let allergenOptions = ["Nuts", "Dairy", "Gluten", "Shellfish", "Eggs", "Soy", "Fish"]
    
    var numberOfDays: Int {
        let days = Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
        return max(1, days + 1)
    }
    
    var isButtonDisabled: Bool {
        mealPlanManager.isGeneratingMealPlan
    }
    
    // Calculate proportional macros based on selected meal types
    private func calculateAdjustedMacros() {
        let totalMealTypes = MealType.allCases.count
        let selectedCount = selectedMealTypes.count
        let proportion = Double(selectedCount) / Double(totalMealTypes)
        
        adjustedCalories = macroGoalsManager.goals.calories * proportion
        adjustedProtein = macroGoalsManager.goals.protein * proportion
        adjustedCarbs = macroGoalsManager.goals.carbs * proportion
        adjustedFat = macroGoalsManager.goals.fat * proportion
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    headerSection
                    
                    // Daily Macro Goals (Read-only)
                    macroGoalsCard
                    
                    // Date Selection - moved to top
                    dateSelectionCard
                    
                    // Meal Configuration
                    mealConfigurationCard
                    
                    // Dietary Preferences
                    dietaryPreferencesCard
                    
                    // Budget & Additional Notes
                    budgetAndNotesCard
                    
                    Spacer(minLength: 100)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                generateButton
                    .padding()
                    .background(.ultraThinMaterial)
            }
            .alert("Meal Plan Generated!", isPresented: $showingSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your AI-generated meal plan has been saved successfully.")
            }
            .alert("Error", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                calculateAdjustedMacros()
            }
            .onChange(of: selectedMealTypes) { _ in
                calculateAdjustedMacros()
            }
        }
        .overlay(
            Group {
                if mealPlanManager.isGeneratingMealPlan {
                    MealPlanLoadingView()
                }
            }
        )
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            Text("MEAL PLANNING")
                .font(.largeTitle)
                .fontWeight(.black)
            
            Text("Hundred analyzes your preferences, dietary needs, and lifestyle to create  meal plans with shopping lists tailored to you.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
        }
    }
    
    private var macroGoalsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Daily Macro Goals", systemImage: "target")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 0) {
                macroItem("Cal", value: Int(macroGoalsManager.goals.calories), color: .blue)
                macroItem("Protein", value: Int(macroGoalsManager.goals.protein), color: .green, unit: "g")
                macroItem("Carbs", value: Int(macroGoalsManager.goals.carbs), color: .orange, unit: "g")
                macroItem("Fat", value: Int(macroGoalsManager.goals.fat), color: .red, unit: "g")
            }
        }
        .padding(20)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func macroItem(_ label: String, value: Int, color: Color, unit: String = "") -> some View {
        VStack(spacing: 4) {
            Text("\(value)\(unit)")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var adjustedMacroGoalsWidget: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "target")
                    .foregroundColor(.orange)
                    .font(.system(size: 16))
                Text("Target Macros")
                    .fontWeight(.medium)
                Spacer()
                Text("Adjust as needed")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color(.systemGray5))
                    .cornerRadius(8)
            }
            
            Text("Macro targets for the \(selectedMealTypes.count) selected meal\(selectedMealTypes.count > 1 ? "s" : "") only")
                .font(.caption)
                .foregroundColor(.secondary)
            
            VStack(spacing: 12) {
                HStack(spacing: 16) {
                    adjustableMacroItem("Calories", value: $adjustedCalories, color: .red, range: 100...4000, step: 50)
                    adjustableMacroItem("Protein", value: $adjustedProtein, color: .blue, range: 10...300, step: 5, unit: "g")
                }
                
                HStack(spacing: 16) {
                    adjustableMacroItem("Carbs", value: $adjustedCarbs, color: .orange, range: 20...400, step: 10, unit: "g")
                    adjustableMacroItem("Fat", value: $adjustedFat, color: .purple, range: 10...200, step: 5, unit: "g")
                }
            }
        }
        .padding(16)
        .background(Color.orange.opacity(0.05))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.orange.opacity(0.2), lineWidth: 1)
        )
    }
    
    private func adjustableMacroItem(_ label: String, value: Binding<Double>, color: Color, range: ClosedRange<Double>, step: Double, unit: String = "") -> some View {
        VStack(spacing: 8) {
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(color)
            
            HStack(spacing: 8) {
                Button(action: {
                    if value.wrappedValue > range.lowerBound {
                        value.wrappedValue = max(range.lowerBound, value.wrappedValue - step)
                    }
                }) {
                    Image(systemName: "minus.circle.fill")
                        .foregroundColor(color.opacity(0.7))
                        .font(.title3)
                }
                .disabled(value.wrappedValue <= range.lowerBound)
                
                Text("\(Int(value.wrappedValue))\(unit)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
                    .frame(minWidth: 50)
                
                Button(action: {
                    if value.wrappedValue < range.upperBound {
                        value.wrappedValue = min(range.upperBound, value.wrappedValue + step)
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(color.opacity(0.7))
                        .font(.title3)
                }
                .disabled(value.wrappedValue >= range.upperBound)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private var dateSelectionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Meal Plan Duration", systemImage: "calendar")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 16) {
                DatePicker("", selection: $startDate, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .frame(maxWidth: .infinity)
                
                Image(systemName: "arrow.right")
                    .font(.title3)
                    .foregroundColor(.secondary)
                
                DatePicker("", selection: $endDate, in: startDate..., displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .frame(maxWidth: .infinity)
            }
            
            Text("\(numberOfDays) day\(numberOfDays > 1 ? "s" : "") of meal planning")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(20)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var mealConfigurationCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Meal Configuration", systemImage: "fork.knife")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 16) {
                // Meal type selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("Select meals to generate")
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(MealType.allCases, id: \.self) { mealType in
                            Button(action: {
                                if selectedMealTypes.contains(mealType) {
                                    // Don't allow removing the last meal type
                                    if selectedMealTypes.count > 1 {
                                        selectedMealTypes.remove(mealType)
                                    }
                                } else {
                                    selectedMealTypes.insert(mealType)
                                }
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: mealType.icon)
                                        .font(.system(size: 16, weight: .medium))
                                    Text(mealType.displayName)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(
                                    selectedMealTypes.contains(mealType) ? .white : .primary
                                )
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    selectedMealTypes.contains(mealType) ?
                                    Color.blue : Color(.systemGray5)
                                )
                                .cornerRadius(8)
                            }
                        }
                    }
                    
                    Text("\(selectedMealTypes.count) meal\(selectedMealTypes.count > 1 ? "s" : "") selected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                // Adjusted Macro Goals for Generated Meals
                adjustedMacroGoalsWidget
                
                Divider()
                
                // Household size
                VStack(alignment: .leading, spacing: 8) {
                    Text("Household size")
                    
                    HStack(spacing: 16) {
                        Button(action: {
                            if householdSize > 1 {
                                householdSize -= 1
                            }
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(householdSize > 1 ? .blue : .gray.opacity(0.5))
                                .font(.title2)
                        }
                        .disabled(householdSize <= 1)
                        
                        VStack(spacing: 2) {
                            Text("\(householdSize)")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                            
                            Text(householdSize == 1 ? "person" : "people")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(minWidth: 80)
                        
                        Button(action: {
                            if householdSize < 8 {
                                householdSize += 1
                            }
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(householdSize < 8 ? .blue : .gray.opacity(0.5))
                                .font(.title2)
                        }
                        .disabled(householdSize >= 8)
                        
                        Spacer()
                    }
                }
                
                Divider()
                
                // Max prep time
                VStack(alignment: .leading, spacing: 8) {
                    Text("Maximum prep time per meal")
                    Picker("Prep time", selection: $maxPrepTime) {
                        ForEach(PrepTime.allCases, id: \.self) { time in
                            Text(time.rawValue).tag(time)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Divider()
                
                // Cooking frequency
                VStack(alignment: .leading, spacing: 12) {
                    Text("How often do you want to cook?")
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(CookingFrequency.allCases, id: \.self) { frequency in
                            Button(action: {
                                cookingFrequency = frequency
                            }) {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text(frequency.rawValue)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        Spacer()
                                        if cookingFrequency == frequency {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.blue)
                                                .font(.system(size: 16))
                                        }
                                    }
                                    
                                    Text(frequency.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.leading)
                                        .lineLimit(2)
                                }
                                .foregroundColor(
                                    cookingFrequency == frequency ? .primary : .primary
                                )
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(12)
                                .background(
                                    cookingFrequency == frequency ?
                                    Color.blue.opacity(0.1) : Color(.systemGray5)
                                )
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(
                                            cookingFrequency == frequency ? Color.blue.opacity(0.3) : Color.clear,
                                            lineWidth: 1
                                        )
                                )
                            }
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var dietaryPreferencesCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Dietary Preferences", systemImage: "leaf")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 16) {
                // Diet type
                VStack(alignment: .leading, spacing: 12) {
                    Text("Diet type")
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(DietType.allCases, id: \.self) { diet in
                            Button(action: {
                                dietType = diet
                            }) {
                                VStack(spacing: 6) {
                                    Text(dietTypeIcon(diet))
                                        .font(.title2)
                                    
                                    Text(diet.rawValue)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .multilineTextAlignment(.center)
                                        .lineLimit(1)
                                }
                                .foregroundColor(
                                    dietType == diet ? .white : .primary
                                )
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    dietType == diet ?
                                    Color.green : Color(.systemGray5)
                                )
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(
                                            dietType == diet ? Color.green.opacity(0.3) : Color.clear,
                                            lineWidth: 1
                                        )
                                )
                            }
                        }
                    }
                    
                    Text(dietTypeDescription(dietType))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Divider()
                
                // Cooking skill
                VStack(alignment: .leading, spacing: 8) {
                    Text("Cooking skill level")
                    Picker("Skill level", selection: $skillLevel) {
                        ForEach(SkillLevel.allCases, id: \.self) { skill in
                            Text(skill.rawValue).tag(skill)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Divider()
                
                // Allergens
                VStack(alignment: .leading, spacing: 12) {
                    Text("Allergens to avoid")
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 8) {
                        ForEach(allergenOptions, id: \.self) { allergen in
                            Button(action: {
                                if selectedAllergens.contains(allergen) {
                                    selectedAllergens.remove(allergen)
                                } else {
                                    selectedAllergens.insert(allergen)
                                }
                            }) {
                                Text(allergen)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        selectedAllergens.contains(allergen) ?
                                        Color.red.opacity(0.9) : Color(.systemGray5)
                                    )
                                    .foregroundColor(
                                        selectedAllergens.contains(allergen) ? .white : .primary
                                    )
                                    .cornerRadius(20)
                            }
                        }
                    }
                    
                    if selectedAllergens.isEmpty {
                        Text("No allergens selected")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(20)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var budgetAndNotesCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Budget & Shopping", systemImage: "cart")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 16) {
                // Budget level
                VStack(alignment: .leading, spacing: 8) {
                    Text("Budget level")
                    Picker("Budget", selection: $budgetLevel) {
                        ForEach(BudgetLevel.allCases, id: \.self) { budget in
                            Text(budget.rawValue).tag(budget)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Divider()
                
                // Shop type
                VStack(alignment: .leading, spacing: 8) {
                    Text("Shopping location")
                    Picker("Shop type", selection: $shopType) {
                        ForEach(ShopType.allCases, id: \.self) { shop in
                            Text(shop.rawValue).tag(shop)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Divider()
                
                // Additional preferences
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "text.quote")
                            .foregroundColor(.blue)
                            .font(.system(size: 16))
                        Text("Additional Preferences")
                            .fontWeight(.medium)
                        Spacer()
                        Text("Optional")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color(.systemGray5))
                            .cornerRadius(8)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tell us more about what you love:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextField("", text: $additionalNotes, axis: .vertical)
                            .textFieldStyle(.plain)
                            .padding(12)
                            .background(Color(.systemBackground))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                            .lineLimit(3...6)
                        
                        if additionalNotes.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Examples:")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                
                                LazyVGrid(columns: [
                                    GridItem(.flexible()),
                                    GridItem(.flexible())
                                ], spacing: 6) {
                                    ForEach(["🌶️ Love spicy food", "🐟 No seafood", "☕ Quick breakfasts", "🥗 Fresh salads", "🍝 Comfort food", "🌱 Plant-forward"], id: \.self) { example in
                                        Text(example)
                                            .font(.caption)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color(.systemGray6))
                                            .cornerRadius(12)
                                            .onTapGesture {
                                                let cleanExample = example.replacingOccurrences(of: "^[🌶️🐟☕🥗🍝🌱]\\s*", with: "", options: .regularExpression)
                                                if additionalNotes.isEmpty {
                                                    additionalNotes = cleanExample
                                                } else {
                                                    additionalNotes += ", " + cleanExample.lowercased()
                                                }
                                            }
                                    }
                                }
                            }
                            .padding(.top, 4)
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var generateButton: some View {
        Button(action: generateMealPlan) {
            HStack {
                if mealPlanManager.isGeneratingMealPlan {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "wand.and.stars")
                        .font(.title3)
                }
                
                Text("GENERATE MEAL PLAN")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [Color.blue, Color.blue.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
            .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .disabled(isButtonDisabled)
        .opacity(isButtonDisabled ? 0.6 : 1.0)
    }
    
    private func generateMealPlan() {
        let configuration = MealPlanningConfiguration(
            selectedMealTypes: selectedMealTypes,
            householdSize: householdSize,
            maxPrepTime: maxPrepTime,
            cookingFrequency: cookingFrequency,
            dietType: dietType,
            skillLevel: skillLevel,
            budgetLevel: budgetLevel,
            shopType: shopType,
            selectedAllergens: selectedAllergens,
            additionalNotes: additionalNotes
        )
        
        Task {
            do {
                // Create adjusted macro goals for generation
                let adjustedMacroGoals = MacroGoals(
                    calories: adjustedCalories,
                    protein: adjustedProtein,
                    carbs: adjustedCarbs,
                    fat: adjustedFat
                )
                
                let _ = try await mealPlanManager.generateAIMealPlan(
                    startDate: startDate,
                    numberOfDays: numberOfDays,
                    macroGoals: adjustedMacroGoals,
                    configuration: configuration,
                    measurementUnit: settingsManager.measurementUnit,
                    temperatureUnit: settingsManager.temperatureUnit
                )
                
                await MainActor.run {
                    showingSuccess = true
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showingAlert = true
                }
            }
        }
    }
    
    private func dietTypeIcon(_ diet: DietType) -> String {
        switch diet {
        case .omnivore: return "🍽️"
        case .vegetarian: return "🥗"
        case .vegan: return "🌱"
        case .keto: return "🥑"
        case .mediterranean: return "🫒"
        case .paleo: return "🥩"
        }
    }
    
    private func dietTypeDescription(_ diet: DietType) -> String {
        switch diet {
        case .omnivore: return "Includes all food groups - meat, dairy, vegetables, grains"
        case .vegetarian: return "No meat or fish, but includes dairy and eggs"
        case .vegan: return "Plant-based only - no animal products"
        case .keto: return "High fat, very low carb for ketosis"
        case .mediterranean: return "Focus on olive oil, fish, vegetables, and whole grains"
        case .paleo: return "Whole foods only - no processed foods, grains, or legumes"
        }
    }
}

#Preview {
    MealPlanningView()
        .environmentObject(MealPlanManager())
        .environmentObject(MacroGoalsManager())
}
