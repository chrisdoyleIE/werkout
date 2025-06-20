import SwiftUI

struct UnifiedNutritionView: View {
    @EnvironmentObject var macroGoalsManager: MacroGoalsManager
    @EnvironmentObject var mealPlanManager: MealPlanManager
    @EnvironmentObject var shoppingListManager: ShoppingListManager
    
    @State private var selectedDate = Date()
    @State private var showingGoalSettings = false
    @State private var showingMealPlanning = false
    @State private var selectedMealPlan: MealPlan?
    @State private var selectedMeal: Meal?
    
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
    
    var activeMealPlans: [MealPlan] {
        let now = Date()
        return mealPlanManager.mealPlans.filter { plan in
            plan.startDate <= now && plan.endDate >= now
        }.sorted { $0.startDate > $1.startDate }
    }
    
    var upcomingMealPlans: [MealPlan] {
        let now = Date()
        return mealPlanManager.mealPlans.filter { plan in
            plan.startDate > now
        }.sorted { $0.startDate < $1.startDate }
    }
    
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // AI Meal Plan Creation Section
                createMealPlanSection
                
                // Configure Daily Goals Section
                configureGoalsSection
                
                // Date Navigation
                dateNavigationSection
                
                // Today's Meal Plan Display
                if let mealPlan = todaysMealPlan {
                    todaysMealPlanSection(mealPlan)
                } else if activeMealPlans.isEmpty {
                    noMealPlanSection
                }
                
                // Active & Upcoming Plans Quick View (only show if no today's meal plan)
                if todaysMealPlan == nil && (!activeMealPlans.isEmpty || !upcomingMealPlans.isEmpty) {
                    mealPlansOverviewSection
                }
                
                Spacer(minLength: 100)
            }
            .padding()
        }
        .sheet(isPresented: $showingGoalSettings) {
            GoalSettingsView()
                .environmentObject(macroGoalsManager)
        }
        .sheet(isPresented: $showingMealPlanning) {
            MealPlanningView()
                .environmentObject(mealPlanManager)
                .environmentObject(macroGoalsManager)
        }
        .sheet(item: $selectedMealPlan) { mealPlan in
            MealPlanDetailView(mealPlan: mealPlan)
                .environmentObject(shoppingListManager)
        }
        .sheet(item: $selectedMeal) { meal in
            MealDetailView(meal: meal)
        }
    }
    
    // MARK: - Core Feature Sections
    
    private var createMealPlanSection: some View {
        VStack(spacing: 16) {
            Button(action: {
                showingMealPlanning = true
            }) {
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "wand.and.stars")
                            .font(.title2)
                            .foregroundColor(.white)
                        
                        Text("CREATE AI MEAL PLAN")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Image(systemName: "arrow.right")
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Text("Generate personalized meal plans with AI")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(20)
                .background(
                    LinearGradient(
                        colors: [Color.blue, Color.blue.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
                .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private var configureGoalsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Daily Nutrition Goals", systemImage: "target")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Configure") {
                    showingGoalSettings = true
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            
            // Current goals display
            HStack(spacing: 16) {
                goalCard("Calories", value: Int(macroGoalsManager.goals.calories), unit: "", color: .red)
                goalCard("Protein", value: Int(macroGoalsManager.goals.protein), unit: "g", color: .blue)
                goalCard("Carbs", value: Int(macroGoalsManager.goals.carbs), unit: "g", color: .orange)
                goalCard("Fat", value: Int(macroGoalsManager.goals.fat), unit: "g", color: .purple)
            }
        }
        .padding(20)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func goalCard(_ title: String, value: Int, unit: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("\(value)\(unit)")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var dateNavigationSection: some View {
        DateNavigationView(
            selectedDate: $selectedDate,
            onPrevious: previousDay,
            onNext: nextDay,
            showEditButton: false,
            onEditTap: {}
        )
    }
    
    private func todaysMealPlanSection(_ mealPlan: MealPlan) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Today's Meals", systemImage: "calendar.badge.clock")
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
                                    .onTapGesture {
                                        selectedMeal = meal
                                    }
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }
                
                // Quick action buttons
                HStack {
                    Button("View Full Plan") {
                        selectedMealPlan = mealPlan
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                    
                    Spacer()
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
                    showingMealPlanning = true
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
        }
        .padding(20)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    
    private var mealPlansOverviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Your Meal Plans", systemImage: "list.bullet.rectangle")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            // Active plans
            if !activeMealPlans.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Active (\(activeMealPlans.count))")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                    
                    ForEach(activeMealPlans.prefix(2)) { plan in
                        compactMealPlanRow(plan, isActive: true)
                    }
                }
            }
            
            // Upcoming plans
            if !upcomingMealPlans.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Upcoming (\(upcomingMealPlans.count))")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                    
                    ForEach(upcomingMealPlans.prefix(2)) { plan in
                        compactMealPlanRow(plan, isActive: false)
                    }
                }
            }
        }
        .padding(20)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Helper Views
    
    private func plannedMealCard(_ meal: Meal) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(meal.type.icon)
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
    
    private func compactMealPlanRow(_ plan: MealPlan, isActive: Bool) -> some View {
        Button(action: {
            selectedMealPlan = plan
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(plan.generatedMealPlan?.title ?? "Custom Plan")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    Text(plan.dateRange)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    if plan.isAIGenerated {
                        Image(systemName: "wand.and.stars")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    
                    if isActive {
                        Text("ACTIVE")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green)
                            .cornerRadius(4)
                    }
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color.white)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Helper Functions
    
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
    UnifiedNutritionView()
        .environmentObject(MacroGoalsManager())
        .environmentObject(MealPlanManager())
        .environmentObject(ShoppingListManager())
}
