import SwiftUI

struct MealPlanningDashboardView: View {
    @EnvironmentObject var macroGoalsManager: MacroGoalsManager
    @EnvironmentObject var mealPlanManager: MealPlanManager
    @EnvironmentObject var shoppingListManager: ShoppingListManager
    
    @State private var selectedWeekStart = Date()
    @State private var showingMealPlanning = false
    @State private var showingFoodLibrary = false
    @State private var showingShoppingDashboard = false
    @State private var selectedMealPlan: MealPlan?
    @State private var selectedMeal: Meal?
    
    private let calendar = Calendar.current
    
    // Get current week's Monday
    private var currentWeekStart: Date {
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today)
        let daysFromMonday = (weekday == 1) ? 6 : weekday - 2
        return calendar.date(byAdding: .day, value: -daysFromMonday, to: today) ?? today
    }
    
    // Get week days for the selected week
    private var weekDays: [Date] {
        (0..<7).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: selectedWeekStart)
        }
    }
    
    // Find active meal plan for the current week
    private var activeWeekMealPlan: MealPlan? {
        mealPlanManager.mealPlans.first { plan in
            plan.startDate <= selectedWeekStart && plan.endDate >= selectedWeekStart
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Week Planning Hero Section
                weekPlanningHeroSection
                
                // Quick Actions Section
                quickActionsSection
                
                // Food Library Section
                foodLibrarySection
                
                // Shopping Lists Section
                shoppingListsSection
                
                // Meal Templates Section
                mealTemplatesSection
                
                Spacer(minLength: 100)
            }
            .padding()
        }
        .sheet(isPresented: $showingMealPlanning) {
            MealPlanningView()
                .environmentObject(mealPlanManager)
                .environmentObject(macroGoalsManager)
        }
        .sheet(isPresented: $showingFoodLibrary) {
            FoodLibraryView()
        }
        .sheet(isPresented: $showingShoppingDashboard) {
            ShoppingDashboardView()
                .environmentObject(shoppingListManager)
                .environmentObject(mealPlanManager)
        }
        .sheet(item: $selectedMealPlan) { mealPlan in
            MealPlanDetailView(mealPlan: mealPlan)
                .environmentObject(shoppingListManager)
        }
        .sheet(item: $selectedMeal) { meal in
            MealDetailView(meal: meal)
        }
        .onAppear {
            selectedWeekStart = currentWeekStart
        }
    }
    
    // MARK: - Week Planning Hero Section
    
    private var weekPlanningHeroSection: some View {
        VStack(spacing: 16) {
            // Week navigation header
            HStack {
                Button(action: previousWeek) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Text(weekHeaderText)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: nextWeek) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                }
            }
            .padding(.horizontal, 8)
            
            // Week grid
            if let mealPlan = activeWeekMealPlan {
                weekGridWithMealPlan(mealPlan)
            } else {
                emptyWeekGrid
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
    
    private var weekHeaderText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d"
        
        let weekEnd = calendar.date(byAdding: .day, value: 6, to: selectedWeekStart) ?? selectedWeekStart
        
        if calendar.isDate(selectedWeekStart, equalTo: currentWeekStart, toGranularity: .day) {
            return "This Week"
        } else {
            return "\(formatter.string(from: selectedWeekStart)) - \(formatter.string(from: weekEnd))"
        }
    }
    
    private func weekGridWithMealPlan(_ mealPlan: MealPlan) -> some View {
        VStack(spacing: 12) {
            // Days of week header
            HStack {
                ForEach(weekDays, id: \.self) { day in
                    VStack(spacing: 4) {
                        Text(dayOfWeekFormatter.string(from: day))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Text("\(calendar.component(.day, from: day))")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(calendar.isDateInToday(day) ? .primary : .secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            
            // Meal plan content
            VStack(spacing: 8) {
                ForEach(MealType.allCases, id: \.self) { mealType in
                    HStack {
                        // Meal type label
                        Text(mealType.displayName)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(width: 60, alignment: .leading)
                        
                        // Meal slots for each day
                        ForEach(weekDays, id: \.self) { day in
                            mealSlot(for: day, mealType: mealType, mealPlan: mealPlan)
                        }
                    }
                }
            }
            
            // Action button
            Button(action: {
                selectedMealPlan = mealPlan
            }) {
                HStack {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 14, weight: .medium))
                    Text("View Full Plan")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(.primary)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
            .padding(.top, 4)
        }
    }
    
    private var emptyWeekGrid: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 32, weight: .light))
                .foregroundColor(.secondary)
            
            Text("No meal plan for this week")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
            
            Button(action: {
                showingMealPlanning = true
            }) {
                HStack {
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 16, weight: .medium))
                    Text("Create Meal Plan")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(.white)
                .padding(.vertical, 12)
                .padding(.horizontal, 24)
                .background(Color.primary)
                .cornerRadius(12)
            }
        }
        .padding(.vertical, 20)
    }
    
    private func mealSlot(for day: Date, mealType: MealType, mealPlan: MealPlan) -> some View {
        Button(action: {
            // Get meal for this day/type
            if let meal = getMeal(for: day, mealType: mealType, from: mealPlan) {
                selectedMeal = meal
            }
        }) {
            VStack(spacing: 2) {
                if let meal = getMeal(for: day, mealType: mealType, from: mealPlan) {
                    Text(meal.name)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                } else {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(.systemGray5))
                        .frame(height: 4)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 32)
            .padding(.horizontal, 4)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(getMeal(for: day, mealType: mealType, from: mealPlan) != nil ? Color(.systemGray6) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Quick Actions Section
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            HStack(spacing: 12) {
                ActionCard(
                    icon: "wand.and.stars",
                    title: "Create Plan",
                    subtitle: "AI-powered meal planning",
                    action: {
                        showingMealPlanning = true
                    }
                )
                
                ActionCard(
                    icon: "magnifyingglass",
                    title: "Food Library",
                    subtitle: "Search & manage foods",
                    action: {
                        showingFoodLibrary = true
                    }
                )
                
                ActionCard(
                    icon: "cart.fill",
                    title: "Shopping",
                    subtitle: "Manage shopping lists",
                    action: {
                        showingShoppingDashboard = true
                    }
                )
            }
        }
    }
    
    // MARK: - Food Library Section
    
    private var foodLibrarySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Food Library")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("View All") {
                    showingFoodLibrary = true
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
            }
            
            // Quick access to recent/frequent foods
            Text("Recently used foods and saved meals will appear here")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .padding(.vertical, 20)
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray6))
                .cornerRadius(12)
        }
    }
    
    // MARK: - Shopping Lists Section
    
    private var shoppingListsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Shopping Lists")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("View All") {
                    showingShoppingDashboard = true
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
            }
            
            // Show active shopping lists summary
            let activeListsCount = shoppingListManager.shoppingLists.filter { !$0.remainingItems.isEmpty }.count
            
            if activeListsCount > 0 {
                HStack {
                    Image(systemName: "cart.badge.plus")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Text("\(activeListsCount) active shopping list\(activeListsCount == 1 ? "" : "s")")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button("Review") {
                        showingShoppingDashboard = true
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            } else {
                Text("No active shopping lists")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .padding(.vertical, 20)
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Meal Templates Section
    
    private var mealTemplatesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Meal Templates")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("Browse All") {
                    // TODO: Show meal templates view
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
            }
            
            // Quick templates
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(sampleMealTemplates, id: \.id) { template in
                        MealTemplateCard(template: template) {
                            // TODO: Use template
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    private var sampleMealTemplates: [MealPlanTemplate] {
        [
            MealPlanTemplate(
                id: UUID(),
                name: "High Protein",
                description: "Protein-focused meals",
                estimatedCalories: 1800,
                estimatedProtein: 150,
                mealCount: 3
            ),
            MealPlanTemplate(
                id: UUID(),
                name: "Balanced",
                description: "Well-rounded nutrition",
                estimatedCalories: 2000,
                estimatedProtein: 120,
                mealCount: 3
            ),
            MealPlanTemplate(
                id: UUID(),
                name: "Plant-Based",
                description: "Vegetarian meals",
                estimatedCalories: 1700,
                estimatedProtein: 90,
                mealCount: 4
            )
        ]
    }
    
    // MARK: - Helper Functions
    
    private func previousWeek() {
        selectedWeekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: selectedWeekStart) ?? selectedWeekStart
    }
    
    private func nextWeek() {
        selectedWeekStart = calendar.date(byAdding: .weekOfYear, value: 1, to: selectedWeekStart) ?? selectedWeekStart
    }
    
    private func getMeal(for day: Date, mealType: MealType, from mealPlan: MealPlan) -> Meal? {
        guard let generatedPlan = mealPlan.generatedMealPlan else { return nil }
        
        let dayOfPlan = calendar.dateComponents([.day], from: mealPlan.startDate, to: day).day ?? 0
        let dailyMeal = generatedPlan.dailyMeals.first { $0.day == dayOfPlan + 1 }
        
        return dailyMeal?.meals.first { $0.type == mealType }
    }
    
    private let dayOfWeekFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter
    }()
}

// MARK: - Supporting Models

struct MealPlanTemplate: Identifiable {
    let id: UUID
    let name: String
    let description: String
    let estimatedCalories: Int
    let estimatedProtein: Int
    let mealCount: Int
}

// MARK: - Supporting Views

struct MealTemplateCard: View {
    let template: MealPlanTemplate
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Text(template.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(template.description)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack {
                    Text("\(template.estimatedCalories) cal")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(template.mealCount) meals")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                
                Text("\(template.estimatedProtein)g protein")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .frame(width: 140, height: 100)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 8)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}


#Preview {
    MealPlanningDashboardView()
        .environmentObject(MacroGoalsManager())
        .environmentObject(MealPlanManager())
        .environmentObject(ShoppingListManager())
}