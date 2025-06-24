import SwiftUI

struct HomeView: View {
    @EnvironmentObject var activeWorkout: ActiveWorkout
    @EnvironmentObject var workoutDataManager: WorkoutDataManager
    @EnvironmentObject var exerciseDataManager: ExerciseDataManager
    @StateObject private var macroGoalsManager = MacroGoalsManager()
    @StateObject private var mealPlanManager = MealPlanManager()
    @StateObject private var supabaseService = SupabaseService.shared
    
    @State private var showingWorkoutCreator = false
    @State private var showingLiveWorkout = false
    @State private var showingAddWeight = false
    @State private var showingFoodLogger = false
    @State private var showingSettings = false
    @State private var selectedSession: WorkoutSession?
    @State private var selectedDayForDetail: Date?
    @State private var calendarRefreshTrigger = false
    
    private var todaysNutrition: NutritionInfo {
        supabaseService.getTodaysNutritionSummary()
    }
    
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Header with inline counter
            VStack(spacing: 16) {
                ZStack{
                    HStack {
                        Spacer()
                        HStack {
                            Text("WERKOUT ")
                                .font(.largeTitle)
                                .fontWeight(.black)
                            + Text("\(workoutDataManager.workoutSessions.count)")
                                .font(.largeTitle)
                                .fontWeight(.black)
                                .foregroundColor(.blue)
                        }
                        Spacer()
                    }
                    HStack{
                        Spacer()
                        Button(action: {
                            showingSettings = true
                        }) {
                            Image(systemName: "person.circle")
                                .font(.title2)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                
                
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 20)
            
            // Calendar with horizontal scrolling
            HorizontalCalendarView(
                workoutSessions: workoutDataManager.workoutSessions,
                refreshTrigger: calendarRefreshTrigger
            ) { session in
                selectedSession = session
            } onDateTap: { date in
                selectedDayForDetail = date
            }
            .padding(.bottom, 24)
            
            // Activity Rings Section
            VStack(spacing: 16) {
                // Activity Rings
                ActivityRingsView(
                    calories: todaysNutrition.calories,
                    protein: todaysNutrition.protein,
                    carbs: todaysNutrition.carbs,
                    fat: todaysNutrition.fat,
                    goals: macroGoalsManager.goals
                )
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 20)
            
                Spacer()
            }
            
            // Action button removed - now in tab bar
        }
        .onAppear {
            Task {
                await workoutDataManager.loadWorkoutSessions()
                await supabaseService.loadTodaysEntries()
            }
        }
        .sheet(isPresented: $showingWorkoutCreator) {
            WorkoutCreatorView()
        }
        .sheet(isPresented: $showingAddWeight) {
            AddWeightView { weight, notes in
                await addWeight(weight: weight, notes: notes)
            }
        }
        .sheet(item: $selectedSession) { session in
            WorkoutDetailView(session: session)
        }
        .sheet(isPresented: Binding(
            get: { selectedDayForDetail != nil },
            set: { if !$0 { selectedDayForDetail = nil } }
        )) {
            if let selectedDay = selectedDayForDetail {
                DayDetailView(selectedDate: selectedDay)
            }
        }
        .sheet(isPresented: $showingFoodLogger) {
            FoodTrackingView()
        }
        .onChange(of: showingFoodLogger) { _, isShowing in
            if !isShowing {
                // Refresh nutrition data when returning from food tracking
                Task {
                    // Add small delay to ensure database transaction completes
                    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                    await supabaseService.loadTodaysEntries()
                    
                    // Trigger calendar refresh
                    await MainActor.run {
                        calendarRefreshTrigger.toggle()
                    }
                }
            }
        }
        .onChange(of: activeWorkout.isActive) { _, isActive in
            if isActive {
                showingWorkoutCreator = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showingLiveWorkout = true
                }
            }
        }
        .fullScreenCover(isPresented: $showingLiveWorkout) {
            LiveWorkoutView()
                .environmentObject(activeWorkout)
                .environmentObject(workoutDataManager)
                .environmentObject(ExerciseDataManager.shared)
                .onDisappear {
                    showingLiveWorkout = false
                }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .onAppear {
            // Refresh calendar when view appears
            calendarRefreshTrigger.toggle()
        }
    }
    
    
    
    private func addWeight(weight: Double, notes: String?) async {
        do {
            try await workoutDataManager.addBodyWeightEntry(weightKg: weight, notes: notes)
            await MainActor.run {
                showingAddWeight = false
            }
        } catch {
            print("Failed to add weight entry: \(error)")
        }
    }
}

