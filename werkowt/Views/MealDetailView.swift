import SwiftUI

struct MealDetailView: View {
    let meal: Meal
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: meal.type.icon)
                                .foregroundColor(.blue)
                                .font(.title2)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(meal.type.displayName)
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                                    .fontWeight(.medium)
                                
                                Text(meal.name)
                                    .font(.title2)
                                    .fontWeight(.bold)
                            }
                            
                            Spacer()
                            
                            if let prepTime = meal.prepTime {
                                VStack(spacing: 2) {
                                    Image(systemName: "clock")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("\(prepTime) min")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        
                        Text(meal.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(nil)
                    }
                    
                    // Nutrition Info
                    if let nutrition = meal.nutrition {
                        nutritionInfoSection(nutrition)
                    }
                    
                    // Ingredients
                    ingredientsSection
                    
                    // Cooking Instructions
                    instructionsSection
                    
                    Spacer(minLength: 100)
                }
                .padding()
            }
            .navigationTitle("Recipe")
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
    
    private func nutritionInfoSection(_ nutrition: NutritionInfo) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Nutrition per serving", systemImage: "chart.pie")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 0) {
                nutritionItem("Calories", value: Int(nutrition.calories), color: .red)
                nutritionItem("Protein", value: Int(nutrition.protein), color: .blue, unit: "g")
                nutritionItem("Carbs", value: Int(nutrition.carbs), color: .orange, unit: "g")
                nutritionItem("Fat", value: Int(nutrition.fat), color: .purple, unit: "g")
            }
            
            if let fiber = nutrition.fiber, let sugar = nutrition.sugar {
                HStack(spacing: 0) {
                    nutritionItem("Fiber", value: Int(fiber), color: .green, unit: "g")
                    nutritionItem("Sugar", value: Int(sugar), color: .pink, unit: "g")
                    Spacer()
                    Spacer()
                }
            }
        }
        .padding(20)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func nutritionItem(_ label: String, value: Int, color: Color, unit: String = "") -> some View {
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
    
    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Ingredients", systemImage: "list.bullet")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(meal.ingredients.enumerated()), id: \.offset) { index, ingredient in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(index + 1).")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                            .frame(width: 24, alignment: .leading)
                        
                        Text(ingredient)
                            .font(.subheadline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .padding(20)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Instructions", systemImage: "list.number")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 16) {
                ForEach(Array(meal.instructions.enumerated()), id: \.offset) { index, instruction in
                    HStack(alignment: .top, spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 28, height: 28)
                            
                            Text("\(index + 1)")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Step \(index + 1)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .fontWeight(.medium)
                            
                            Text(instruction)
                                .font(.subheadline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(.vertical, 4)
                    
                    if index < meal.instructions.count - 1 {
                        Divider()
                            .padding(.leading, 44)
                    }
                }
            }
        }
        .padding(20)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    MealDetailView(meal: Meal(
        type: .breakfast,
        name: "Avocado Toast with Poached Egg",
        description: "A healthy and delicious breakfast with creamy avocado and perfectly poached egg on whole grain toast.",
        ingredients: [
            "2 slices whole grain bread",
            "1 ripe avocado",
            "2 large eggs",
            "1 tablespoon white vinegar",
            "Salt and pepper to taste",
            "Red pepper flakes (optional)",
            "Lemon juice"
        ],
        instructions: [
            "Fill a large saucepan with water and bring to a gentle simmer. Add white vinegar.",
            "Toast the bread slices until golden brown.",
            "Cut the avocado in half, remove pit, and mash in a bowl. Season with salt, pepper, and lemon juice.",
            "Crack each egg into a small bowl. Create a gentle whirlpool in the simmering water and slowly pour in one egg.",
            "Cook for 3-4 minutes until whites are set but yolk is still runny. Remove with slotted spoon.",
            "Spread mashed avocado on toast, top with poached egg, and season with salt, pepper, and red pepper flakes."
        ],
        prepTime: 15,
        nutrition: NutritionInfo(
            calories: 320,
            protein: 16,
            carbs: 28,
            fat: 18,
            fiber: 12,
            sugar: 3
        )
    ))
}