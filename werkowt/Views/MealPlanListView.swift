import SwiftUI

struct MealPlanListView: View {
    @EnvironmentObject var mealPlanManager: MealPlanManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedMealPlan: MealPlan?
    @State private var showingMealPlanDetail = false
    
    var body: some View {
        NavigationView {
            VStack {
                if mealPlanManager.mealPlans.isEmpty {
                    emptyStateView
                } else {
                    mealPlansList
                }
            }
            .navigationTitle("Saved Meal Plans")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(item: $selectedMealPlan) { mealPlan in
            MealPlanDetailView(mealPlan: mealPlan)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Meal Plans Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Create your first meal plan by tapping 'Meal Planning' on the nutrition screen.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var mealPlansList: some View {
        List {
            ForEach(mealPlanManager.mealPlans) { mealPlan in
                MealPlanRowView(mealPlan: mealPlan) {
                    selectedMealPlan = mealPlan
                }
            }
            .onDelete(perform: deleteMealPlans)
        }
        .listStyle(.insetGrouped)
    }
    
    private func deleteMealPlans(offsets: IndexSet) {
        for index in offsets {
            let mealPlan = mealPlanManager.mealPlans[index]
            mealPlanManager.deleteMealPlan(mealPlan)
        }
    }
}

struct MealPlanRowView: View {
    let mealPlan: MealPlan
    let onTap: () -> Void
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
    
    private let relativeDateFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter
    }()
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header with AI indicator
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(mealPlan.dateRange)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text("Created \(relativeDateFormatter.localizedString(for: mealPlan.createdAt, relativeTo: Date()))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
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
                
                // Duration info
                HStack {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(mealPlan.numberOfDays) day\(mealPlan.numberOfDays > 1 ? "s" : "")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Preview of content
                if mealPlan.isAIGenerated, let generatedPlan = mealPlan.generatedMealPlan {
                    Text(generatedPlan.title)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                } else {
                    Text(mealPlan.mealPlanText)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    let manager = MealPlanManager()
    
    // Add some sample data
    let sampleManualPlan = MealPlan(
        startDate: Date(),
        numberOfDays: 3,
        mealPlanText: "Healthy Mediterranean diet with lots of vegetables and lean proteins.",
        createdAt: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date()
    )
    
    manager.saveMealPlan(sampleManualPlan)
    
    return MealPlanListView()
        .environmentObject(manager)
}