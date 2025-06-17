import SwiftUI

struct NutritionTabView: View {
    @StateObject private var macroGoalsManager = MacroGoalsManager()
    @StateObject private var mealPlanManager = MealPlanManager()
    @StateObject private var shoppingListManager = ShoppingListManager()
    
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    Text("NUTRITION")
                        .font(.largeTitle)
                        .fontWeight(.black)
                        .frame(maxWidth: .infinity)
                    
                    // Custom Tab Selector
                    HStack(spacing: 0) {
                        tabButton("TODAY", index: 0)
                        tabButton("MEAL PLANS", index: 1)
                        tabButton("SHOPPING", index: 2)
                    }
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                .padding(.top)
                .padding(.bottom, 16)
                
                // Tab Content
                TabView(selection: $selectedTab) {
                    // TODAY Tab
                    TodayNutritionView()
                        .environmentObject(macroGoalsManager)
                        .environmentObject(mealPlanManager)
                        .tag(0)
                    
                    // MEAL PLANS Tab
                    NutritionPlanningView()
                        .environmentObject(mealPlanManager)
                        .environmentObject(macroGoalsManager)
                        .environmentObject(shoppingListManager)
                        .tag(1)
                    
                    // SHOPPING Tab
                    ShoppingDashboardView()
                        .environmentObject(shoppingListManager)
                        .environmentObject(mealPlanManager)
                        .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func tabButton(_ title: String, index: Int) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTab = index
            }
        }) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(selectedTab == index ? .white : .primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    selectedTab == index ? Color.blue : Color.clear
                )
                .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    NutritionTabView()
}