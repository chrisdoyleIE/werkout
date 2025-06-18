import SwiftUI

struct NutritionTabView: View {
    @StateObject private var macroGoalsManager = MacroGoalsManager()
    @StateObject private var mealPlanManager = MealPlanManager()
    @StateObject private var shoppingListManager = ShoppingListManager()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    Text("NUTRITION")
                        .font(.largeTitle)
                        .fontWeight(.black)
                        .frame(maxWidth: .infinity)
                }
                .padding(.top)
                .padding(.bottom, 16)
                
                // Content
                UnifiedNutritionView()
                    .environmentObject(macroGoalsManager)
                    .environmentObject(mealPlanManager)
                    .environmentObject(shoppingListManager)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

#Preview {
    NutritionTabView()
}