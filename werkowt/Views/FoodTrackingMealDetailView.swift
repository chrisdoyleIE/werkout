import SwiftUI

struct FoodTrackingMealDetailView: View {
    let meal: RecentFoodItem
    let mealType: MealType
    let onLog: (Double) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var scaleFactor: Double = 1.0
    
    var scaledCalories: Double {
        meal.caloriesPerServing * scaleFactor
    }
    
    var scaledProtein: Double {
        meal.proteinPerServing * scaleFactor
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Meal header
                    VStack(spacing: 8) {
                        Text(meal.name)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("for \(mealType.displayName)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top)
                    
                    // Components
                    if let components = meal.components {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Components")
                                .font(.headline)
                            
                            VStack(spacing: 8) {
                                ForEach(Array(components.enumerated()), id: \.offset) { index, component in
                                    HStack {
                                        Text(component.foodName)
                                            .font(.subheadline)
                                        
                                        Spacer()
                                        
                                        Text("\(Int(component.quantityGrams * scaleFactor))g")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.vertical, 8)
                                    
                                    if index < components.count - 1 {
                                        Divider()
                                    }
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                    }
                    
                    // Portion adjustment
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Portion Size")
                            .font(.headline)
                        
                        HStack {
                            Button(action: { scaleFactor = max(0.25, scaleFactor - 0.25) }) {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.primary.opacity(0.7))
                            }
                            
                            Spacer()
                            
                            Text("\(Int(scaleFactor * 100))%")
                                .font(.title3)
                                .fontWeight(.semibold)
                            
                            Spacer()
                            
                            Button(action: { scaleFactor = min(3.0, scaleFactor + 0.25) }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.primary.opacity(0.7))
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    // Nutrition summary
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Nutrition")
                            .font(.headline)
                        
                        VStack(spacing: 8) {
                            HStack {
                                Text("Calories")
                                Spacer()
                                Text("\(Int(scaledCalories))")
                                    .fontWeight(.semibold)
                            }
                            
                            Divider()
                            
                            HStack {
                                Text("Protein")
                                Spacer()
                                Text("\(Int(scaledProtein))g")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    Spacer(minLength: 40)
                    
                    // Log button
                    Button(action: {
                        onLog(scaleFactor)
                        dismiss()
                    }) {
                        Text("Add to \(mealType.displayName)")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.primary)
                            .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("Meal Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    FoodTrackingMealDetailView(
        meal: RecentFoodItem(
            itemType: "meal",
            itemId: UUID(),
            name: "Chicken & Rice",
            brand: nil,
            lastUsed: Date(),
            useCount: 3,
            avgQuantity: nil,
            caloriesPerServing: 450,
            proteinPerServing: 35,
            isMeal: true,
            components: [
                MealComponent(
                    foodItemId: UUID(),
                    quantityGrams: 150,
                    foodName: "Chicken Breast",
                    brand: nil,
                    caloriesPer100g: 165,
                    proteinPer100g: 31,
                    carbsPer100g: 0,
                    fatPer100g: 3.6
                ),
                MealComponent(
                    foodItemId: UUID(),
                    quantityGrams: 100,
                    foodName: "Brown Rice",
                    brand: nil,
                    caloriesPer100g: 123,
                    proteinPer100g: 2.6,
                    carbsPer100g: 23,
                    fatPer100g: 0.9
                )
            ]
        ),
        mealType: .lunch,
        onLog: { _ in }
    )
}