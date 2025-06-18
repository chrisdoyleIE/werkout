import Foundation

struct MacroData {
    let caloriesAchieved: Bool
    let proteinAchieved: Bool
    let carbsAchieved: Bool
    let fatAchieved: Bool
    
    static let empty = MacroData(
        caloriesAchieved: false,
        proteinAchieved: false,
        carbsAchieved: false,
        fatAchieved: false
    )
    
    static let sample = MacroData(
        caloriesAchieved: true,
        proteinAchieved: true,
        carbsAchieved: false,
        fatAchieved: true
    )
    
    static let allAchieved = MacroData(
        caloriesAchieved: true,
        proteinAchieved: true,
        carbsAchieved: true,
        fatAchieved: true
    )
    
    static let caloriesOnly = MacroData(
        caloriesAchieved: true,
        proteinAchieved: false,
        carbsAchieved: false,
        fatAchieved: false
    )
}

struct MacroGoals {
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    
    static let `default` = MacroGoals(
        calories: 2000,
        protein: 150,
        carbs: 200,
        fat: 80
    )
}

struct MealPlan: Identifiable, Codable {
    let id: UUID
    let startDate: Date
    let numberOfDays: Int
    let mealPlanText: String
    let createdAt: Date
    let isAIGenerated: Bool
    let generatedMealPlan: GeneratedMealPlan?
    
    var endDate: Date {
        Calendar.current.date(byAdding: .day, value: numberOfDays - 1, to: startDate) ?? startDate
    }
    
    var dateRange: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        
        if numberOfDays == 1 {
            return formatter.string(from: startDate)
        } else {
            return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
        }
    }
    
    // Convenience initializer for manual meal plans
    init(startDate: Date, numberOfDays: Int, mealPlanText: String, createdAt: Date) {
        self.id = UUID()
        self.startDate = startDate
        self.numberOfDays = numberOfDays
        self.mealPlanText = mealPlanText
        self.createdAt = createdAt
        self.isAIGenerated = false
        self.generatedMealPlan = nil
    }
    
    // Convenience initializer for AI-generated meal plans
    init(startDate: Date, numberOfDays: Int, userPreferences: String, generatedMealPlan: GeneratedMealPlan, createdAt: Date) {
        self.id = UUID()
        self.startDate = startDate
        self.numberOfDays = numberOfDays
        self.mealPlanText = userPreferences
        self.createdAt = createdAt
        self.isAIGenerated = true
        self.generatedMealPlan = generatedMealPlan
    }
    
    // Database initializer
    init(id: UUID, startDate: Date, numberOfDays: Int, mealPlanText: String, createdAt: Date, isAIGenerated: Bool, generatedMealPlan: GeneratedMealPlan?) {
        self.id = id
        self.startDate = startDate
        self.numberOfDays = numberOfDays
        self.mealPlanText = mealPlanText
        self.createdAt = createdAt
        self.isAIGenerated = isAIGenerated
        self.generatedMealPlan = generatedMealPlan
    }
}

class MealPlanManager: ObservableObject {
    @Published var mealPlans: [MealPlan] = []
    @Published var isGeneratingMealPlan = false
    @Published var generationError: Error?
    @Published var isLoading = false
    
    private let supabaseService = SupabaseService.shared
    private let claudeClient = ClaudeAPIClient.shared
    
    init() {
        Task {
            await loadMealPlans()
        }
    }
    
    @MainActor
    func saveMealPlan(_ mealPlan: MealPlan) async {
        do {
            try await supabaseService.saveMealPlan(mealPlan)
            if !mealPlans.contains(where: { $0.id == mealPlan.id }) {
                mealPlans.append(mealPlan)
            }
        } catch {
            generationError = error
        }
    }
    
    @MainActor
    func deleteMealPlan(_ mealPlan: MealPlan) async {
        do {
            try await supabaseService.deleteMealPlan(mealPlan)
            mealPlans.removeAll { $0.id == mealPlan.id }
        } catch {
            generationError = error
        }
    }
    
    @MainActor
    func generateAIMealPlan(
        startDate: Date,
        numberOfDays: Int,
        macroGoals: MacroGoals?,
        configuration: MealPlanningConfiguration,
        measurementUnit: MeasurementUnit = .metric,
        temperatureUnit: TemperatureUnit = .celsius
    ) async throws -> MealPlan {
        isGeneratingMealPlan = true
        generationError = nil
        
        do {
            let generatedMealPlan = try await claudeClient.generateMealPlan(
                numberOfDays: numberOfDays,
                startDate: startDate,
                macroGoals: macroGoals,
                configuration: configuration,
                measurementUnit: measurementUnit,
                temperatureUnit: temperatureUnit
            )
            
            let mealPlan = MealPlan(
                startDate: startDate,
                numberOfDays: numberOfDays,
                userPreferences: configuration.additionalNotes.isEmpty ? "AI Generated Meal Plan" : configuration.additionalNotes,
                generatedMealPlan: generatedMealPlan,
                createdAt: Date()
            )
            
            await saveMealPlan(mealPlan)
            isGeneratingMealPlan = false
            return mealPlan
            
        } catch {
            isGeneratingMealPlan = false
            generationError = error
            throw error
        }
    }
    
    @MainActor
    func getQuickMealSuggestion(preferences: String) async throws -> String {
        return try await claudeClient.generateQuickMealSuggestion(preferences: preferences)
    }
    
    @MainActor
    private func loadMealPlans() async {
        isLoading = true
        do {
            mealPlans = try await supabaseService.getMealPlans()
        } catch {
            generationError = error
        }
        isLoading = false
    }
    
    @MainActor
    func refreshMealPlans() async {
        await loadMealPlans()
    }
}

class MacroGoalsManager: ObservableObject {
    @Published var goals: MacroGoals = .default
    @Published var isLoading = false
    @Published var error: Error?
    
    private let supabaseService = SupabaseService.shared
    
    init() {
        Task {
            await loadGoals()
        }
    }
    
    @MainActor
    func updateGoals(calories: Double, protein: Double, carbs: Double, fat: Double) async {
        goals = MacroGoals(calories: calories, protein: protein, carbs: carbs, fat: fat)
        await saveGoals()
    }
    
    @MainActor
    private func saveGoals() async {
        do {
            try await supabaseService.saveMacroGoals(goals)
        } catch {
            self.error = error
        }
    }
    
    @MainActor
    private func loadGoals() async {
        isLoading = true
        do {
            if let loadedGoals = try await supabaseService.getMacroGoals() {
                goals = loadedGoals
            }
        } catch {
            self.error = error
        }
        isLoading = false
    }
    
    @MainActor
    func refreshGoals() async {
        await loadGoals()
    }
}