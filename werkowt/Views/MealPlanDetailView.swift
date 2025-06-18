import SwiftUI

struct MealPlanDetailView: View {
    let mealPlan: MealPlan
    @Environment(\.dismiss) private var dismiss
    @State private var selectedMeal: Meal?
    @State private var showingShoppingList = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Shopping List Button
                    if mealPlan.isAIGenerated && mealPlan.generatedMealPlan?.shoppingList != nil {
                        Button(action: {
                            showingShoppingList = true
                        }) {
                            HStack {
                                Image(systemName: "list.bullet.clipboard")
                                    .font(.title3)
                                    .foregroundColor(.white)
                                
                                Text("SHOPPING LIST")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                if let count = mealPlan.generatedMealPlan?.shoppingList?.count {
                                    Text("\(count) items")
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.9))
                                }
                                
                                Image(systemName: "arrow.right")
                                    .font(.title3)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .padding(16)
                            .background(
                                LinearGradient(
                                    colors: [Color.gray.opacity(0.8), Color.gray.opacity(0.6)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                            .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    // Header Info
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(mealPlan.dateRange)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            if mealPlan.isAIGenerated {
                                HStack(spacing: 4) {
                                    Image(systemName: "wand.and.stars")
                                        .font(.caption)
                                    Text("AI Generated")
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
                        
                        Text("\(mealPlan.numberOfDays) day\(mealPlan.numberOfDays > 1 ? "s" : "")")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                    
                    if mealPlan.isAIGenerated, let generatedPlan = mealPlan.generatedMealPlan {
                        // AI Generated Content
                        aiGeneratedContent(generatedPlan)
                    } else {
                        // Manual Content
                        manualContent
                    }
                }
                .padding()
            }
            .navigationTitle("Meal Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(item: $selectedMeal) { meal in
            MealDetailView(meal: meal)
        }
        .sheet(isPresented: $showingShoppingList) {
            IntegratedShoppingListView(mealPlan: mealPlan)
        }
    }
    
    @ViewBuilder
    private func aiGeneratedContent(_ generatedPlan: GeneratedMealPlan) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            // Plan Overview
            VStack(alignment: .leading, spacing: 12) {
                Text(generatedPlan.title)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(generatedPlan.description)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            // Daily Meals
            ForEach(generatedPlan.dailyMeals, id: \.day) { dailyMeal in
                dailyMealCard(dailyMeal)
            }
            
            // Shopping List
            if let shoppingList = generatedPlan.shoppingList, !shoppingList.isEmpty {
                shoppingListSection(shoppingList)
            }
            
            // Nutrition Summary
            if let nutrition = generatedPlan.totalNutrition {
                nutritionSummarySection(nutrition)
            }
        }
    }
    
    @ViewBuilder
    private var manualContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Plan Details")
                .font(.title2)
                .fontWeight(.bold)
            
            Text(mealPlan.mealPlanText)
                .font(.body)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
        }
    }
    
    @ViewBuilder
    private func dailyMealCard(_ dailyMeal: DailyMeal) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Day Header
            HStack {
                Text("Day \(dailyMeal.day)")
                    .font(.title3)
                    .fontWeight(.bold)
                
                Spacer()
                
                Text(dailyMeal.date)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Meals
            VStack(spacing: 12) {
                ForEach(dailyMeal.meals, id: \.name) { meal in
                    mealCard(meal)
                }
            }
            
            // Daily Nutrition
            if let nutrition = dailyMeal.dailyNutrition {
                dailyNutritionView(nutrition)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    @ViewBuilder
    private func mealCard(_ meal: Meal) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: meal.type.icon)
                    .foregroundColor(.blue)
                
                Text(meal.type.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                
                Spacer()
                
                if let prepTime = meal.prepTime {
                    Text("\(prepTime) min")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Text(meal.name)
                .font(.headline)
                .fontWeight(.semibold)
            
            if !meal.description.isEmpty {
                Text(meal.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let nutrition = meal.nutrition {
                HStack(spacing: 16) {
                    nutritionItem("Cal", value: Int(nutrition.calories))
                    nutritionItem("P", value: Int(nutrition.protein))
                    nutritionItem("C", value: Int(nutrition.carbs))
                    nutritionItem("F", value: Int(nutrition.fat))
                }
                .font(.caption)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .onTapGesture {
            selectedMeal = meal
        }
    }
    
    @ViewBuilder
    private func nutritionItem(_ label: String, value: Int) -> some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .fontWeight(.semibold)
            Text(label)
                .foregroundColor(.secondary)
        }
    }
    
    @ViewBuilder
    private func dailyNutritionView(_ nutrition: NutritionSummary) -> some View {
        HStack {
            Text("Daily Total:")
                .font(.caption)
                .fontWeight(.medium)
            
            Spacer()
            
            HStack(spacing: 16) {
                nutritionItem("Cal", value: Int(nutrition.totalCalories))
                nutritionItem("P", value: Int(nutrition.totalProtein))
                nutritionItem("C", value: Int(nutrition.totalCarbs))
                nutritionItem("F", value: Int(nutrition.totalFat))
            }
        }
        .padding(.top, 8)
        .font(.caption)
    }
    
    @ViewBuilder
    private func shoppingListSection(_ shoppingList: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Shopping List")
                .font(.title2)
                .fontWeight(.bold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(shoppingList, id: \.self) { item in
                    Text("• \(item)")
                        .font(.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private func nutritionSummarySection(_ nutrition: NutritionSummary) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Total Nutrition")
                .font(.title2)
                .fontWeight(.bold)
            
            HStack {
                nutritionSummaryItem("Calories", value: Int(nutrition.totalCalories), unit: "cal")
                nutritionSummaryItem("Protein", value: Int(nutrition.totalProtein), unit: "g")
                nutritionSummaryItem("Carbs", value: Int(nutrition.totalCarbs), unit: "g")
                nutritionSummaryItem("Fat", value: Int(nutrition.totalFat), unit: "g")
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private func nutritionSummaryItem(_ label: String, value: Int, unit: String) -> some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.title3)
                .fontWeight(.bold)
            Text(unit)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity)
    }
}
