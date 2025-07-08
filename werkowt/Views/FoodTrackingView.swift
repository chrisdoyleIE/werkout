import SwiftUI

struct FoodTrackingView: View {
    @StateObject private var supabaseService = SupabaseService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingManualSearch = false
    @State private var selectedMealType: MealType = .snack
    
    // Smart input state
    @State private var inputText = ""
    @State private var isAnalyzing = false
    @State private var analysisResult: ClaudeAPIClient.FoodAnalysisResult?
    @State private var showingResults = false
    @State private var errorMessage: String?
    
    private func mealTypeForCurrentTime() -> MealType {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5...10:
            return .breakfast
        case 11...15:
            return .lunch
        case 16...21:
            return .dinner
        default:
            return .snack
        }
    }
    
    private var canAnalyze: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func analyzeFood() {
        guard canAnalyze else { return }
        
        isAnalyzing = true
        errorMessage = nil
        
        Task {
            do {
                let result = try await ClaudeAPIClient.shared.analyzeFoodWithTools(
                    input: inputText.trimmingCharacters(in: .whitespacesAndNewlines),
                    inputType: .text
                )
                
                await MainActor.run {
                    analysisResult = result
                    isAnalyzing = false
                    showingResults = true
                }
            } catch {
                await MainActor.run {
                    isAnalyzing = false
                    errorMessage = "Failed to analyze food: \(error.localizedDescription)"
                }
                print("Food analysis error: \(error)")
            }
        }
    }
    
    private var todaysNutrition: NutritionInfo {
        supabaseService.getTodaysNutritionSummary()
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Simplified meal type selector
                HStack(spacing: 12) {
                    ForEach(MealType.allCases, id: \.self) { mealType in
                        Button(action: {
                            selectedMealType = mealType
                        }) {
                            VStack(spacing: 6) {
                                Image(systemName: mealType.icon)
                                    .font(.system(size: 18))
                                Text(mealType.displayName)
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(selectedMealType == mealType ? .primary : .secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                selectedMealType == mealType ?
                                Color.primary.opacity(0.1) : Color.clear
                            )
                            .cornerRadius(10)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                // Simplified input section
                VStack(spacing: 12) {
                    // Input area
                    HStack(alignment: .top, spacing: 12) {
                        TextField("What did you eat?", text: $inputText, axis: .vertical)
                            .textFieldStyle(.plain)
                            .lineLimit(1...3)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        
                        if !inputText.isEmpty {
                            Button(action: analyzeFood) {
                                if isAnalyzing {
                                    ProgressView()
                                        .controlSize(.small)
                                } else {
                                    Image(systemName: "arrow.up.circle.fill")
                                        .font(.system(size: 28))
                                        .foregroundColor(.primary)
                                }
                            }
                            .disabled(isAnalyzing)
                        }
                    }
                    
                    // Quick action buttons
                    HStack(spacing: 16) {
                        Button(action: { showingManualSearch = true }) {
                            Label("Search", systemImage: "magnifyingglass")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                        }
                        
                        Spacer()
                        
                        Button(action: {}) {
                            Label("Camera", systemImage: "camera")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .disabled(true)
                        
                        Button(action: {}) {
                            Label("Voice", systemImage: "mic")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .disabled(true)
                    }
                    
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 16)
                
                // Today's meals section
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        if supabaseService.isFoodTrackingLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding(.top, 40)
                        } else if supabaseService.todaysEntries.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "fork.knife")
                                    .font(.system(size: 48))
                                    .foregroundColor(.secondary.opacity(0.5))
                                
                                Text("No meals logged today")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Text("Start tracking your meals to see nutrition insights")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 60)
                        } else {
                            // Group entries by meal type
                            ForEach(MealType.allCases, id: \.self) { mealType in
                                let mealEntries = supabaseService.todaysEntries.filter { $0.mealType == mealType }
                                if !mealEntries.isEmpty {
                                    MealSectionView(
                                        mealType: mealType,
                                        entries: mealEntries
                                    )
                                }
                            }
                            
                            // Daily totals
                            VStack(spacing: 16) {
                                HStack {
                                    Text("Daily Total")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                    
                                    Spacer()
                                }
                                
                                HStack(spacing: 20) {
                                    MacroView(
                                        value: String(format: "%.0f", todaysNutrition.calories),
                                        label: "cal",
                                        color: .primary
                                    )
                                    MacroView(
                                        value: String(format: "%.1f", todaysNutrition.protein),
                                        label: "protein",
                                        color: .primary.opacity(0.8)
                                    )
                                    MacroView(
                                        value: String(format: "%.1f", todaysNutrition.carbs),
                                        label: "carbs",
                                        color: .primary.opacity(0.6)
                                    )
                                    MacroView(
                                        value: String(format: "%.1f", todaysNutrition.fat),
                                        label: "fat",
                                        color: .primary.opacity(0.4)
                                    )
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            }
                            .padding(.top, 8)
                        }
                    }
                    .padding(.horizontal)
                }
                
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Track Food")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                selectedMealType = mealTypeForCurrentTime()
                Task {
                    await supabaseService.loadTodaysEntries()
                    await supabaseService.loadRecentFoods()
                }
            }
            .sheet(isPresented: $showingManualSearch) {
                ManualFoodSearchView(selectedMealType: selectedMealType)
            }
            .onChange(of: showingManualSearch) { _, isShowing in
                if !isShowing {
                    // Refresh data when returning from manual search
                    Task {
                        // Add small delay to ensure database transaction completes
                        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                        await supabaseService.loadTodaysEntries()
                    }
                }
            }
            .sheet(isPresented: $showingResults) {
                if let result = analysisResult {
                    FoodVerificationView(
                        analysisResult: result,
                        selectedMealType: selectedMealType
                    )
                }
            }
            .onChange(of: showingResults) { _, isShowing in
                if !isShowing {
                    // Refresh data when returning from food verification
                    Task {
                        // Add small delay to ensure database transaction completes
                        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                        await supabaseService.loadTodaysEntries()
                    }
                    // Clear input after successful addition
                    inputText = ""
                    analysisResult = nil
                    errorMessage = nil
                }
            }
        }
    }
}

