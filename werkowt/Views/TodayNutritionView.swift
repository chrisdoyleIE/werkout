import SwiftUI

struct TodayNutritionView: View {
    @EnvironmentObject var macroGoalsManager: MacroGoalsManager
    @EnvironmentObject var mealPlanManager: MealPlanManager
    
    @State private var selectedDate = Date()
    @State private var caloriesConsumed: Double = 2200
    @State private var proteinConsumed: Double = 165
    @State private var carbsConsumed: Double = 120
    @State private var fatConsumed: Double = 30
    
    @State private var showingGoalSettings = false
    
    private let calendar = Calendar.current
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE - MMMM d"
        return formatter
    }()
    
    var todaysMealPlan: MealPlan? {
        mealPlanManager.mealPlans.first { plan in
            plan.startDate <= selectedDate && plan.endDate >= selectedDate
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Date Navigation
                dateNavigationSection
                
                // Today's Meal Plan Overview
                if let mealPlan = todaysMealPlan {
                    todaysMealPlanSection(mealPlan)
                } else {
                    noMealPlanSection
                }
                
                // Macro Progress
                macroProgressSection
                
                // Quick Actions
                quickActionsSection
                
                Spacer(minLength: 100)
            }
            .padding()
        }
        .sheet(isPresented: $showingGoalSettings) {
            GoalSettingsView()
                .environmentObject(macroGoalsManager)
        }
    }
    
    private var dateNavigationSection: some View {
        DateNavigationView(
            selectedDate: $selectedDate,
            onPreviousDay: previousDay,
            onNextDay: nextDay,
            showEditButton: true,
            onEditTap: {
                showingGoalSettings = true
            }
        )
    }
    
    private func todaysMealPlanSection(_ mealPlan: MealPlan) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Today's Meal Plan", systemImage: "calendar.badge.clock")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if mealPlan.isAIGenerated {
                    HStack(spacing: 4) {
                        Image(systemName: "wand.and.stars")
                            .font(.caption)
                        Text("AI")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(8)
                }
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text(mealPlan.generatedMealPlan?.title ?? "Custom Meal Plan")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                if let description = mealPlan.generatedMealPlan?.description {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Today's planned meals
                if let generatedPlan = mealPlan.generatedMealPlan,
                   let todaysDate = getTodaysDailyMeal(from: generatedPlan) {
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(todaysDate.meals, id: \.name) { meal in
                                plannedMealCard(meal)
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }
                
                // Quick action button
                HStack {
                    Button("View Full Plan") {
                        // Navigate to meal plan detail
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                    
                    Spacer()
                    
                    Button("Adjust Plan") {
                        // Quick edit action
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                }
            }
        }
        .padding(20)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var noMealPlanSection: some View {
        VStack(spacing: 16) {
            HStack {
                Label("No Meal Plan", systemImage: "calendar.badge.exclamationmark")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("No meal plan found for today")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Button("Create Meal Plan") {
                    // Navigate to meal planning
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
        }
        .padding(20)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var macroProgressSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Daily Progress", systemImage: "chart.bar.fill")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                MacroProgressBar(
                    title: "Calories",
                    current: caloriesConsumed,
                    target: macroGoalsManager.goals.calories,
                    unit: "",
                    color: .red
                )
                
                MacroProgressBar(
                    title: "Protein",
                    current: proteinConsumed,
                    target: macroGoalsManager.goals.protein,
                    unit: "g",
                    color: .blue
                )
                
                MacroProgressBar(
                    title: "Carbs",
                    current: carbsConsumed,
                    target: macroGoalsManager.goals.carbs,
                    unit: "g",
                    color: .orange
                )
                
                MacroProgressBar(
                    title: "Fat",
                    current: fatConsumed,
                    target: macroGoalsManager.goals.fat,
                    unit: "g",
                    color: .purple
                )
            }
        }
        .padding(20)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var quickActionsSection: some View {
        VStack(spacing: 12) {
            // Primary Action - Log Food
            Button(action: {
                // Add food action
            }) {
                HStack {
                    Image(systemName: "plus.circle")
                        .font(.title3)
                    Text("LOG FOOD")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
            }
        }
    }
    
    private func plannedMealCard(_ meal: Meal) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: meal.type.icon)
                    .foregroundColor(.blue)
                    .font(.caption)
                
                Text(meal.type.displayName)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                
                Spacer()
            }
            
            Text(meal.name)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(2)
            
            if let nutrition = meal.nutrition {
                Text("\(Int(nutrition.calories)) cal")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .frame(width: 140)
        .background(Color.white)
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private func getTodaysDailyMeal(from plan: GeneratedMealPlan) -> DailyMeal? {
        let dayOfPlan = calendar.dateComponents([.day], from: todaysMealPlan?.startDate ?? Date(), to: selectedDate).day ?? 0
        return plan.dailyMeals.first { $0.day == dayOfPlan + 1 }
    }
    
    private func previousDay() {
        selectedDate = calendar.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
    }
    
    private func nextDay() {
        selectedDate = calendar.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
    }
}


#Preview {
    TodayNutritionView()
        .environmentObject(MacroGoalsManager())
        .environmentObject(MealPlanManager())
}