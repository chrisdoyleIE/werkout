import SwiftUI

struct WorkoutProgressView: View {
    @EnvironmentObject var workoutDataManager: WorkoutDataManager
    @EnvironmentObject var exerciseDataManager: ExerciseDataManager
    
    @State private var selectedSection: ProgressSection = .overview
    @State private var selectedExercise: Exercise?
    @State private var searchText = ""
    @State private var showingExerciseSearch = false
    @State private var progressData: [WorkoutSet] = []
    @State private var personalRecords: [PersonalRecord] = []
    @State private var recentWeightEntries: [BodyWeightEntry] = []
    @State private var isLoadingProgress = false
    @State private var isLoadingPRs = false
    @State private var isLoadingWeight = false
    
    private var filteredExercises: [Exercise] {
        if searchText.isEmpty {
            return exerciseDataManager.getAllExercises()
        } else {
            return exerciseDataManager.searchExercises(query: searchText)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    Text("PROGRESS")
                        .font(.largeTitle)
                        .fontWeight(.black)
                    
                    // Section Picker
                    Picker("Section", selection: $selectedSection) {
                        ForEach(ProgressSection.allCases, id: \.self) { section in
                            Text(section.title).tag(section)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                .padding()
                
                // Content based on selected section
                ScrollView {
                    switch selectedSection {
                    case .overview:
                        OverviewSection(
                            workoutSessions: workoutDataManager.workoutSessions,
                            personalRecords: personalRecords,
                            recentWeightEntries: recentWeightEntries,
                            isLoadingWeight: isLoadingWeight
                        )
                    case .records:
                        PersonalRecordsSection(
                            personalRecords: personalRecords,
                            isLoading: isLoadingPRs
                        )
                    case .charts:
                        ChartsSection(
                            selectedExercise: selectedExercise,
                            progressData: progressData,
                            isLoading: isLoadingProgress,
                            onExerciseSelect: {
                                showingExerciseSearch = true
                            }
                        )
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                loadPersonalRecords()
                loadWeightData()
            }
            .sheet(isPresented: $showingExerciseSearch) {
                ExerciseSearchSheet(
                    searchText: $searchText,
                    filteredExercises: filteredExercises,
                    onExerciseSelect: { exercise in
                        selectedExercise = exercise
                        showingExerciseSearch = false
                        loadProgressData(for: exercise)
                    }
                )
            }
        }
    }
    
    private func loadPersonalRecords() {
        isLoadingPRs = true
        Task {
            do {
                let records = try await workoutDataManager.getAllPersonalRecords()
                await MainActor.run {
                    personalRecords = records
                    isLoadingPRs = false
                }
            } catch {
                await MainActor.run {
                    isLoadingPRs = false
                }
                print("Failed to load personal records: \(error)")
            }
        }
    }
    
    private func loadProgressData(for exercise: Exercise) {
        isLoadingProgress = true
        Task {
            do {
                let data = try await workoutDataManager.getProgressData(for: exercise.id, days: 90)
                await MainActor.run {
                    progressData = data
                    isLoadingProgress = false
                }
            } catch {
                await MainActor.run {
                    isLoadingProgress = false
                }
                print("Failed to load progress data: \(error)")
            }
        }
    }
    
    private func loadWeightData() {
        isLoadingWeight = true
        Task {
            do {
                await workoutDataManager.loadBodyWeightEntries()
                let recentEntries = try await workoutDataManager.getRecentBodyWeightEntries(days: 30)
                await MainActor.run {
                    recentWeightEntries = recentEntries
                    isLoadingWeight = false
                }
            } catch {
                await MainActor.run {
                    isLoadingWeight = false
                }
                print("Failed to load weight data: \(error)")
            }
        }
    }
}

// MARK: - Progress Section Enum
enum ProgressSection: CaseIterable {
    case overview
    case records
    case charts
    
    var title: String {
        switch self {
        case .overview: return "Overview"
        case .records: return "Records"
        case .charts: return "Charts"
        }
    }
}

// MARK: - Overview Section
struct OverviewSection: View {
    let workoutSessions: [WorkoutSession]
    let personalRecords: [PersonalRecord]
    let recentWeightEntries: [BodyWeightEntry]
    let isLoadingWeight: Bool
    
    private var totalWorkouts: Int {
        workoutSessions.count
    }
    
    private var averageDuration: Int {
        let completedWorkouts = workoutSessions.compactMap { $0.durationMinutes }
        guard !completedWorkouts.isEmpty else { return 0 }
        return completedWorkouts.reduce(0, +) / completedWorkouts.count
    }
    
    private var thisWeekWorkouts: Int {
        let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        return workoutSessions.filter { $0.startedAt >= oneWeekAgo }.count
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Stats Cards
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 10) {
                StatCard(
                    title: "All Workouts",
                    value: "\(totalWorkouts)",
                    icon: "figure.strengthtraining.traditional",
                    color: .blue
                )
                
                StatCard(
                    title: "This Week",
                    value: "\(thisWeekWorkouts)",
                    icon: "calendar.badge.clock",
                    color: .green
                )
                
                StatCard(
                    title: "Avg Duration",
                    value: "\(averageDuration)m",
                    icon: "clock",
                    color: .orange
                )
            }
            
            // Weight Tracking Card (takes remaining space)
            WeightTrendCard(
                recentEntries: recentWeightEntries,
                isLoading: isLoadingWeight
            )
            .frame(maxHeight: .infinity)
            
            // Recent Personal Records (only if weight section is collapsed)
            if !personalRecords.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Recent Personal Records")
                        .font(.title2)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    ForEach(Array(personalRecords.prefix(3)), id: \.id) { record in
                        RecentPRCard(record: record)
                    }
                }
            }
        }
        .padding()
    }
}