// MARK: - Camera View (Placeholder)
struct CameraView: View {
    let onImageCaptured: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                
                VStack(spacing: 16) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    
                    Text("Camera Coming Soon")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Photo-based food recognition will be available in a future update")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Spacer()
                
                Button("Close") {
                    dismiss()
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.primary)
                .cornerRadius(12)
                .padding(.horizontal)
            }
            .padding()
            .navigationTitle("Camera")
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
}

struct ActionButtonContent: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.primary.opacity(0.1))
        .cornerRadius(12)
    }
}

struct NutritionStatView: View {
    let title: String
    let value: String
    var unit: String = ""
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(alignment: .bottom, spacing: 2) {
                Text(value)
                    .font(.headline)
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

struct FoodEntryRowView: View {
    let entry: FoodEntry
    @StateObject private var supabaseService = SupabaseService.shared
    
    var body: some View {
        HStack(spacing: 12) {
            // Meal type icon
            Image(systemName: entry.mealType.icon)
                .font(.system(size: 16))
                .foregroundColor(mealTypeColor)
                .frame(width: 24)
            
            // Food info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(entry.foodItem?.displayName ?? "Unknown Food")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text("\(String(format: "%.0f", entry.quantityGrams))g")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Label("\(String(format: "%.0f", entry.calories)) cal", systemImage: "flame.fill")
                        .font(.caption)
                        .foregroundColor(.primary)
                    
                    Label("\(String(format: "%.1f", entry.proteinG))g protein", systemImage: "circle.fill")
                        .font(.caption)
                        .foregroundColor(.primary.opacity(0.8))
                    
                    Spacer()
                    
                    if entry.source != .manual {
                        Image(systemName: entry.source.icon)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(.systemGray4), lineWidth: 0.5)
        )
        .contextMenu {
            Button(action: {
                Task {
                    try? await supabaseService.deleteFoodEntry(entry)
                }
            }) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
    
    private var mealTypeColor: Color {
        switch entry.mealType {
        case .breakfast:
            return .primary.opacity(0.9)
        case .lunch:
            return .primary.opacity(0.7)
        case .dinner:
            return .primary.opacity(0.5)
        case .snack:
            return .primary.opacity(0.3)
        }
    }
}

// MARK: - New Components

struct MealSectionView: View {
    let mealType: MealType
    let entries: [FoodEntry]
    @State private var isExpanded = false
    
    private var mealTotals: (calories: Double, protein: Double, carbs: Double, fat: Double) {
        entries.reduce((0, 0, 0, 0)) { totals, entry in
            (totals.0 + entry.calories, 
             totals.1 + entry.proteinG, 
             totals.2 + entry.carbsG, 
             totals.3 + entry.fatG)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Meal header
            Button(action: { withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() } }) {
                HStack(spacing: 16) {
                    // Meal icon
                    Image(systemName: mealType.icon)
                        .font(.system(size: 24))
                        .foregroundColor(mealTypeColor(for: mealType))
                        .frame(width: 44, height: 44)
                        .background(mealTypeColor(for: mealType).opacity(0.1))
                        .cornerRadius(10)
                    
                    // Meal info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(mealType.displayName)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("\(entries.count) item\(entries.count == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Meal macros
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(String(format: "%.0f", mealTotals.calories)) cal")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        HStack(spacing: 8) {
                            Text("P: \(String(format: "%.0f", mealTotals.protein))g")
                            Text("C: \(String(format: "%.0f", mealTotals.carbs))g")
                            Text("F: \(String(format: "%.0f", mealTotals.fat))g")
                        }
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    }
                    
                    // Expand indicator
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // Expanded food items
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(entries) { entry in
                        HStack {
                            Text(entry.foodItem?.displayName ?? "Unknown Food")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            Text("\(String(format: "%.0f", entry.quantityGrams))g")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("•")
                                .foregroundColor(.secondary)
                            
                            Text("\(String(format: "%.0f", entry.calories)) cal")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.leading, 60)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
    
    private func mealTypeColor(for mealType: MealType) -> Color {
        switch mealType {
        case .breakfast:
            return .primary.opacity(0.9)
        case .lunch:
            return .primary.opacity(0.7)
        case .dinner:
            return .primary.opacity(0.5)
        case .snack:
            return .primary.opacity(0.3)
        }
    }
}

struct MacroView: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    FoodTrackingView()
}
