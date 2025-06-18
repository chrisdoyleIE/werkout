import SwiftUI

struct GoalSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var macroGoalsManager: MacroGoalsManager
    
    @State private var calories: String = ""
    @State private var protein: String = ""
    @State private var carbs: String = ""
    @State private var fat: String = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    Text("MACRO GOALS")
                        .font(.largeTitle)
                        .fontWeight(.black)
                    
                    Text("Set your daily nutrition targets")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                
                // Goals Form
                VStack(spacing: 20) {
                    GoalInputRow(
                        title: "Calories",
                        value: $calories,
                        unit: "kcal",
                        color: .red,
                        placeholder: "2000"
                    )
                    
                    GoalInputRow(
                        title: "Protein",
                        value: $protein,
                        unit: "g",
                        color: .blue,
                        placeholder: "150"
                    )
                    
                    GoalInputRow(
                        title: "Carbs",
                        value: $carbs,
                        unit: "g",
                        color: .orange,
                        placeholder: "200"
                    )
                    
                    GoalInputRow(
                        title: "Fat",
                        value: $fat,
                        unit: "g",
                        color: .purple,
                        placeholder: "80"
                    )
                }
                .padding()
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 16) {
                    Button(action: saveGoals) {
                        HStack {
                            Image(systemName: "checkmark.circle")
                                .font(.title3)
                            Text("SAVE GOALS")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [Color.blue, Color.blue.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                        .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    
                    Button(action: resetToDefaults) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.title3)
                            Text("RESET TO DEFAULTS")
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
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            loadCurrentGoals()
        }
    }
    
    private func loadCurrentGoals() {
        let goals = macroGoalsManager.goals
        calories = String(format: "%.0f", goals.calories)
        protein = String(format: "%.0f", goals.protein)
        carbs = String(format: "%.0f", goals.carbs)
        fat = String(format: "%.0f", goals.fat)
    }
    
    private func saveGoals() {
        guard let caloriesValue = Double(calories),
              let proteinValue = Double(protein),
              let carbsValue = Double(carbs),
              let fatValue = Double(fat) else {
            return
        }
        
        Task {
            await macroGoalsManager.updateGoals(
                calories: caloriesValue,
                protein: proteinValue,
                carbs: carbsValue,
                fat: fatValue
            )
            dismiss()
        }
    }
    
    private func resetToDefaults() {
        let defaults = MacroGoals.default
        calories = String(format: "%.0f", defaults.calories)
        protein = String(format: "%.0f", defaults.protein)
        carbs = String(format: "%.0f", defaults.carbs)
        fat = String(format: "%.0f", defaults.fat)
    }
}

struct GoalInputRow: View {
    let title: String
    @Binding var value: String
    let unit: String
    let color: Color
    let placeholder: String
    
    var body: some View {
        HStack(spacing: 16) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(color)
                .frame(width: 80, alignment: .leading)
            
            TextField(placeholder, text: $value)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.decimalPad)
                .frame(maxWidth: .infinity)
            
            Text(unit)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .frame(width: 40, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

#Preview {
    GoalSettingsView()
        .environmentObject(MacroGoalsManager())
}