// MARK: - Personal Records Section
struct PersonalRecordsSection: View {
    let personalRecords: [PersonalRecord]
    let isLoading: Bool
    @EnvironmentObject var exerciseDataManager: ExerciseDataManager
    
    private var groupedRecords: [String: [PersonalRecord]] {
        var grouped: [String: [PersonalRecord]] = [:]
        
        for record in personalRecords {
            if let muscleGroup = exerciseDataManager.getMuscleGroup(for: record.exerciseId) {
                grouped[muscleGroup.name, default: []].append(record)
            } else {
                grouped["Other", default: []].append(record)
            }
        }
        
        return grouped
    }
    
    var body: some View {
        VStack(spacing: 24) {
            if isLoading {
                SwiftUI.ProgressView()
                    .scaleEffect(1.2)
                    .padding()
            } else if personalRecords.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "trophy.circle")
                        .font(.system(size: 48, weight: .light))
                        .foregroundColor(.secondary)
                    
                    Text("No Personal Records Yet")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Complete workouts with weight-based exercises to start tracking your PRs")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 40)
            } else {
                ForEach(groupedRecords.keys.sorted(), id: \.self) { muscleGroup in
                    if let records = groupedRecords[muscleGroup] {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(muscleGroup)
                                .font(.title2)
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            ForEach(records.sorted { $0.achievedAt > $1.achievedAt }, id: \.id) { record in
                                PersonalRecordCard(record: record)
                            }
                        }
                    }
                }
            }
        }
        .padding()
    }
}

// MARK: - Charts Section
struct ChartsSection: View {
    let selectedExercise: Exercise?
    let progressData: [WorkoutSet]
    let isLoading: Bool
    let onExerciseSelect: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // Exercise Selection
            Button(action: onExerciseSelect) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Selected Exercise")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(selectedExercise?.name ?? "Tap to select exercise")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(selectedExercise != nil ? .primary : .blue)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.blue)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Progress Chart
            if isLoading {
                SwiftUI.ProgressView()
                    .scaleEffect(1.2)
                    .padding()
            } else if let exercise = selectedExercise {
                if progressData.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 48, weight: .light))
                            .foregroundColor(.secondary)
                        
                        Text("No Data Available")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Complete workouts with \(exercise.name) to see your progress")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 40)
                } else {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("\(exercise.name) Progress")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        ExerciseProgressChart(
                            exercise: exercise,
                            progressData: progressData
                        )
                        .frame(height: 250)
                    }
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "chart.line.uptrend.xyaxis.circle")
                        .font(.system(size: 48, weight: .light))
                        .foregroundColor(.blue)
                    
                    Text("Select an Exercise")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Choose an exercise to view your progress over time")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 40)
            }
        }
        .padding()
    }
}

