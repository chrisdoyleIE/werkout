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
}

class MealPlanManager: ObservableObject {
    @Published var mealPlans: [MealPlan] = []
    @Published var isGeneratingMealPlan = false
    @Published var generationError: Error?
    
    private let userDefaults = UserDefaults.standard
    private let mealPlansKey = "SavedMealPlans"
    private let claudeClient = ClaudeAPIClient.shared
    
    init() {
        loadMealPlans()
    }
    
    func saveMealPlan(_ mealPlan: MealPlan) {
        mealPlans.append(mealPlan)
        saveMealPlans()
    }
    
    func deleteMealPlan(_ mealPlan: MealPlan) {
        mealPlans.removeAll { $0.id == mealPlan.id }
        saveMealPlans()
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
            
            saveMealPlan(mealPlan)
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
    
    private func saveMealPlans() {
        if let encoded = try? JSONEncoder().encode(mealPlans) {
            userDefaults.set(encoded, forKey: mealPlansKey)
        }
    }
    
    private func loadMealPlans() {
        if let data = userDefaults.data(forKey: mealPlansKey),
           let decoded = try? JSONDecoder().decode([MealPlan].self, from: data) {
            mealPlans = decoded.sorted { $0.createdAt > $1.createdAt }
        }
    }
}

class MacroGoalsManager: ObservableObject {
    @Published var goals: MacroGoals = .default
    
    private let userDefaults = UserDefaults.standard
    private let goalsKey = "MacroGoals"
    
    init() {
        loadGoals()
    }
    
    func updateGoals(calories: Double, protein: Double, carbs: Double, fat: Double) {
        goals = MacroGoals(calories: calories, protein: protein, carbs: carbs, fat: fat)
        saveGoals()
    }
    
    private func saveGoals() {
        let goalsData = [
            "calories": goals.calories,
            "protein": goals.protein,
            "carbs": goals.carbs,
            "fat": goals.fat
        ]
        userDefaults.set(goalsData, forKey: goalsKey)
    }
    
    private func loadGoals() {
        if let goalsData = userDefaults.dictionary(forKey: goalsKey) as? [String: Double] {
            goals = MacroGoals(
                calories: goalsData["calories"] ?? MacroGoals.default.calories,
                protein: goalsData["protein"] ?? MacroGoals.default.protein,
                carbs: goalsData["carbs"] ?? MacroGoals.default.carbs,
                fat: goalsData["fat"] ?? MacroGoals.default.fat
            )
        }
    }
}