struct HorizontalCalendarView: View {
    let workoutSessions: [WorkoutSession]
    let refreshTrigger: Bool
    let onSessionTap: (WorkoutSession) -> Void
    let onDateTap: (Date) -> Void
    
    @State private var macroDataByDate: [Date: MacroData] = [:]
    @State private var isLoadingMacroData = false
    
    private let calendar = Calendar.current
    private let dayLabels = ["M", "T", "W", "T", "F", "S", "S"]
    
    // Calculate optimal width to fit 12 weeks across screen
    private var weekWidth: CGFloat {
        // Screen width minus horizontal padding (16px each side + 30px left for day labels + 28px right margin)
        let availableWidth = UIScreen.main.bounds.width - 90
        return availableWidth / 12
    }
    
    // Generate initial 12 weeks total with today on far right
    private var initialWeeks: [Date] {
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        let daysFromMonday = (weekday == 1) ? 6 : weekday - 2
        let currentWeekMonday = calendar.date(byAdding: .day, value: -daysFromMonday, to: today) ?? today
        
        // Start 11 weeks ago, show 12 weeks total (11 past + current) - today on far right
        let startWeek = calendar.date(byAdding: .weekOfYear, value: -11, to: currentWeekMonday) ?? currentWeekMonday
        
        return (0..<12).compactMap { weekOffset in
            calendar.date(byAdding: .weekOfYear, value: weekOffset, to: startWeek)
        }
    }
    
    // Use fixed 12 weeks - no dynamic loading
    private var currentWeeks: [Date] {
        return initialWeeks
    }
    
