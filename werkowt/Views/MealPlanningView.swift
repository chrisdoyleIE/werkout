import SwiftUI

enum MealPlanCreationMode: String, CaseIterable {
    case manual = "Manual"
    case ai = "AI Generated"
    
    var icon: String {
        switch self {
        case .manual: return "text.cursor"
        case .ai: return "wand.and.stars"
        }
    }
    
    var description: String {
        switch self {
        case .manual: return "Write your own meal plan details"
        case .ai: return "Let AI create a detailed meal plan for you"
        }
    }
}

struct MealPlanningView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var mealPlanManager: MealPlanManager
    @EnvironmentObject var macroGoalsManager: MacroGoalsManager
    
    @State private var startDate = Date()
    @State private var endDate = Calendar.current.date(byAdding: .day, value: 6, to: Date()) ?? Date()
    @State private var mealPlanText = ""
    @State private var showingSuccess = false
    @State private var creationMode: MealPlanCreationMode = .manual
    @State private var showingAIAlert = false
    @State private var errorMessage = ""
    @State private var generatedMealPlan: MealPlan?
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
    
    var numberOfDays: Int {
        let days = Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
        return max(1, days + 1)
    }
    
    var isButtonDisabled: Bool {
        let textEmpty = mealPlanText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let isGenerating = mealPlanManager.isGeneratingMealPlan && creationMode == .ai
        return textEmpty || isGenerating
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    Text("MEAL PLANNING")
                        .font(.largeTitle)
                        .fontWeight(.black)
                    
                    Text("Plan your meals for the upcoming days")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Creation Mode Selector
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Creation Mode")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            HStack(spacing: 12) {
                                ForEach(MealPlanCreationMode.allCases, id: \.self) { mode in
                                    Button(action: {
                                        creationMode = mode
                                    }) {
                                        VStack(spacing: 8) {
                                            Image(systemName: mode.icon)
                                                .font(.title2)
                                                .foregroundColor(creationMode == mode ? .white : .blue)
                                            
                                            Text(mode.rawValue)
                                                .font(.caption)
                                                .fontWeight(.medium)
                                                .foregroundColor(creationMode == mode ? .white : .blue)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                        .background(
                                            creationMode == mode ? 
                                            Color.blue : Color.blue.opacity(0.1)
                                        )
                                        .cornerRadius(12)
                                    }
                                }
                            }
                            
                            Text(creationMode.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // Date Selection
                        HStack(spacing: 16) {
                            DatePicker("", selection: $startDate, displayedComponents: .date)
                                .datePickerStyle(CompactDatePickerStyle())
                                .frame(maxWidth: .infinity)
                            
                            Image(systemName: "arrow.right")
                                .font(.title3)
                                .foregroundColor(.secondary)
                            
                            DatePicker("", selection: $endDate, in: startDate..., displayedComponents: .date)
                                .datePickerStyle(CompactDatePickerStyle())
                                .frame(maxWidth: .infinity)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        
                        // Content Input
                        VStack(alignment: .leading, spacing: 16) {
                            Text(creationMode == .manual ? "Add your own flare" : "Describe your preferences")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            ZStack(alignment: .topLeading) {
                                TextEditor(text: $mealPlanText)
                                    .frame(minHeight: 200)
                                    .padding(12)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color(.systemGray4), lineWidth: 1)
                                    )
                                
                                if mealPlanText.isEmpty {
                                    Text(creationMode == .manual ? 
                                         "I want to try mexican but no fish, I'm also on a budget." :
                                         "I want healthy meals with high protein, vegetarian-friendly options, and I'm on a budget.")
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 20)
                                        .allowsHitTesting(false)
                                }
                            }
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding()
                }
                
                // Action Buttons
                VStack(spacing: 16) {
                    Button(action: createMealPlan) {
                        HStack {
                            if mealPlanManager.isGeneratingMealPlan && creationMode == .ai {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: creationMode == .ai ? "wand.and.stars" : "checkmark.circle")
                                    .font(.title3)
                            }
                            
                            Text(creationMode == .ai ? "GENERATE WITH AI" : "CREATE MEAL PLAN")
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
                    .disabled(isButtonDisabled)
                    .opacity(isButtonDisabled ? 0.6 : 1.0)
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
            .alert("Meal Plan Saved!", isPresented: $showingSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your meal plan has been saved successfully.")
            }
            .alert("Error", isPresented: $showingAIAlert) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func createMealPlan() {
        switch creationMode {
        case .manual:
            saveManualMealPlan()
        case .ai:
            generateAIMealPlan()
        }
    }
    
    private func saveManualMealPlan() {
        let mealPlan = MealPlan(
            startDate: startDate,
            numberOfDays: numberOfDays,
            mealPlanText: mealPlanText.trimmingCharacters(in: .whitespacesAndNewlines),
            createdAt: Date()
        )
        
        mealPlanManager.saveMealPlan(mealPlan)
        showingSuccess = true
    }
    
    private func generateAIMealPlan() {
        Task {
            do {
                let _ = try await mealPlanManager.generateAIMealPlan(
                    userPreferences: mealPlanText.trimmingCharacters(in: .whitespacesAndNewlines),
                    startDate: startDate,
                    numberOfDays: numberOfDays,
                    macroGoals: macroGoalsManager.goals
                )
                
                await MainActor.run {
                    showingSuccess = true
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showingAIAlert = true
                }
            }
        }
    }
}

#Preview {
    MealPlanningView()
        .environmentObject(MealPlanManager())
        .environmentObject(MacroGoalsManager())
}
