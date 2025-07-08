import SwiftUI

struct WeightTrackingView: View {
    @EnvironmentObject var workoutDataManager: WorkoutDataManager
    @State private var showingAddWeight = false
    @State private var isLoading = false
    @State private var chartData: [BodyWeightEntry] = []
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    Text("WEIGHT")
                        .font(.largeTitle)
                        .fontWeight(.black)
                }
                .padding()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Add Weight Button
                        Button(action: {
                            showingAddWeight = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                
                                Text("Add Weight Entry")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.primary)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        
                        // Weight Chart
                        if isLoading {
                            ProgressView()
                                .scaleEffect(1.2)
                                .padding()
                        } else if !chartData.isEmpty {
                            WeightChartView(entries: chartData)
                                .padding(.horizontal)
                        } else {
                            EmptyWeightView()
                                .padding(.horizontal)
                        }
                        
                        // Recent Entries
                        if !workoutDataManager.bodyWeightEntries.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Recent Entries")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal)
                                
                                LazyVStack(spacing: 12) {
                                    ForEach(workoutDataManager.bodyWeightEntries.prefix(10), id: \.id) { entry in
                                        WeightEntryCard(entry: entry) {
                                            deleteEntry(entry)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.bottom, 50)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                loadData()
            }
            .sheet(isPresented: $showingAddWeight) {
                AddWeightView { weight, notes in
                    await addWeight(weight: weight, notes: notes)
                }
            }
        }
    }
    
    private func loadData() {
        isLoading = true
        Task {
            await workoutDataManager.loadBodyWeightEntries()
            
            do {
                let recentEntries = try await workoutDataManager.getRecentBodyWeightEntries(days: 90)
                await MainActor.run {
                    chartData = recentEntries
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                }
                print("Failed to load weight chart data: \(error)")
            }
        }
    }
    
    private func addWeight(weight: Double, notes: String?) async {
        do {
            try await workoutDataManager.addBodyWeightEntry(weightKg: weight, notes: notes)
            // Reload chart data to include new entry
            let recentEntries = try await workoutDataManager.getRecentBodyWeightEntries(days: 90)
            await MainActor.run {
                chartData = recentEntries
                showingAddWeight = false
            }
        } catch {
            print("Failed to add weight entry: \(error)")
        }
    }
    
    private func deleteEntry(_ entry: BodyWeightEntry) {
        Task {
            do {
                try await workoutDataManager.deleteBodyWeightEntry(entry)
                // Reload chart data
                let recentEntries = try await workoutDataManager.getRecentBodyWeightEntries(days: 90)
                await MainActor.run {
                    chartData = recentEntries
                }
            } catch {
                print("Failed to delete weight entry: \(error)")
            }
        }
    }
}

// MARK: - Weight Chart View
struct WeightChartView: View {
    let entries: [BodyWeightEntry]
    
    private var minWeight: Double {
        guard let min = entries.map(\.weightKg).min() else { return 0 }
        return max(0, min - 2) // Show 2kg below minimum, but not below 0
    }
    
    private var maxWeight: Double {
        guard let max = entries.map(\.weightKg).max() else { return 100 }
        return max + 2 // Show 2kg above maximum
    }
    