// MARK: - Supporting Views
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            VStack(spacing: 4) {
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 100)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct RecentPRCard: View {
    let record: PersonalRecord
    @EnvironmentObject var exerciseDataManager: ExerciseDataManager
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                if let exercise = exerciseDataManager.getExercise(by: record.exerciseId) {
                    Text(exercise.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                } else {
                    Text(record.exerciseId)
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                Text(record.achievedAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(String(format: "%.1f", record.maxWeightKg))kg")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                
                Text("\(record.reps) reps")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct PersonalRecordCard: View {
    let record: PersonalRecord
    @EnvironmentObject var exerciseDataManager: ExerciseDataManager
    
    // Calculate estimated 1RM using Epley formula
    private var estimated1RM: Double {
        record.maxWeightKg * (1 + Double(record.reps) / 30.0)
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                if let exercise = exerciseDataManager.getExercise(by: record.exerciseId) {
                    Text(exercise.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                } else {
                    Text(record.exerciseId)
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                Text("Achieved: \(record.achievedAt.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(String(format: "%.1f", record.maxWeightKg))kg × \(record.reps)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                
                Text("Est. 1RM: \(String(format: "%.1f", estimated1RM))kg")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Exercise Search Sheet
struct ExerciseSearchSheet: View {
    @Binding var searchText: String
    let filteredExercises: [Exercise]
    let onExerciseSelect: (Exercise) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                SearchBar(text: $searchText)
                
                List(filteredExercises, id: \.id) { exercise in
                    Button(action: {
                        onExerciseSelect(exercise)
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(exercise.name)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text(exercise.type.rawValue.capitalized)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .navigationTitle("Select Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search exercises...", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
        .padding(.horizontal)
    }
}

// MARK: - Exercise Progress Chart
struct ExerciseProgressChart: View {
    let exercise: Exercise
    let progressData: [WorkoutSet]
    
    private var chartData: [ProgressDataPoint] {
        return progressData.compactMap { set in
            guard let date = Calendar.current.dateInterval(of: .day, for: set.completedAt)?.start else {
                return nil
            }
            
            if let weight = set.weightKg, let reps = set.reps {
                // For weight exercises, show estimated 1RM
                let estimated1RM = weight * (1 + Double(reps) / 30.0)
                return ProgressDataPoint(date: date, value: estimated1RM, label: "\(String(format: "%.1f", weight))kg×\(reps)")
            } else if let reps = set.reps {
                // For bodyweight exercises, show reps
                return ProgressDataPoint(date: date, value: Double(reps), label: "\(reps) reps")
            } else if let duration = set.durationSeconds {
                // For timed exercises, show duration in minutes
                let minutes = Double(duration) / 60.0
                return ProgressDataPoint(date: date, value: minutes, label: "\(duration)s")
            }
            
            return nil
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if chartData.isEmpty {
                Text("No data available")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Progress Data")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(yAxisLabel)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(Array(chartData.enumerated()), id: \.offset) { index, dataPoint in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(dataPoint.date.formatted(date: .abbreviated, time: .omitted))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        
                                        Text(dataPoint.label)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                    }
                                    
                                    Spacer()
                                    
                                    Text(String(format: "%.1f", dataPoint.value))
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundColor(.blue)
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                                .background(Color(.systemBackground))
                                .cornerRadius(8)
                            }
                        }
                    }
                    .frame(maxHeight: 200)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var yAxisLabel: String {
        switch exercise.type {
        case .weight:
            return "Est. 1RM (kg)"
        case .bodyweight:
            return "Reps"
        case .timed:
            return "Duration (min)"
        }
    }
}

struct ProgressDataPoint {
    let date: Date
    let value: Double
    let label: String
}

// MARK: - Weight Trend Card
struct WeightTrendCard: View {
    let recentEntries: [BodyWeightEntry]
    let isLoading: Bool
    @EnvironmentObject var workoutDataManager: WorkoutDataManager
    @State private var chartData: [BodyWeightEntry] = []
    
    private var currentWeight: Double? {
        recentEntries.first?.weightKg
    }
    
    private var weightTrend: String {
        guard recentEntries.count >= 2 else { return "No trend" }
        
        let latest = recentEntries[0].weightKg
        let previous = recentEntries[1].weightKg
        let change = latest - previous
        
        if abs(change) < 0.1 {
            return "Stable"
        } else if change > 0 {
            return "+\(String(format: "%.1f", change))kg"
        } else {
            return "\(String(format: "%.1f", change))kg"
        }
    }
    
    private var trendColor: Color {
        guard recentEntries.count >= 2 else { return .secondary }
        
        let latest = recentEntries[0].weightKg
        let previous = recentEntries[1].weightKg
        let change = latest - previous
        
        if abs(change) < 0.1 {
            return .secondary
        } else if change > 0 {
            return .orange
        } else {
            return .green
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Text("Body Weight")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            if isLoading {
                ProgressView()
                    .scaleEffect(1.0)
                    .padding(.vertical, 20)
            } else if let weight = currentWeight {
                // Current weight and trend (always visible)
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Current Weight")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("\(String(format: "%.1f", weight)) kg")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Trend")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(weightTrend)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(trendColor)
                    }
                }
                
                // Compact chart (always visible)
                if !chartData.isEmpty {
                    CompactWeightChartView(entries: Array(chartData.prefix(6)))
                }
            } else {
                // Empty state
                VStack(spacing: 8) {
                    Image(systemName: "figure.stand")
                        .font(.title)
                        .foregroundColor(.secondary)
                    
                    Text("Track your weight")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 20)
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .frame(height: 180)
        .onAppear {
            loadChartData()
        }
    }
    
    private func loadChartData() {
        Task {
            do {
                await workoutDataManager.loadBodyWeightEntries()
                let recentEntries = try await workoutDataManager.getRecentBodyWeightEntries(days: 90)
                await MainActor.run {
                    chartData = recentEntries
                }
            } catch {
                print("Failed to load weight chart data: \(error)")
            }
        }
    }
    
    
    private func deleteEntry(_ entry: BodyWeightEntry) {
        Task {
            do {
                try await workoutDataManager.deleteBodyWeightEntry(entry)
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



#Preview {
    WorkoutProgressView()
        .environmentObject(WorkoutDataManager.shared)
        .environmentObject(ExerciseDataManager.shared)
}

// MARK: - Compact Weight Chart View
struct CompactWeightChartView: View {
    let entries: [BodyWeightEntry]
    
    private var minWeight: Double {
        guard let min = entries.map(\.weightKg).min() else { return 0 }
        return max(0, min - 1)
    }
    
    private var maxWeight: Double {
        guard let max = entries.map(\.weightKg).max() else { return 100 }
        return max + 1
    }
    
    private var weightRange: Double {
        maxWeight - minWeight
    }
    
    private func barHeight(for weight: Double) -> CGFloat {
        guard weightRange > 0 else { return 30 }
        let normalizedHeight = (weight - minWeight) / weightRange
        return CGFloat(normalizedHeight) * 60 + 15 // Min height 15, max around 75
    }
    
    var body: some View {
        VStack(spacing: 8) {
            if entries.count < 2 {
                Text("Add more entries to see progress")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 20)
            } else {
                HStack(alignment: .bottom, spacing: 12) {
                    ForEach(entries.reversed(), id: \.id) { entry in
                        VStack(spacing: 4) {
                            // Weight value
                            Text(String(format: "%.1f", entry.weightKg))
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(.blue)
                            
                            // Bar
                            Rectangle()
                                .fill(Color.blue)
                                .frame(width: 16, height: barHeight(for: entry.weightKg))
                                .cornerRadius(2)
                            
                            // Date
                            Text(entry.recordedAt.formatted(.dateTime.month(.abbreviated).day()))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(height: 90)
            }
        }
    }
}