    // Generate all 84 calendar dates for bulk loading
    private var allCalendarDates: [Date] {
        var dates: [Date] = []
        for weekDate in currentWeeks {
            for dayOffset in 0..<7 {
                if let date = calendar.date(byAdding: .day, value: dayOffset, to: weekDate) {
                    dates.append(date)
                }
            }
        }
        return dates
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Day labels on the left
            VStack(spacing: 1) {
                // Space for month headers
                Text("")
                    .frame(height: 20)
                
                // Space for week numbers
                Text("")
                    .frame(height: 20)
                
                // Day labels
                ForEach(0..<7, id: \.self) { dayIndex in
                    Text(dayLabels[dayIndex])
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .frame(height: 17)
                }
            }
            .frame(width: 30)
            .padding(.leading, 16)
            .padding(.trailing, 4)
            
            // Calendar content
            VStack(spacing: 1) {
                // Month headers
                HStack(spacing: 1) {
                    ForEach(currentWeeks.indices, id: \.self) { index in
                        let weekDate = currentWeeks[index]
                        
                        // Show month name when month changes
                        if index == 0 || !calendar.isDate(weekDate, equalTo: currentWeeks[index-1], toGranularity: .month) {
                            Text(DateFormatter.monthName.string(from: weekDate))
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                                .frame(width: weekWidth)
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                        } else {
                            Text("")
                                .frame(width: weekWidth)
                        }
                    }
                }
                .frame(height: 20)
                
                // Week numbers
                HStack(spacing: 1) {
                    ForEach(currentWeeks, id: \.self) { weekDate in
                        Text("\(calendar.component(.day, from: weekDate))")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .frame(width: weekWidth)
                    }
                }
                .frame(height: 20)
                
                // Calendar grid
                VStack(spacing: 1) {
                    ForEach(0..<7, id: \.self) { dayOfWeek in
                        HStack(spacing: 1) {
                            ForEach(currentWeeks, id: \.self) { weekDate in
                                let date = calendar.date(byAdding: .day, value: dayOfWeek, to: weekDate) ?? weekDate
                                CalendarDayView(
                                    date: date,
                                    isCurrentMonth: true,
                                    workoutSession: sessionForDate(date),
                                    macroData: macroDataByDate[date] ?? MacroData.empty
                                ) { _ in
                                    onDateTap(date)
                                }
                                .frame(width: weekWidth, height: 17)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .onAppear {
            loadBulkMacroData()
        }
        .onChange(of: refreshTrigger) { _, _ in
            loadBulkMacroData()
        }
    }
    
    private func sessionForDate(_ date: Date) -> WorkoutSession? {
        workoutSessions.first { session in
            calendar.isDate(session.startedAt, inSameDayAs: date)
        }
    }
    
    private func loadBulkMacroData() {
        guard !isLoadingMacroData else { return }
        
        Task {
            await MainActor.run {
                isLoadingMacroData = true
            }
            
            let startTime = Date()
            print("📅 HorizontalCalendarView: Starting bulk macro data load for \(allCalendarDates.count) dates")
            
            do {
                let bulkData = try await SupabaseService.shared.getCachedMacroAchievements(for: allCalendarDates)
                let duration = Date().timeIntervalSince(startTime)
                
                await MainActor.run {
                    macroDataByDate = bulkData
                    isLoadingMacroData = false
                    print("📅 HorizontalCalendarView: ✅ Completed bulk macro data load in \(String(format: "%.2f", duration))s")
                }
            } catch {
                let duration = Date().timeIntervalSince(startTime)
                print("❌ HorizontalCalendarView: Failed bulk macro data load after \(String(format: "%.2f", duration))s - Error: \(error)")
                
                await MainActor.run {
                    isLoadingMacroData = false
                    // Set empty data for all dates on error
                    macroDataByDate = allCalendarDates.reduce(into: [Date: MacroData]()) { result, date in
                        result[date] = MacroData.empty
                    }
                }
            }
        }
    }
    
}


struct CalendarDayView: View {
    let date: Date
    let isCurrentMonth: Bool
    let workoutSession: WorkoutSession?
    let macroData: MacroData
    let onTap: (WorkoutSession?) -> Void
    
    private let calendar = Calendar.current
    
    private var backgroundGradient: Color {
        if !isCurrentMonth {
            return Color.gray.opacity(0.1)
        }
        
        let caloriesHit = macroData.caloriesAchieved
        let proteinHit = macroData.proteinAchieved
        
        if caloriesHit && proteinHit {
            return Color.green.opacity(0.8) // Dark green
        } else if caloriesHit || proteinHit {
            return Color.green.opacity(0.4) // Light green
        } else {
            return Color.gray.opacity(0.15) // Light gray
        }
    }
    
    
    var body: some View {
        Button(action: { onTap(workoutSession) }) {
            // Main calendar square with dumbbell overlay
            ZStack {
                RoundedRectangle(cornerRadius: 2)
                    .fill(backgroundGradient)
                    .overlay(
                        RoundedRectangle(cornerRadius: 2)
                            .stroke(calendar.isDateInToday(date) ? Color.black : Color.clear, lineWidth: 1)
                    )
                
                // Blue diagonal line for workout days
                if workoutSession != nil {
                    GeometryReader { geometry in
                        Path { path in
                            let width = geometry.size.width
                            let height = geometry.size.height
                            // Bottom-left to top-right diagonal
                            path.move(to: CGPoint(x: 2, y: height - 2))
                            path.addLine(to: CGPoint(x: width - 2, y: 2))
                        }
                        .stroke(Color.blue, lineWidth: 2)
                    }
                }
            }
            .frame(height: 16)
            .frame(maxWidth: .infinity, minHeight: 18)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
}


struct WorkoutDetailView: View {
    let session: WorkoutSession
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var workoutDataManager: WorkoutDataManager
    @EnvironmentObject var exerciseDataManager: ExerciseDataManager
    
    @State private var sets: [WorkoutSet] = []
    @State private var isLoading = true
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button("Done") {
                    dismiss()
                }
                .font(.headline)
                
                Spacer()
                
                Text(session.name)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Text(session.startedAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            
            if isLoading {
                Spacer()
                SwiftUI.ProgressView()
                Spacer()
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        if sets.isEmpty {
                            // Show class details for gym classes
                            VStack(spacing: 20) {
                                Image(systemName: "figure.strengthtraining.functional")
                                    .font(.system(size: 48, weight: .light))
                                    .foregroundColor(.purple)
                                
                                VStack(spacing: 8) {
                                    Text(session.name)
                                        .font(.title2)
                                        .fontWeight(.bold)
                                    
                                    if let duration = session.durationMinutes {
                                        Text("\(duration) minutes")
                                            .font(.title3)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Text("Gym Class")
                                        .font(.headline)
                                        .foregroundColor(.purple)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(Color.purple.opacity(0.1))
                                        .cornerRadius(20)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else {
                            ForEach(groupedSets.keys.sorted(), id: \.self) { exerciseId in
                                if let exerciseSets = groupedSets[exerciseId] {
                                    ExerciseDetailSection(
                                        exerciseId: exerciseId,
                                        sets: exerciseSets
                                    )
                                }
                            }
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            loadSets()
        }
    }
    
    private var groupedSets: [String: [WorkoutSet]] {
        Dictionary(grouping: sets, by: \.exerciseId)
    }
    
    private func loadSets() {
        Task {
            do {
                let sessionSets = try await workoutDataManager.getSets(for: session.id)
                await MainActor.run {
                    sets = sessionSets
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                }
                print("Failed to load sets: \(error)")
            }
        }
    }
}

struct ExerciseDetailSection: View {
    let exerciseId: String
    let sets: [WorkoutSet]
    @EnvironmentObject var exerciseDataManager: ExerciseDataManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let exercise = exerciseDataManager.getExercise(by: exerciseId) {
                Text(exercise.name)
                    .font(.title2)
                    .fontWeight(.bold)
            } else {
                Text(exerciseId)
                    .font(.title2)
                    .fontWeight(.bold)
            }
            
            ForEach(sets.sorted(by: { $0.setNumber < $1.setNumber }), id: \.id) { set in
                Text("Set \(set.setNumber): \(formatSetDisplay(set))")
                    .font(.title3)
                    .fontWeight(.medium)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private func formatSetDisplay(_ set: WorkoutSet) -> String {
        if let weight = set.weightKg, let reps = set.reps {
            // Weight-based exercise
            return "\(String(format: "%.1f", weight))kg × \(reps)"
        } else if let reps = set.reps {
            // Bodyweight exercise
            return "\(reps) reps"
        } else if let duration = set.durationSeconds {
            // Timed exercise
            let minutes = duration / 60
            let seconds = duration % 60
            if minutes > 0 {
                return "\(minutes)m \(seconds)s"
            } else {
                return "\(seconds)s"
            }
        } else {
            return "Unknown"
        }
    }
}

struct WeekCalendarView: View {
    @Binding var selectedDate: Date
    let workoutSessions: [WorkoutSession]
    
    private let calendar = Calendar.current
    
    var body: some View {
        HStack(spacing: 20) {
            ForEach(weekDays, id: \.self) { date in
                VStack(spacing: 8) {
                    Text(dayFormatter.string(from: date))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Text("\(calendar.component(.day, from: date))")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(hasWorkout(date) ? .blue : .primary)
                    
                    Circle()
                        .fill(hasWorkout(date) ? Color.blue : Color.clear)
                        .frame(width: 6, height: 6)
                }
                .frame(width: 40)
            }
        }
        .padding(.horizontal)
    }
    
    private var weekDays: [Date] {
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: selectedDate)?.start ?? selectedDate
        return (0..<7).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek)
        }
    }
    
    private let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter
    }()
    
    private func hasWorkout(_ date: Date) -> Bool {
        workoutSessions.contains { session in
            calendar.isDate(session.startedAt, inSameDayAs: date)
        }
    }
}

struct DayDetailView: View {
    let selectedDate: Date
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var workoutDataManager: WorkoutDataManager
    @EnvironmentObject var exerciseDataManager: ExerciseDataManager
    
    @State private var workoutSets: [WorkoutSet] = []
    @State private var foodEntries: [FoodEntry] = []
    @State private var isLoading = true
    
    private let calendar = Calendar.current
    
    var workoutSession: WorkoutSession? {
        workoutDataManager.workoutSessions.first { session in
            calendar.isDate(session.startedAt, inSameDayAs: selectedDate)
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header with date
                    VStack(alignment: .leading, spacing: 8) {
                        Text(DateFormatter.dayDetailHeader.string(from: selectedDate))
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        if calendar.isDateInToday(selectedDate) {
                            Text("Today")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Workout Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "dumbbell.fill")
                                .foregroundColor(.blue)
                            Text("Workout")
                                .font(.headline)
                                .fontWeight(.bold)
                        }
                        .padding(.horizontal)
                        
                        if let session = workoutSession {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(session.name)
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .padding(.horizontal)
                                
                                if !workoutSets.isEmpty {
                                    LazyVStack(alignment: .leading, spacing: 8) {
                                        ForEach(groupedSets, id: \.key) { exerciseName, sets in
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(exerciseName)
                                                    .font(.subheadline)
                                                    .fontWeight(.medium)
                                                    .padding(.horizontal)
                                                
                                                ForEach(sets) { set in
                                                    HStack {
                                                        Text("Set \(set.setNumber)")
                                                            .font(.caption)
                                                            .foregroundColor(.secondary)
                                                        
                                                        Spacer()
                                                        
                                                        if let reps = set.reps, let weight = set.weightKg {
                                                            Text("\(reps) reps × \(weight, specifier: "%.1f") kg")
                                                                .font(.caption)
                                                        } else if let reps = set.reps {
                                                            Text("\(reps) reps")
                                                                .font(.caption)
                                                        } else if let duration = set.durationSeconds {
                                                            Text("\(duration)s")
                                                                .font(.caption)
                                                        }
                                                    }
                                                    .padding(.horizontal, 20)
                                                }
                                            }
                                        }
                                    }
                                } else {
                                    Text("No exercise details available")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal)
                                }
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        } else {
                            Text("No workout recorded")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(12)
                                .padding(.horizontal)
                        }
                    }
                    
                    // Food Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "fork.knife")
                                .foregroundColor(.green)
                            Text("Food")
                                .font(.headline)
                                .fontWeight(.bold)
                        }
                        .padding(.horizontal)
                        
                        if !foodEntries.isEmpty {
                            ForEach(MealType.allCases, id: \.self) { mealType in
                                let mealEntries = foodEntries.filter { $0.mealType == mealType }
                                if !mealEntries.isEmpty {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(mealType.displayName)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .padding(.horizontal)
                                        
                                        ForEach(mealEntries) { entry in
                                            HStack {
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(entry.foodItem?.displayName ?? "Unknown Food")
                                                        .font(.caption)
                                                        .fontWeight(.medium)
                                                    
                                                    Text("\(entry.quantityGrams, specifier: "%.0f")g")
                                                        .font(.caption2)
                                                        .foregroundColor(.secondary)
                                                }
                                                
                                                Spacer()
                                                
                                                VStack(alignment: .trailing, spacing: 2) {
                                                    Text("\(entry.calories, specifier: "%.0f") cal")
                                                        .font(.caption)
                                                        .fontWeight(.medium)
                                                    
                                                    Text("P: \(entry.proteinG, specifier: "%.1f")g")
                                                        .font(.caption2)
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                            .padding(.horizontal, 20)
                                        }
                                        
                                        // Meal totals
                                        let mealTotals = calculateMealTotals(mealEntries)
                                        HStack {
                                            Text("Total")
                                                .font(.caption)
                                                .fontWeight(.semibold)
                                            
                                            Spacer()
                                            
                                            Text("\(mealTotals.calories, specifier: "%.0f") cal")
                                                .font(.caption)
                                                .fontWeight(.semibold)
                                        }
                                        .padding(.horizontal, 20)
                                        .padding(.top, 4)
                                    }
                                    .padding()
                                    .background(Color.green.opacity(0.1))
                                    .cornerRadius(12)
                                    .padding(.horizontal)
                                }
                            }
                            
                            // Daily totals
                            let dailyTotals = calculateDailyTotals()
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Daily Totals")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .padding(.horizontal)
                                
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text("Calories: \(dailyTotals.calories, specifier: "%.0f")")
                                        Text("Protein: \(dailyTotals.protein, specifier: "%.1f")g")
                                    }
                                    .font(.caption)
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing) {
                                        Text("Carbs: \(dailyTotals.carbs, specifier: "%.1f")g")
                                        Text("Fat: \(dailyTotals.fat, specifier: "%.1f")g")
                                    }
                                    .font(.caption)
                                }
                                .padding(.horizontal, 20)
                            }
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        } else {
                            Text("No food logged")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(12)
                                .padding(.horizontal)
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .task {
            await loadData()
        }
    }
    
    private var groupedSets: [(key: String, value: [WorkoutSet])] {
        let grouped = Dictionary(grouping: workoutSets) { set in
            let exercise = exerciseDataManager.getExercise(by: set.exerciseId)
            return exercise?.name ?? "Unknown Exercise"
        }
        return grouped.sorted { $0.key < $1.key }
    }
    
    private func calculateMealTotals(_ entries: [FoodEntry]) -> (calories: Double, protein: Double, carbs: Double, fat: Double) {
        entries.reduce((0, 0, 0, 0)) { totals, entry in
            (totals.0 + entry.calories, totals.1 + entry.proteinG, totals.2 + entry.carbsG, totals.3 + entry.fatG)
        }
    }
    
    private func calculateDailyTotals() -> (calories: Double, protein: Double, carbs: Double, fat: Double) {
        foodEntries.reduce((0, 0, 0, 0)) { totals, entry in
            (totals.0 + entry.calories, totals.1 + entry.proteinG, totals.2 + entry.carbsG, totals.3 + entry.fatG)
        }
    }
    
    private func loadData() async {
        isLoading = true
        
        // Load workout sets if workout exists
        if let session = workoutSession {
            do {
                let sets = try await workoutDataManager.getSets(for: session.id)
                await MainActor.run {
                    self.workoutSets = sets
                }
            } catch {
                print("Error loading workout sets: \(error)")
            }
        }
        
        // Load food entries for the date
        do {
            let entries = try await SupabaseService.shared.getEntriesForDate(selectedDate)
            await MainActor.run {
                self.foodEntries = entries
            }
        } catch {
            print("Error loading food entries: \(error)")
        }
        
        await MainActor.run {
            self.isLoading = false
        }
    }
}

extension DateFormatter {
    static let dayDetailHeader: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter
    }()
    
    static let monthName: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter
    }()
}



