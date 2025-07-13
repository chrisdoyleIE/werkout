import SwiftUI
import Charts

// MARK: - Shared Colors
extension Color {
    static let lightGrayCalendar = Color(red: 0.94, green: 0.94, blue: 0.94)
    static let progressBarBackground = Color.gray.opacity(0.2)
}

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
    @State private var macroDataByDate: [Date: MacroData] = [:]
    @State private var showingStreakInfo = false
    @State private var weightDataByWeek: [Date: Double] = [:]
    
    private var todaysNutrition: NutritionInfo {
        supabaseService.getTodaysNutritionSummary()
    }
    
    private var journeyStartDate: Date? {
        // Find the earliest workout session
        guard let earliestWorkout = workoutDataManager.workoutSessions
            .min(by: { $0.startedAt < $1.startedAt }) else {
            return nil
        }
        return Calendar.current.startOfDay(for: earliestWorkout.startedAt)
    }
    
    private var journeyDays: Int {
        guard let startDate = journeyStartDate else {
            return 0 // No workouts yet, journey hasn't started
        }
        
        let calendar = Calendar.current
        let today = Calendar.current.startOfDay(for: Date())
        let daysSinceStart = calendar.dateComponents([.day], from: startDate, to: today).day ?? 0
        return max(0, daysSinceStart)
    }
    
    private var calorieStreak: Int {
        var streak = 0
        let today = Date()
        let calendar = Calendar.current
        
        // Start from today and go backwards
        var currentDate = today
        
        // Count consecutive days where calories were achieved
        for _ in 0..<365 { // Limit to 1 year to prevent infinite loops
            let dayStart = Calendar.current.startOfDay(for: currentDate)
            
            if let macroData = macroDataByDate[dayStart], macroData.caloriesAchieved {
                streak += 1
                // Move to previous day
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            } else {
                // Streak broken, stop counting
                break
            }
        }
        
        return streak
    }
    
    private var lastMilestone: Int {
        let milestones = [25, 50, 75, 100]
        return milestones.last { $0 <= journeyDays } ?? 0
    }
    
    private var nextMilestone: Int {
        let milestones = [25, 50, 75, 100]
        return milestones.first { $0 > journeyDays } ?? 100
    }
    
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Spacer for top
                    Spacer()
                        .frame(height: 20)

                    
                
                    
                    // Journey Section
                    VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 16) {
                        
                        // Progress split layout
                        VStack(spacing: 12) {
                            VStack(spacing: 16) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text("Day \(journeyDays)")
                                            .font(.system(size: 36, weight: .bold, design: .rounded))
                                            .foregroundColor(.primary)
                                        Text("of 100")
                                            .font(.system(size: 14, weight: .regular))
                                            .foregroundColor(Color(red: 0.33, green: 0.33, blue: 0.33))
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing) {
                                        Text(String(format: "%.1f weeks", Double(100 - journeyDays) / 7.0))
                                            .font(.system(size: 14, weight: .regular))
                                            .foregroundColor(.primary)
                                        HStack(spacing: 2) {
                                            Text("until your first")
                                                .font(.system(size: 14, weight: .regular))
                                                .foregroundColor(Color(red: 0.33, green: 0.33, blue: 0.33))
                                            Text("Hundred")
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(.black)
                                        }
                                    }
                                }
                                
                                // Supercharged progress bar with milestone markers below
                                VStack(spacing: 4) {
                                    GeometryReader { geometry in
                                        ZStack(alignment: .leading) {
                                            // Background bar
                                            RoundedRectangle(cornerRadius: 5)
                                                .fill(Color(red: 0.90, green: 0.90, blue: 0.90))
                                                .frame(width: geometry.size.width, height: 10)
                                            
                                            // Progress fill
                                            RoundedRectangle(cornerRadius: 5)
                                                .fill(Color.black)
                                                .frame(width: geometry.size.width * min(Double(journeyDays) / 100.0, 1.0), height: 10)
                                                .animation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0), value: journeyDays)
                                        }
                                    }
                                    .frame(height: 10)
                                    
                                    // Milestone symbols and day count annotations - aligned with bar edges
                                    HStack {
                                        // Day 0 - aligned to left edge
                                        VStack(spacing: 2) {
                                            Image(systemName: "figure.mixed.cardio")
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(.black)
                                            Text("1")
                                                .font(.system(size: 10, weight: .medium))
                                                .foregroundColor(.black)
                                        }
                                        
                                        Spacer()
                                        
                                        // Day 25
                                        VStack(spacing: 2) {
                                            Image(systemName: "figure.walk")
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(journeyDays >= 25 ? Color(red: 1.0, green: 0.8, blue: 0.0) : Color(red: 0.6, green: 0.6, blue: 0.6))
                                            Text("25")
                                                .font(.system(size: 10, weight: .medium))
                                                .foregroundColor(journeyDays >= 25 ? Color(red: 1.0, green: 0.8, blue: 0.0) : Color(red: 0.6, green: 0.6, blue: 0.6))
                                        }
                                        
                                        Spacer()
                                        
                                        // Day 50
                                        VStack(spacing: 2) {
                                            Image(systemName: "figure.walk.motion")
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(journeyDays >= 50 ? Color(red: 1.0, green: 0.8, blue: 0.0) : Color(red: 0.6, green: 0.6, blue: 0.6))
                                            Text("50")
                                                .font(.system(size: 10, weight: .medium))
                                                .foregroundColor(journeyDays >= 50 ? Color(red: 1.0, green: 0.8, blue: 0.0) : Color(red: 0.6, green: 0.6, blue: 0.6))
                                        }
                                        
                                        Spacer()
                                        
                                        // Day 75
                                        VStack(spacing: 2) {
                                            Image(systemName: "figure.run")
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(journeyDays >= 75 ? Color(red: 1.0, green: 0.8, blue: 0.0) : Color(red: 0.6, green: 0.6, blue: 0.6))
                                            Text("75")
                                                .font(.system(size: 10, weight: .medium))
                                                .foregroundColor(journeyDays >= 75 ? Color(red: 1.0, green: 0.8, blue: 0.0) : Color(red: 0.6, green: 0.6, blue: 0.6))
                                        }
                                        
                                        Spacer()
                                        
                                        // Day 100 - aligned to right edge
                                        VStack(spacing: 2) {
                                            Image(systemName: journeyDays >= 100 ? "crown.fill" : "crown")
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(journeyDays >= 100 ? Color(red: 1.0, green: 0.8, blue: 0.0) : Color(red: 0.6, green: 0.6, blue: 0.6))
                                            Text("100")
                                                .font(.system(size: 10, weight: .medium))
                                                .foregroundColor(journeyDays >= 100 ? Color(red: 1.0, green: 0.8, blue: 0.0) : Color(red: 0.6, green: 0.6, blue: 0.6))
                                        }
                                    }
                                }
                                .frame(height: 38)
                            }
                            .padding(20)
                            .background(Color.white)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
                        }
                        .padding(.horizontal)
                    }
                
                HorizontalCalendarView(
                    workoutSessions: workoutDataManager.workoutSessions,
                    refreshTrigger: calendarRefreshTrigger,
                    macroDataByDate: $macroDataByDate,
                    weightDataByWeek: $weightDataByWeek
                ) { session in
                    selectedSession = session
                } onDateTap: { date in
                    selectedDayForDetail = date
                }
                    .environmentObject(workoutDataManager)
                    
                    // Divider
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 1)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 8)
                    
                    // Today Section
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Today")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        
                        // Vertical bar layout for macros - centered
                        HStack {
                            Spacer()
                            HStack(spacing: 32) {
                                VerticalMacroBar(
                                    emoji: "🔥",
                                    currentValue: Int(todaysNutrition.calories),
                                    goalValue: Int(macroGoalsManager.goals.calories),
                                    macroName: "calories",
                                    progress: min(todaysNutrition.calories / macroGoalsManager.goals.calories, 1.0),
                                    color: .black
                                )
                                
                                VerticalMacroBar(
                                    emoji: "🥩",
                                    currentValue: Int(todaysNutrition.protein),
                                    goalValue: Int(macroGoalsManager.goals.protein),
                                    macroName: "protein",
                                    unit: "g",
                                    progress: min(todaysNutrition.protein / macroGoalsManager.goals.protein, 1.0),
                                    color: .black
                                )
                                
                                VerticalMacroBar(
                                    emoji: "🌾",
                                    currentValue: Int(todaysNutrition.carbs),
                                    goalValue: Int(macroGoalsManager.goals.carbs),
                                    macroName: "carbs",
                                    unit: "g",
                                    progress: min(todaysNutrition.carbs / macroGoalsManager.goals.carbs, 1.0),
                                    color: .black
                                )
                                
                                VerticalMacroBar(
                                    emoji: "🥑",
                                    currentValue: Int(todaysNutrition.fat),
                                    goalValue: Int(macroGoalsManager.goals.fat),
                                    macroName: "fat",
                                    unit: "g",
                                    progress: min(todaysNutrition.fat / macroGoalsManager.goals.fat, 1.0),
                                    color: .black
                                )
                            }
                            Spacer()
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 12)
                }
                .padding(.bottom, 16)
                
                Spacer()
            }
            }
            .scrollIndicators(.hidden)
            
            // Action button removed - now in tab bar
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
        .sheet(isPresented: $showingStreakInfo) {
            StreakInfoView(streak: journeyDays)
        }
        .onAppear {
            // Force data refresh when view appears
            Task {
                await workoutDataManager.loadWorkoutSessions()
                await supabaseService.loadTodaysEntries()
                
                // Check what today's entries returned
                let todaysNutrition = supabaseService.getTodaysNutritionSummary()
                // Trigger calendar refresh after data loads
                await MainActor.run {
                    calendarRefreshTrigger.toggle()
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            // Refresh when app returns to foreground
            Task {
                await workoutDataManager.loadWorkoutSessions()
                await supabaseService.loadTodaysEntries()
                
                // Check what today's entries returned after foreground refresh
                let todaysNutrition = supabaseService.getTodaysNutritionSummary()
                
                await MainActor.run {
                    calendarRefreshTrigger.toggle()
                }
            }
        }
    }
    
    private func getMotivationalMessage() -> String {
        let daysLeft = max(0, 100 - journeyDays)
        
        switch journeyDays {
        case 0:
            return "Start your hundred today - every journey begins with a single day"
        case 1...7:
            return "Building momentum - keep going!"
        case 8...14:
            return "Two weeks strong - you're establishing the habit"
        case 15...24:
            return "Approaching 25 days - your first milestone is near!"
        case 25:
            return "🎯 Quarter way there! 25 days of dedication"
        case 26...49:
            return "\(daysLeft) days to go - you're proving what's possible"
        case 50:
            return "🔥 Halfway to your hundred! Incredible progress"
        case 51...74:
            return "Past the halfway mark - \(daysLeft) days until your best self"
        case 75:
            return "💪 75 days! The final quarter begins"
        case 76...99:
            return "So close - just \(daysLeft) days to complete your hundred"
        case 100:
            return "🏆 You've completed your hundred! You are your best self"
        default:
            return "Beyond the hundred - keep cultivating excellence"
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
    @Binding var macroDataByDate: [Date: MacroData]
    @Binding var weightDataByWeek: [Date: Double]
    let onSessionTap: (WorkoutSession) -> Void
    let onDateTap: (Date) -> Void
    
    @State private var isLoadingMacroData = false
    @State private var isLoadingWeightData = false
    @EnvironmentObject var workoutDataManager: WorkoutDataManager
    
    private let calendar = Calendar.current
    private let dayLabels = ["M", "T", "W", "T", "F", "S", "S"]
    
    // Calculate optimal width to fit 12 weeks across screen
    private var weekWidth: CGFloat {
        // Screen width minus horizontal padding (8px each side + 30px left for day labels + 16px right margin)
        let availableWidth = UIScreen.main.bounds.width - 62
        return availableWidth / 12
    }
    
    // Generate initial 12 weeks total starting from first workout week
    private var initialWeeks: [Date] {
        // Find the earliest workout date
        guard let earliestWorkout = workoutSessions.min(by: { $0.startedAt < $1.startedAt }) else {
            // Fallback: if no workouts, show last 12 weeks ending with today
            let today = calendar.startOfDay(for: Date())
            let weekday = calendar.component(.weekday, from: today)
            let daysFromMonday = (weekday == 1) ? 6 : weekday - 2
            let currentWeekMonday = calendar.date(byAdding: .day, value: -daysFromMonday, to: today) ?? today
            let startWeek = calendar.date(byAdding: .weekOfYear, value: -11, to: currentWeekMonday) ?? currentWeekMonday
            
            return (0..<12).compactMap { weekOffset in
                calendar.date(byAdding: .weekOfYear, value: weekOffset, to: startWeek)
            }
        }
        
        // Calculate the Monday of the week containing the first workout
        let firstWorkoutDate = calendar.startOfDay(for: earliestWorkout.startedAt)
        let weekday = calendar.component(.weekday, from: firstWorkoutDate)
        let daysFromMonday = (weekday == 1) ? 6 : weekday - 2
        let firstWorkoutWeekMonday = calendar.date(byAdding: .day, value: -daysFromMonday, to: firstWorkoutDate) ?? firstWorkoutDate
        
        // Generate 12 weeks starting from the first workout week
        return (0..<12).compactMap { weekOffset in
            calendar.date(byAdding: .weekOfYear, value: weekOffset, to: firstWorkoutWeekMonday)
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
        HStack(spacing: 2) {
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
                        .frame(height: 22)
                }
            }
            .frame(width: 30)
            .padding(.leading, 8)
            .padding(.trailing, 2)
            
            // Calendar content
            VStack(spacing: 1) {
                // Month headers
                HStack(spacing: 0) {
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
                        } else {
                            Text("")
                                .frame(width: weekWidth)
                        }
                    }
                }
                .frame(height: 20)
                
                // Week numbers
                HStack(spacing: 0) {
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
                        HStack(spacing: 0) {
                            ForEach(currentWeeks, id: \.self) { weekDate in
                                let date = calendar.date(byAdding: .day, value: dayOfWeek, to: weekDate) ?? weekDate
                                CalendarDayView(
                                    date: date,
                                    isCurrentMonth: true,
                                    workoutSession: sessionForDate(date),
                                    macroData: macroDataByDate[Calendar.current.startOfDay(for: date)] ?? MacroData.empty
                                ) { _ in
                                    onDateTap(date)
                                }
                                .frame(width: weekWidth, height: 22)
                            }
                        }
                    }
                }
                
            }
            .padding(.horizontal, 8)
            .padding(.trailing, 8)
        }
        .onChange(of: refreshTrigger) { _, _ in
            loadBulkMacroData()
            loadWeightData()
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
            do {
                let bulkData = try await SupabaseService.shared.getCachedMacroAchievements(for: allCalendarDates)
                let duration = Date().timeIntervalSince(startTime)
                
                await MainActor.run {
                    macroDataByDate = bulkData
                    isLoadingMacroData = false
                    
                    // Debug: Check today's macro data
                    let today = Date()
                    let todayStart = Calendar.current.startOfDay(for: today)
                    if let todayData = bulkData[todayStart] {
                        print("🎯 Today's macro data - Calories: \(todayData.caloriesAchieved), Protein: \(todayData.proteinAchieved)")
                    } else {
                        print("❌ No macro data found for today: \(todayStart)")
                    }
                    
                    // Debug: Summary of loaded dates
                    let achievementDates = bulkData.filter { $0.value.caloriesAchieved || $0.value.proteinAchieved }
                    
                    // Only log dates with achievements
                    let formatter = DateFormatter()
                    formatter.dateFormat = "MMM dd"
                    for (date, data) in achievementDates.sorted(by: { $0.key < $1.key }) {
                        print("📈 \(formatter.string(from: date)): Cal=\(data.caloriesAchieved), Protein=\(data.proteinAchieved)")
                    }
                    
                    // Specifically check June 24th, 2025 (the problematic date)
                    let june24 = Calendar.current.date(from: DateComponents(year: 2025, month: 6, day: 24))!
                    let june24Start = Calendar.current.startOfDay(for: june24)
                    
                    // Debug the exact keys being used
                    print("🔍 June 24th lookup key: \(june24Start)")
                    print("🔍 Available cache keys for June: \(bulkData.keys.filter { Calendar.current.component(.month, from: $0) == 6 }.sorted())")
                    
                    if let june24Data = bulkData[june24Start] {
                        print("🎯 BULK LOAD June 24th: Cal=\(june24Data.caloriesAchieved), Protein=\(june24Data.proteinAchieved)")
                    } else {
                        print("❌ BULK LOAD: No data found for June 24th with key \(june24Start)")
                        // Try to find any June 24th data with different key
                        for (key, value) in bulkData {
                            if Calendar.current.component(.day, from: key) == 24 && Calendar.current.component(.month, from: key) == 6 {
                                print("🔍 Found June 24th data with different key: \(key) -> Cal=\(value.caloriesAchieved), Protein=\(value.proteinAchieved)")
                            }
                        }
                    }
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
    
    private func loadWeightData() {
        guard !isLoadingWeightData else { return }
        
        Task {
            await MainActor.run {
                isLoadingWeightData = true
            }
            
            do {
                let weightEntries = try await workoutDataManager.getRecentBodyWeightEntries(days: 90)
                
                await MainActor.run {
                    print("⚖️ 🚿 Total weight entries loaded: \(weightEntries.count)")
                    
                    // Log all weight entries
                    for entry in weightEntries.sorted(by: { $0.recordedAt < $1.recordedAt }) {
                        print("⚖️ 📅 Weight entry: \(String(format: "%.1f", entry.weightKg))kg on \(entry.recordedAt)")
                    }
                    
                    // Calculate weekly averages
                    var weeklyAverages: [Date: Double] = [:]
                    
                    for weekDate in currentWeeks {
                        // Get all weight entries for this week
                        let weekEnd = Calendar.current.date(byAdding: .day, value: 6, to: weekDate) ?? weekDate
                        let weekEntries = weightEntries.filter { entry in
                            entry.recordedAt >= weekDate && entry.recordedAt <= weekEnd
                        }
                        
                        print("⚖️ 📅 Week \(weekDate) to \(weekEnd): found \(weekEntries.count) weight entries")
                        
                        if !weekEntries.isEmpty {
                            let averageWeight = weekEntries.map { $0.weightKg }.reduce(0, +) / Double(weekEntries.count)
                            weeklyAverages[weekDate] = averageWeight
//                            print("⚖️ 📈 Week \(weekDate): average \(String(format: "%.1f", averageWeight))kg")
                        } else {
//                            print("⚖️ ❌ Week \(weekDate): no weight entries found")
                        }
                    }
                    
                    weightDataByWeek = weeklyAverages
                    isLoadingWeightData = false
                    
                    // Debug: Log weight data
                    print("⚖️ ✅ Final weight data for \(weeklyAverages.count) weeks")
                    for (weekDate, weight) in weeklyAverages.sorted(by: { $0.key < $1.key }) {
                        print("⚖️ 📊 Week \(weekDate): \(String(format: "%.1f", weight))kg")
                    }
                }
            } catch {
                print("❌ Failed to load weight data: \(error)")
                await MainActor.run {
                    isLoadingWeightData = false
                    weightDataByWeek = [:]
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
        let caloriesHit = macroData.caloriesAchieved
        
        if caloriesHit {
            return Color.black // Black background for calorie achievement
        } else {
            return Color(red: 0.97, green: 0.97, blue: 0.97) // Light gray for empty
        }
    }
    
    private var dumbbellColor: Color {
        let caloriesHit = macroData.caloriesAchieved
        
        if caloriesHit {
            return .white // White dumbbell on black background
        } else {
            return .black // Black dumbbell on light background
        }
    }
    
    
    var body: some View {
        Button(action: { onTap(workoutSession) }) {
            // Main calendar square with dumbbell overlay
            ZStack {
                RoundedRectangle(cornerRadius: 3)
                    .fill(backgroundGradient)
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(
                                calendar.isDateInToday(date) ? Color.black : Color.clear, 
                                lineWidth: calendar.isDateInToday(date) ? 1 : 0
                            )
                    )
                
                // Dumbbell icon for workout days
                if workoutSession != nil {
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(dumbbellColor)
                }
            }
            .frame(height: 22)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(1.0)
        .animation(.easeInOut(duration: 0.1), value: false)
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
        formatter.dateFormat = "MMM"
        return formatter
    }()
}

struct StreakInfoView: View {
    let streak: Int
    @Environment(\.dismiss) private var dismiss
    
    private var daysToHundred: Int {
        max(0, 100 - streak)
    }
    
    private var progressPercentage: Double {
        min(Double(streak) / 100.0, 1.0)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // Header with flame and streak
                    VStack(spacing: 16) {
                        ZStack {
                            // Progress ring
                            Circle()
                                .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                                .frame(width: 140, height: 140)
                            
                            Circle()
                                .trim(from: 0, to: progressPercentage)
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(red: 0.8, green: 0.6, blue: 0.0),
                                            Color(red: 1.0, green: 0.8, blue: 0.0)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                                )
                                .frame(width: 140, height: 140)
                                .rotationEffect(Angle(degrees: -90))
                                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: streak)
                            
                            VStack(spacing: 4) {
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.0))
                                    .shadow(color: Color.yellow.opacity(0.3), radius: 4, x: 0, y: 0)
                                
                                Text("\(streak)")
                                    .font(.system(size: 36, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)
                                
                                Text("days")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        if streak < 100 {
                            Text("\(daysToHundred) days to your hundred")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        } else if streak == 100 {
                            Text("🏆 Hundred Complete!")
                                .font(.headline)
                                .foregroundColor(.green)
                                .fontWeight(.bold)
                        } else {
                            Text("Beyond the hundred")
                                .font(.headline)
                                .foregroundColor(.purple)
                                .fontWeight(.medium)
                        }
                    }
                    .padding(.top, 40)
                    
                    // Milestones
                    VStack(spacing: 20) {
                        Text("Your Hundred Journey")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        VStack(spacing: 12) {
                            MilestoneRow(milestone: 25, currentStreak: streak, label: "Foundation Built")
                            MilestoneRow(milestone: 50, currentStreak: streak, label: "Halfway There")
                            MilestoneRow(milestone: 75, currentStreak: streak, label: "Final Quarter")
                            MilestoneRow(milestone: 100, currentStreak: streak, label: "Transformation")
                        }
                        .padding(.horizontal)
                    }
                    
                    // Explanation
                    VStack(alignment: .leading, spacing: 16) {
                        Text("The Hundred Day Promise")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        Text("Complete 100 consecutive days of hitting your nutrition goals and consistent training. This isn't about perfection—it's about showing up every day and cultivating the habits that transform.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                        
                        if streak == 0 {
                            Text("🌱 Plant the seed today. Your hundred starts now.")
                                .font(.subheadline)
                                .foregroundColor(.green)
                                .fontWeight(.medium)
                        } else if streak < 25 {
                            Text("🌱 The foundation is being laid. Trust the process.")
                                .font(.subheadline)
                                .foregroundColor(.green)
                                .fontWeight(.medium)
                        } else if streak < 50 {
                            Text("🔥 Momentum is building. You're proving it's possible.")
                                .font(.subheadline)
                                .foregroundColor(.orange)
                                .fontWeight(.medium)
                        } else if streak < 75 {
                            Text("💪 Past halfway—you're becoming your best self.")
                                .font(.subheadline)
                                .foregroundColor(.orange)
                                .fontWeight(.medium)
                        } else if streak < 100 {
                            Text("🚀 The final stretch. Finish what you started.")
                                .font(.subheadline)
                                .foregroundColor(.red)
                                .fontWeight(.medium)
                        } else {
                            Text("🏆 You did it. The hundred is complete, but the journey continues.")
                                .font(.subheadline)
                                .foregroundColor(.purple)
                                .fontWeight(.medium)
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer(minLength: 40)
                }
            }
            .navigationTitle("Your Hundred")
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

struct CompactMacroView: View {
    let emoji: String
    let value: String
    let goalValue: String
    let macroName: String
    let progress: Double
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            // Main card with ring
            ZStack {
                // Background shape
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(red: 0.97, green: 0.97, blue: 0.97))
                
                // Progress border - circular for smooth curves
                ZStack {
                    // Always show gray background circle
                    Circle()
                        .stroke(Color.gray.opacity(0.2), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .padding(4)
                    
                    // Colored progress ring on top (only when progress > 0)
                    if progress > 0 {
                        Circle()
                            .trim(from: 0, to: CGFloat(progress))
                            .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .rotationEffect(Angle(degrees: -90))
                            .padding(4)
                            .animation(.easeOut(duration: 0.8), value: progress)
                    }
                }
                
                // Content centered in ring
                VStack(spacing: 2) {
                    Text(emoji)
                        .font(.system(size: 20))
                    
                    Text(value)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text(goalValue)
                        .font(.system(size: 10, weight: .regular))
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 6)
            }
            .frame(maxWidth: .infinity, maxHeight: 80)
            
            // Macro name below the entire card
            Text(macroName)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.primary)
                .textCase(.lowercase)
        }
        .frame(maxWidth: .infinity)
    }
}

struct HeroMacroView: View {
    let emoji: String
    let value: String
    let goalValue: String
    let progress: Double
    let color: Color
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(Color(red: 0.97, green: 0.97, blue: 0.97))
            
            // Progress ring
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color.gray.opacity(0.2), style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .padding(5)
                
                // Progress ring
                if progress > 0 {
                    Circle()
                        .trim(from: 0, to: CGFloat(progress))
                        .stroke(color, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                        .rotationEffect(Angle(degrees: -90))
                        .padding(5)
                        .animation(.easeOut(duration: 0.8), value: progress)
                }
            }
            
            // Content
            VStack(spacing: 2) {
                Text(emoji)
                    .font(.system(size: 28))
                
                Text(value)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(goalValue)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct PyramidMacroView: View {
    let emoji: String
    let value: String
    let goalValue: String
    let progress: Double
    let color: Color
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(Color(red: 0.97, green: 0.97, blue: 0.97))
            
            // Progress ring
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color.gray.opacity(0.2), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .padding(3)
                
                // Progress ring
                if progress > 0 {
                    Circle()
                        .trim(from: 0, to: CGFloat(progress))
                        .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .rotationEffect(Angle(degrees: -90))
                        .padding(3)
                        .animation(.easeOut(duration: 0.8), value: progress)
                }
            }
            
            // Content
            VStack(spacing: 1) {
                Text(emoji)
                    .font(.system(size: 16))
                
                Text(value)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.primary)
            }
        }
    }
}

struct VerticalMacroBar: View {
    let emoji: String
    let currentValue: Int
    let goalValue: Int
    let macroName: String
    var unit: String = ""
    let progress: Double
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            // Vertical bar
            ZStack {
                // Background - darker for better contrast
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(red: 0.88, green: 0.88, blue: 0.88))
                    .frame(width: 48, height: 120)
                
                // Progress fill - full width for maximum visibility
                VStack {
                    Spacer()
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color)
                        .frame(width: 48, height: 120 * CGFloat(min(progress, 1.0)))
                        .animation(.easeOut(duration: 0.8), value: progress)
                }
                .frame(width: 48, height: 120)
                
                // Golden crown when macro is met
                if progress >= 1.0 {
                    VStack {
                        Spacer()
                        Image(systemName: "crown.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.0))
                            .padding(.bottom, 60) // Halfway up the 120px bar
                        Spacer()
                    }
                    .frame(width: 48, height: 120)
                }
            }
            
            // Values below bar
            VStack(spacing: 4) {
                Text("\(currentValue)\(unit)")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text("\(goalValue)\(unit)")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(Color(red: 0.53, green: 0.53, blue: 0.53))
            }
            
            // Macro name only (no emoji)
            Text(macroName)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
        }
        .padding(.top, 12)
    }
}

struct MilestoneRow: View {
    let milestone: Int
    let currentStreak: Int
    let label: String
    
    private var isCompleted: Bool {
        currentStreak >= milestone
    }
    
    private var isNext: Bool {
        currentStreak < milestone && currentStreak >= (milestone - 25)
    }
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(isCompleted ? Color.green : (isNext ? Color.orange.opacity(0.3) : Color.gray.opacity(0.1)))
                    .frame(width: 44, height: 44)
                
                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    Text("\(milestone)")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(isNext ? .orange : .gray)
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.subheadline)
                    .fontWeight(isNext ? .semibold : .medium)
                    .foregroundColor(isCompleted ? .primary : (isNext ? .primary : .secondary))
                
                if isCompleted {
                    Text("Completed")
                        .font(.caption)
                        .foregroundColor(.green)
                } else if isNext {
                    Text("\(milestone - currentStreak) days away")
                        .font(.caption)
                        .foregroundColor(.orange)
                } else {
                    Text("Day \(milestone)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}