    private var weightRange: Double {
        maxWeight - minWeight
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Weight Progress")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Weight (kg)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if entries.count < 2 {
                    Text("Add more entries to see your progress trend")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .italic()
                        .padding(.vertical, 40)
                        .frame(maxWidth: .infinity)
                } else {
                    VStack(spacing: 16) {
                        // Line Chart with Data Points
                        ScrollView(.horizontal, showsIndicators: false) {
                            ZStack {
                                // Grid lines
                                VStack(spacing: 0) {
                                    ForEach(0..<5) { _ in
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.2))
                                            .frame(height: 1)
                                        Spacer()
                                    }
                                }
                                .frame(height: 180)
                                
                                // Chart content
                                HStack(alignment: .bottom, spacing: 24) {
                                    ForEach(Array(entries.enumerated()), id: \.offset) { index, entry in
                                        VStack(spacing: 8) {
                                            // Weight value
                                            Text(String(format: "%.1f kg", entry.weightKg))
                                                .font(.caption)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.primary)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color.primary.opacity(0.1))
                                                .cornerRadius(6)
                                            
                                            // Bar chart
                                            Rectangle()
                                                .fill(Color.primary)
                                                .frame(width: 12, height: CGFloat(barHeight(for: entry.weightKg)))
                                                .cornerRadius(2)
                                            
                                            Spacer()
                                            
                                            // Date and optional notes
                                            VStack(spacing: 2) {
                                                Text(entry.recordedAt.formatted(.dateTime.month(.abbreviated).day()))
                                                    .font(.caption2)
                                                    .fontWeight(.medium)
                                                    .foregroundColor(.primary)
                                                
                                                Text(entry.recordedAt.formatted(.dateTime.year(.defaultDigits)))
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                                
                                                if let notes = entry.notes, !notes.isEmpty {
                                                    Text("📝")
                                                        .font(.caption2)
                                                }
                                            }
                                        }
                                        .frame(width: 60)
                                    }
                                }
                                .padding(.horizontal)
                            }
                            .frame(height: 250)
                        }
                        
                        // Weight range info
                        if entries.count > 1 {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Range")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("\(String(format: "%.1f", minWeight)) - \(String(format: "%.1f", maxWeight)) kg")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("Latest Change")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    if entries.count >= 2 {
                                        let change = entries.first!.weightKg - entries[1].weightKg
                                        Text(change >= 0 ? "+\(String(format: "%.1f", change)) kg" : "\(String(format: "%.1f", change)) kg")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(change >= 0 ? .primary.opacity(0.8) : .primary.opacity(0.6))
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func barHeight(for weight: Double) -> CGFloat {
        guard weightRange > 0 else { return 50 }
        let normalizedHeight = (weight - minWeight) / weightRange
        return CGFloat(normalizedHeight) * 120 + 20 // Min height of 20, max around 140
    }
    
    private func dataPointOffset(for weight: Double) -> Double {
        guard weightRange > 0 else { return 0 }
        let normalizedOffset = (weight - minWeight) / weightRange
        return normalizedOffset * 120 // Scale to chart height
    }
}

// MARK: - Weight Entry Card
struct WeightEntryCard: View {
    let entry: BodyWeightEntry
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(String(format: "%.1f kg", entry.weightKg))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(entry.recordedAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let notes = entry.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .padding(.top, 2)
                }
            }
            
            Spacer()
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.secondary)
                    .font(.subheadline)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Empty Weight View
struct EmptyWeightView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.stand")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(.secondary)
            
            Text("No Weight Entries Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Track your weight over time by adding regular entries")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 40)
    }
}

// MARK: - Add Weight View
struct AddWeightView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var weightText = ""
    @State private var notes = ""
    @State private var isLoading = false
    
    let onSave: (Double, String?) async -> Void
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // Header Icon and Title
                    VStack(spacing: 16) {
                        Image(systemName: "figure.stand")
                            .font(.system(size: 48, weight: .light))
                            .foregroundColor(.primary)
                        
                        VStack(spacing: 8) {
                            Text("Track Weight")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("Record your weight and notes")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 20)
                    
                    // Weight Input Card
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Weight")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            TextField("Enter weight", text: $weightText)
                                .keyboardType(.decimalPad)
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            
                            Text("kg")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.leading, 4)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                    
                    // Notes Input Card
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Notes")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            TextField("How are you feeling today?", text: $notes, axis: .vertical)
                                .font(.body)
                                .lineLimit(3...6)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            
                            Text("Optional")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.leading, 4)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                    
                    Spacer(minLength: 40)
                    
                    // Save Button
                    Button(action: saveWeight) {
                        HStack(spacing: 12) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title3)
                                
                                Text("Save Weight Entry")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isValidWeight ? Color.primary : Color(.systemGray4))
                    .foregroundColor(isValidWeight ? .white : .secondary)
                    .cornerRadius(16)
                    .disabled(!isValidWeight || isLoading)
                    .animation(.easeInOut(duration: 0.2), value: isValidWeight)
                }
                .padding(.horizontal)
                .padding(.bottom, 50)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Add Weight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.body)
                    .fontWeight(.medium)
                }
            }
        }
    }
    
    private var isValidWeight: Bool {
        guard let weight = Double(weightText) else { return false }
        return weight > 0 && weight <= 1000 // Reasonable bounds
    }
    
    private func saveWeight() {
        guard let weight = Double(weightText) else { return }
        
        isLoading = true
        Task {
            await onSave(weight, notes.isEmpty ? nil : notes)
            await MainActor.run {
                isLoading = false
            }
        }
    }
}

// MARK: - Corner Radius Extension
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    let radius: CGFloat
    let corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    WeightTrackingView()
        .environmentObject(WorkoutDataManager.shared)
}
