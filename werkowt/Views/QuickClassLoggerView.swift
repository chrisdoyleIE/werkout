import SwiftUI

struct QuickClassLoggerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var workoutDataManager: WorkoutDataManager
    
    @State private var selectedClassType = "HIIT"
    @State private var selectedDuration = 45
    @State private var isLogging = false
    @State private var errorMessage = ""
    
    let onComplete: (() -> Void)?
    
    init(onComplete: (() -> Void)? = nil) {
        self.onComplete = onComplete
    }
    
    private let classTypes = ["HIIT", "Yoga", "Pilates", "Spin", "Boxing", "CrossFit", "Bootcamp", "Zumba"]
    private let durations = [15, 30, 45, 60, 75, 90]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("Log Gym Class")
                        .font(.largeTitle)
                        .fontWeight(.black)
                    
                    Text("Quick log for classes and group fitness")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top)
                
                // Class Type Selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("Class Type")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2), spacing: 8) {
                        ForEach(classTypes, id: \.self) { classType in
                            Button(action: {
                                selectedClassType = classType
                            }) {
                                HStack {
                                    Image(systemName: iconForClass(classType))
                                        .font(.title3)
                                    Text(classType)
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(selectedClassType == classType ? .white : .primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedClassType == classType ? Color.blue : Color(.systemGray6))
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                
                // Duration Selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("Duration")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    HStack(spacing: 8) {
                        ForEach(durations, id: \.self) { duration in
                            Button(action: {
                                selectedDuration = duration
                            }) {
                                Text("\(duration)m")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(selectedDuration == duration ? .white : .primary)
                                    .frame(minWidth: 44)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(selectedDuration == duration ? Color.blue : Color(.systemGray6))
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                
                Spacer()
                
                // Log Button
                Button(action: logClass) {
                    HStack {
                        if isLogging {
                            SwiftUI.ProgressView()
                                .scaleEffect(0.8)
                                .tint(.white)
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title3)
                        }
                        Text(isLogging ? "Logging..." : "Log \(selectedClassType) Class")
                            .font(.title3)
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Color.green, Color.green.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .disabled(isLogging)
                .padding(.horizontal)
                .padding(.bottom)
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.headline)
                }
            }
        }
    }
    
    private func iconForClass(_ classType: String) -> String {
        switch classType {
        case "HIIT": return "flame.fill"
        case "Yoga": return "figure.yoga"
        case "Pilates": return "figure.pilates"
        case "Spin": return "bicycle"
        case "Boxing": return "figure.boxing"
        case "CrossFit": return "figure.strengthtraining.functional"
        case "Bootcamp": return "figure.run"
        case "Zumba": return "figure.dance"
        default: return "figure.strengthtraining.functional"
        }
    }
    
    private func logClass() {
        isLogging = true
        errorMessage = ""
        
        Task {
            do {
                try await workoutDataManager.logGymClass(
                    type: selectedClassType,
                    durationMinutes: selectedDuration
                )
                
                await MainActor.run {
                    isLogging = false
                    dismiss()
                    onComplete?()
                }
            } catch {
                await MainActor.run {
                    isLogging = false
                    errorMessage = "Failed to log class: \(error.localizedDescription)"
                }
            }
        }
    }
}

#Preview {
    QuickClassLoggerView()
        .environmentObject(WorkoutDataManager.shared)
}