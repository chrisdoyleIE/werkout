import SwiftUI

struct MealTrackingView: View {
    @StateObject private var macroGoalsManager = MacroGoalsManager()
    @StateObject private var mealPlanManager = MealPlanManager()
    
    @State private var selectedDate = Date()
    @State private var caloriesConsumed: Double = 2200
    @State private var proteinConsumed: Double = 165
    @State private var carbsConsumed: Double = 120
    @State private var fatConsumed: Double = 30
    
    @State private var showingGoalSettings = false
    @State private var showingMealPlanning = false
    @State private var showingMealPlanList = false
    
    private let calendar = Calendar.current
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE - MMMM d"
        return formatter
    }()
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                HStack {
                    Spacer()
                    
                    Text("NUTRITION")
                        .font(.largeTitle)
                        .fontWeight(.black)
                    
                    Spacer()
                }
                
                
                // Date navigation
                HStack {
                    Button(action: previousDay) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .padding()
                    }
                    
                    Spacer()
                    
                    Text(dateFormatter.string(from: selectedDate))
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Button(action: nextDay) {
                        Image(systemName: "chevron.right")
                            .font(.title2)
                            .padding()
                    }
                    
                    Button(action: {
                        showingGoalSettings = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "flag.fill")
                                .font(.subheadline)
                            Text("Edit")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(16)
                    }
                }
                .padding(.horizontal)
            }
            .padding()
            
            // Progress bars
            VStack(spacing: 16) {
                
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
            .padding()
            
            Spacer()
            
            // Action Buttons
            VStack(spacing: 16) {
                // Secondary Navigation
                HStack(spacing: 12) {
                    Button(action: {
                        showingMealPlanning = true
                    }) {
                        HStack {
                            Image(systemName: "calendar")
                                .font(.subheadline)
                            Text("Meal Planning")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                    
                    Button(action: {
                        showingMealPlanList = true
                    }) {
                        HStack {
                            Image(systemName: "list.bullet.clipboard")
                                .font(.subheadline)
                            Text("Saved Plans")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
                
                // Primary Action - Log Food (matching Add Weight button style)
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
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
        .sheet(isPresented: $showingGoalSettings) {
            GoalSettingsView()
                .environmentObject(macroGoalsManager)
        }
        .sheet(isPresented: $showingMealPlanning) {
            MealPlanningView()
                .environmentObject(mealPlanManager)
        }
        .sheet(isPresented: $showingMealPlanList) {
            MealPlanListView()
                .environmentObject(mealPlanManager)
        }
    }
    
    private func previousDay() {
        selectedDate = calendar.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
    }
    
    private func nextDay() {
        selectedDate = calendar.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
    }
}

struct MacroProgressBar: View {
    let title: String
    let current: Double
    let target: Double
    let unit: String
    let color: Color
    
    private var progress: Double {
        current / target
    }
    
    private var visualProgress: Double {
        min(progress, 1.0)
    }
    
    private var percentage: Int {
        Int(progress * 100)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(width: 60, alignment: .leading)
            
            VStack(spacing: 4) {
                HStack {
                    Text("\(Int(current))\(unit)")
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text("\(Int(target))\(unit)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 6)
                            .cornerRadius(3)
                        
                        Rectangle()
                            .fill(color)
                            .frame(width: geometry.size.width * visualProgress, height: 6)
                            .cornerRadius(3)
                    }
                }
                .frame(height: 6)
            }
            
            Text("\(percentage)%")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .frame(width: 35, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

#Preview {
    MealTrackingView()
}