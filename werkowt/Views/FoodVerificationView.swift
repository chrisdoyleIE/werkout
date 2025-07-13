import SwiftUI

struct FoodVerificationView: View {
    let analysisResult: ClaudeAPIClient.FoodAnalysisResult
    let selectedMealType: MealType
    
    @StateObject private var supabaseService = SupabaseService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var editableFoods: [EditableFoodItem] = []
    @State private var editableAmounts: [String: String] = [:]
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    struct EditableFoodItem {
        let analyzedFood: ClaudeAPIClient.AnalyzedFood
        var isSelected: Bool
        var editedName: String
        var editedBrand: String
        var editedNutrition: ClaudeAPIClient.NutritionPer100g
        
        init(from analyzedFood: ClaudeAPIClient.AnalyzedFood) {
            self.analyzedFood = analyzedFood
            self.isSelected = true
            self.editedName = analyzedFood.name
            self.editedBrand = analyzedFood.brand ?? ""
            self.editedNutrition = analyzedFood.nutrition
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with confidence score
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.green)
                        
                        Text("Analysis Complete")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        ConfidenceScoreView(score: analysisResult.confidence)
                    }
                    
                    Text("Review and edit the identified foods before saving")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color(.systemGray6))
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Identified Foods Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Identified Foods")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            ForEach(Array(editableFoods.enumerated()), id: \.offset) { index, editableFood in
                                FoodItemVerificationCard(
                                    editableFood: $editableFoods[index],
                                    estimatedAmount: Binding(
                                        get: {
                                            editableAmounts[editableFood.analyzedFood.name] ?? String(format: "%.0f", analysisResult.estimatedAmounts[editableFood.analyzedFood.name] ?? 100)
                                        },
                                        set: { newValue in
                                            editableAmounts[editableFood.analyzedFood.name] = newValue
                                        }
                                    )
                                )
                            }
                        }
                        
                        // Summary section
                        if !selectedFoods.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Nutrition Summary")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                let totalNutrition = calculateTotalNutrition()
                                
                                VStack(spacing: 8) {
                                    NutritionSummaryRow(
                                        title: "Total Calories",
                                        value: String(format: "%.0f", totalNutrition.calories),
                                        color: .red
                                    )
                                    
                                    NutritionSummaryRow(
                                        title: "Protein",
                                        value: String(format: "%.1f", totalNutrition.protein),
                                        unit: "g",
                                        color: .green
                                    )
                                    
                                    NutritionSummaryRow(
                                        title: "Carbs",
                                        value: String(format: "%.1f", totalNutrition.carbs),
                                        unit: "g",
                                        color: .orange
                                    )
                                    
                                    NutritionSummaryRow(
                                        title: "Fat",
                                        value: String(format: "%.1f", totalNutrition.fat),
                                        unit: "g",
                                        color: .purple
                                    )
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            }
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding()
                }
                
                // Bottom action bar
                VStack(spacing: 12) {
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }
                    
                    Button(action: saveFoodEntries) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                            }
                            
                            Text(isLoading ? "Saving..." : "Add to \(selectedMealType.displayName)")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canSave ? Color.blue : Color.gray)
                        .cornerRadius(12)
                    }
                    .disabled(!canSave || isLoading)
                }
                .padding()
                .background(Color(.systemBackground))
            }
            .navigationTitle("Verify Foods")
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
            setupEditableFoods()
        }
    }
    
    private var selectedFoods: [EditableFoodItem] {
        editableFoods.filter { $0.isSelected }
    }
    
    private var canSave: Bool {
        !selectedFoods.isEmpty && !isLoading
    }
    
    private func setupEditableFoods() {
        editableFoods = analysisResult.identifiedFoods.map { EditableFoodItem(from: $0) }
        
        // Initialize amounts
        for food in analysisResult.identifiedFoods {
            let amount = analysisResult.estimatedAmounts[food.name] ?? 100
            editableAmounts[food.name] = String(format: "%.0f", amount)
        }
    }
    
    private func calculateTotalNutrition() -> NutritionInfo {
        var total = NutritionInfo.zero
        
        for editableFood in selectedFoods {
            let amountString = editableAmounts[editableFood.analyzedFood.name] ?? "100"
            let amount = Double(amountString) ?? 100
            let factor = amount / 100.0
            
            let nutrition = NutritionInfo(
                calories: editableFood.editedNutrition.calories * factor,
                protein: editableFood.editedNutrition.protein * factor,
                carbs: editableFood.editedNutrition.carbs * factor,
                fat: editableFood.editedNutrition.fat * factor,
                fiber: (editableFood.editedNutrition.fiber ?? 0) * factor,
                sugar: (editableFood.editedNutrition.sugar ?? 0) * factor,
                sodium: (editableFood.editedNutrition.sodium ?? 0) * factor
            )
            
            total = total + nutrition
        }
        
        return total
    }
    
    private func saveFoodEntries() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                var entries: [FoodEntry] = []
                
                for editableFood in selectedFoods {
                    let amountString = editableAmounts[editableFood.analyzedFood.name] ?? "100"
                    let amount = Double(amountString) ?? 100
                    
                    let entry = try await supabaseService.createFoodEntryFromAnalysis(
                        analyzedFood: editableFood.analyzedFood,
                        quantity: amount,
                        mealType: selectedMealType,
                        source: .claudeSearch
                    )
                    
                    entries.append(entry)
                }
                
                await MainActor.run {
                    isLoading = false
                    dismiss()
                }
                
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Failed to save food entries: \(error.localizedDescription)"
                }
                print("Error saving food entries: \(error)")
            }
        }
    }
}

