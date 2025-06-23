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
            VStack(spacing: 16) {
                // Meal type selector card
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        ForEach(MealType.allCases, id: \.self) { mealType in
                            Button(action: {
                                selectedMealType = mealType
                            }) {
                                VStack(spacing: 4) {
                                    Image(systemName: mealType.icon)
                                        .font(.system(size: 14, weight: .medium))
                                    Text(mealType.displayName)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(
                                    selectedMealType == mealType ? .white : .primary
                                )
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(
                                    selectedMealType == mealType ?
                                    Color.blue : Color(.systemGray5)
                                )
                                .cornerRadius(8)
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                .padding(.horizontal)
                
                // Food input card
                VStack(alignment: .leading, spacing: 12) {
                    // Enhanced text input with embedded options
                    ZStack(alignment: .bottomTrailing) {
                        ZStack(alignment: .topLeading) {
                            TextEditor(text: $inputText)
                                .frame(minHeight: 80)
                                .padding(.horizontal, 8)
                                .padding(.top, 8)
                                .padding(.bottom, 40) // Space for buttons
                            
                            // Placeholder text
                            if inputText.isEmpty {
                                Text("Describe what you ate...")
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 12)
                                    .padding(.top, 16)
                                    .allowsHitTesting(false)
                            }
                        }
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        
                        // Embedded floating icons
                        HStack(spacing: 12) {
                            // Manual search (magnifying glass)
                            Button(action: { showingManualSearch = true }) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 20))
                                    .foregroundColor(.blue)
                            }
                            
                            // Camera
                            Button(action: {
                                // TODO: Camera functionality
                            }) {
                                Image(systemName: "camera")
                                    .font(.system(size: 20))
                                    .foregroundColor(.blue)
                            }
                            .disabled(true)
                            
                            // Microphone
                            Button(action: {
                                // TODO: Mic functionality
                            }) {
                                Image(systemName: "mic")
                                    .font(.system(size: 20))
                                    .foregroundColor(.blue)
                            }
                            .disabled(true)
                            
                            // AI Analysis (appears when text is entered)
                            if !inputText.isEmpty {
                                Button(action: analyzeFood) {
                                    if isAnalyzing {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: "wand.and.stars")
                                            .font(.system(size: 20))
                                            .foregroundColor(.blue)
                                    }
                                }
                                .disabled(isAnalyzing)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.bottom, 8)
                    }
                    
                    // Error message
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                .padding(.horizontal)
                
                // Today's entries card
                VStack(alignment: .leading, spacing: 12) {
                    Text("Today's Entries")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    if supabaseService.isFoodTrackingLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else if supabaseService.todaysEntries.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "fork.knife.circle")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                            
                            Text("No food logged today")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 8) {
                                ForEach(supabaseService.todaysEntries) { entry in
                                    FoodEntryRowView(entry: entry)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                .padding(.horizontal)
                
                Spacer()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Track Food")
            .navigationBarTitleDisplayMode(.inline)
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
            .onChange(of: showingManualSearch) { isShowing in
                print("🔄 showingManualSearch changed to: \(isShowing)")  // <- BREAKPOINT HERE
                if !isShowing {
                    print("🔄 Manual search dismissed, starting refresh...")
                    // Refresh data when returning from manual search
                    Task {
                        // Add small delay to ensure database transaction completes
                        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                        print("🔄 About to call loadTodaysEntries")  // <- BREAKPOINT HERE
                        await supabaseService.loadTodaysEntries()
                        print("🔄 loadTodaysEntries completed")
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
            .onChange(of: showingResults) { isShowing in
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
                .background(Color.blue)
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
        .background(color.opacity(0.1))
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
                        .foregroundColor(.red)
                    
                    Label("\(String(format: "%.1f", entry.proteinG))g protein", systemImage: "circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                    
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
            return .orange
        case .lunch:
            return .blue
        case .dinner:
            return .purple
        case .snack:
            return .gray
        }
    }
}

#Preview {
    FoodTrackingView()
}