import SwiftUI

struct NutritionPlanningView: View {
    @EnvironmentObject var mealPlanManager: MealPlanManager
    @EnvironmentObject var macroGoalsManager: MacroGoalsManager
    @EnvironmentObject var shoppingListManager: ShoppingListManager
    
    @State private var showingMealPlanning = false
    @State private var selectedMealPlan: MealPlan?
    
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
    
    var pastMealPlans: [MealPlan] {
        let now = Date()
        return mealPlanManager.mealPlans.filter { plan in
            plan.endDate < now
        }.sorted { $0.startDate > $1.startDate }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Create New Plan Section
                createNewPlanSection
                
                // Active Plans
                if !activeMealPlans.isEmpty {
                    activePlansSection
                }
                
                // Upcoming Plans
                if !upcomingMealPlans.isEmpty {
                    upcomingPlansSection
                }
                
                // Saved Plans Library
                savedPlansSection
                
                Spacer(minLength: 100)
            }
            .padding()
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
    }
    
    private var createNewPlanSection: some View {
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
    
    private var activePlansSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Active Plans", systemImage: "clock.badge.checkmark")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(activeMealPlans.count)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(activeMealPlans) { plan in
                    mealPlanCard(plan, isActive: true)
                }
            }
        }
    }
    
    private var upcomingPlansSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Upcoming Plans", systemImage: "calendar.badge.clock")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(upcomingMealPlans.count)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(upcomingMealPlans) { plan in
                    mealPlanCard(plan, isActive: false)
                }
            }
        }
    }
    
    private var savedPlansSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Saved Plans", systemImage: "folder.fill")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(pastMealPlans.count)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if pastMealPlans.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "tray")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    
                    Text("No saved meal plans yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Create your first meal plan to get started!")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(40)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(pastMealPlans) { plan in
                        mealPlanCard(plan, isActive: false)
                    }
                }
            }
        }
    }
    
    private func mealPlanCard(_ plan: MealPlan, isActive: Bool) -> some View {
        Button(action: {
            selectedMealPlan = plan
        }) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(plan.generatedMealPlan?.title ?? "Custom Plan")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        
                        Text(plan.dateRange)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if plan.isAIGenerated {
                        Image(systemName: "wand.and.stars")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                
                // Duration and days
                HStack {
                    Label("\(plan.numberOfDays) days", systemImage: "calendar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
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
                
                // Quick actions
                HStack(spacing: 8) {
                    // Shopping list indicator
                    if let shoppingList = shoppingListManager.getShoppingList(for: plan.id) {
                        HStack(spacing: 4) {
                            Image(systemName: "cart")
                                .font(.caption2)
                            Text(shoppingList.completionText)
                                .font(.caption2)
                        }
                        .foregroundColor(.blue)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        duplicatePlan(plan)
                    }) {
                        Image(systemName: "doc.on.doc")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(16)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isActive ? Color.green.opacity(0.3) : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .contextMenu {
            Button("View Details") {
                selectedMealPlan = plan
            }
            
            Button("Duplicate Plan") {
                duplicatePlan(plan)
            }
            
            if !isActive {
                Button("Delete Plan", role: .destructive) {
                    mealPlanManager.deleteMealPlan(plan)
                }
            }
        }
    }
    
    private func duplicatePlan(_ plan: MealPlan) {
        // Create a new meal plan starting from today with the same configuration
        // This would ideally regenerate with the same preferences
        showingMealPlanning = true
    }
}

#Preview {
    NutritionPlanningView()
        .environmentObject(MealPlanManager())
        .environmentObject(MacroGoalsManager())
        .environmentObject(ShoppingListManager())
}