struct FoodItemVerificationCard: View {
    @Binding var editableFood: FoodVerificationView.EditableFoodItem
    @Binding var estimatedAmount: String
    
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 12) {
            // Main food item row
            HStack(spacing: 12) {
                // Selection checkbox
                Button(action: {
                    editableFood.isSelected.toggle()
                }) {
                    Image(systemName: editableFood.isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 20))
                        .foregroundColor(editableFood.isSelected ? .blue : .secondary)
                }
                
                // Food info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(editableFood.editedName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        if !editableFood.editedBrand.isEmpty {
                            Text("(\(editableFood.editedBrand))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        ConfidenceScoreView(score: editableFood.analyzedFood.confidence)
                    }
                    
                    Text("\(String(format: "%.0f", editableFood.editedNutrition.calories)) cal/100g")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Amount input
                VStack(alignment: .trailing, spacing: 2) {
                    HStack {
                        TextField("Amount", text: $estimatedAmount)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 60)
                        
                        Text("g")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Expand button
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Expanded nutrition details
            if isExpanded {
                VStack(spacing: 8) {
                    Divider()
                    
                    let amount = Double(estimatedAmount) ?? 100
                    let factor = amount / 100.0
                    
                    VStack(spacing: 6) {
                        NutritionDetailRow(
                            title: "Calories",
                            value: String(format: "%.0f", editableFood.editedNutrition.calories * factor),
                            color: .red
                        )
                        
                        NutritionDetailRow(
                            title: "Protein",
                            value: String(format: "%.1f", editableFood.editedNutrition.protein * factor),
                            unit: "g",
                            color: .green
                        )
                        
                        NutritionDetailRow(
                            title: "Carbs",
                            value: String(format: "%.1f", editableFood.editedNutrition.carbs * factor),
                            unit: "g",
                            color: .orange
                        )
                        
                        NutritionDetailRow(
                            title: "Fat",
                            value: String(format: "%.1f", editableFood.editedNutrition.fat * factor),
                            unit: "g",
                            color: .purple
                        )
                        
                        if let fiber = editableFood.editedNutrition.fiber, fiber > 0 {
                            NutritionDetailRow(
                                title: "Fiber",
                                value: String(format: "%.1f", fiber * factor),
                                unit: "g",
                                color: .brown
                            )
                        }
                    }
                    
                    if editableFood.analyzedFood.existsInDatabase {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                            
                            Text("Found in database")
                                .font(.caption)
                                .foregroundColor(.green)
                            
                            Spacer()
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(editableFood.isSelected ? Color.blue.opacity(0.05) : Color(.systemGray6))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(editableFood.isSelected ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
}

struct ConfidenceScoreView: View {
    let score: Double
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "brain.head.profile")
                .font(.caption2)
                .foregroundColor(confidenceColor)
            
            Text("\(Int(score * 100))%")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(confidenceColor)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(confidenceColor.opacity(0.1))
        .cornerRadius(4)
    }
    
    private var confidenceColor: Color {
        if score >= 0.8 {
            return .green
        } else if score >= 0.6 {
            return .orange
        } else {
            return .red
        }
    }
}

struct NutritionSummaryRow: View {
    let title: String
    let value: String
    var unit: String = ""
    let color: Color
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
            
            HStack(alignment: .bottom, spacing: 2) {
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

struct NutritionDetailRow: View {
    let title: String
    let value: String
    var unit: String = ""
    let color: Color
    
    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            HStack(alignment: .bottom, spacing: 2) {
                Text(value)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
                
                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}
