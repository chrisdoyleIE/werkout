import SwiftUI

struct HomeView: View {
    @EnvironmentObject var activeWorkout: ActiveWorkout
    @EnvironmentObject var workoutDataManager: WorkoutDataManager
    @EnvironmentObject var exerciseDataManager: ExerciseDataManager
    @StateObject private var macroGoalsManager = MacroGoalsManager()
    @StateObject private var mealPlanManager = MealPlanManager()
    
    @State private var showingWorkoutCreator = false
    @State private var showingLiveWorkout = false
    @State private var showingAddWeight = false
    @State private var showingFoodLogger = false
    @State private var selectedDate = Date()
    @State private var selectedSession: WorkoutSession?
    
    // Nutrition state
    @State private var caloriesConsumed: Double = 2200
    @State private var proteinConsumed: Double = 165
    @State private var carbsConsumed: Double = 120
    @State private var fatConsumed: Double = 30
    
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with inline counter
            VStack(spacing: 16) {
                HStack {
                    Text("WERKOUT ")
                        .font(.largeTitle)
                        .fontWeight(.black)
                    + Text("\(workoutDataManager.workoutSessions.count)")
                        .font(.largeTitle)
                        .fontWeight(.black)
                        .foregroundColor(.blue)
                }
                
                // Date Navigation
                DateNavigationView(
                    selectedDate: $selectedDate,
                    onPreviousDay: previousDay,
                    onNextDay: nextDay
                )
                
            }
            .padding()
            
            // Calendar
            CalendarView(
                selectedDate: $selectedDate,
                workoutSessions: workoutDataManager.workoutSessions
            ) { session in
                selectedSession = session
            }
            
            
            // Macro Progress Pie Charts
            HorizontalMacroCharts(
                calories: caloriesConsumed,
                protein: proteinConsumed,
                carbs: carbsConsumed,
                fat: fatConsumed,
                goals: macroGoalsManager.goals
            )
            
            Spacer()
            
            // Unified Action Widget
            UnifiedActionWidget(
                onWorkoutTap: {
                    showingWorkoutCreator = true
                },
                onFoodTap: {
                    showingFoodLogger = true
                },
                onWeightTap: {
                    showingAddWeight = true
                }
            )
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
        .onAppear {
            Task {
                await workoutDataManager.loadWorkoutSessions()
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
        .sheet(isPresented: $showingFoodLogger) {
            // Food logging view - placeholder for now
            NavigationView {
                VStack {
                    Text("Food Logging")
                        .font(.title)
                    Text("This will integrate with the nutrition system")
                        .foregroundColor(.secondary)
                    
                    Button("Close") {
                        showingFoodLogger = false
                    }
                    .padding()
                }
                .navigationTitle("Log Food")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
        .onChange(of: activeWorkout.isActive) { isActive in
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
    }
    
    
    private func previousDay() {
        selectedDate = calendar.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
    }
    
    private func nextDay() {
        selectedDate = calendar.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
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

struct CalendarView: View {
    @Binding var selectedDate: Date
    let workoutSessions: [WorkoutSession]
    let onSessionTap: (WorkoutSession) -> Void
    
    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
    var body: some View {
        VStack(spacing: 0) {
            // Day headers (Monday to Sunday)
            HStack {
                ForEach(["M", "T", "W", "T", "F", "S", "S"], id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 4)
            
            // Calendar grid
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(calendarDays, id: \.self) { date in
                    CalendarDayView(
                        date: date,
                        isCurrentMonth: calendar.isDate(date, equalTo: selectedDate, toGranularity: .month),
                        workoutSession: sessionForDate(date)
                    ) { session in
                        if let session = session {
                            onSessionTap(session)
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var calendarDays: [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: selectedDate) else {
            return []
        }
        
        // Get first Monday of the month view
        let firstOfMonth = monthInterval.start
        let weekday = calendar.component(.weekday, from: firstOfMonth)
        let daysFromMonday = (weekday == 1) ? 6 : weekday - 2 // Convert Sunday=1 to Monday=0 based
        
        guard let startDate = calendar.date(byAdding: .day, value: -daysFromMonday, to: firstOfMonth) else {
            return []
        }
        
        // Generate 42 days (6 weeks)
        return (0..<42).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: startDate)
        }
    }
    
    private func sessionForDate(_ date: Date) -> WorkoutSession? {
        workoutSessions.first { session in
            calendar.isDate(session.startedAt, inSameDayAs: date)
        }
    }
    
}

struct CalendarDayView: View {
    let date: Date
    let isCurrentMonth: Bool
    let workoutSession: WorkoutSession?
    let onTap: (WorkoutSession?) -> Void
    
    @EnvironmentObject var workoutDataManager: WorkoutDataManager
    @EnvironmentObject var exerciseDataManager: ExerciseDataManager
    @State private var macroData: MacroData = MacroData.empty
    
    private let calendar = Calendar.current
    
    var body: some View {
        Button(action: { onTap(workoutSession) }) {
            VStack(spacing: 2) {
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(workoutSession != nil ? .white : (isCurrentMonth ? .primary : .secondary))
                
                Spacer()
            }
            .frame(width: 45, height: 45)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        workoutSession != nil ? 
                        Color.green :
                        Color.clear
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(calendar.isDateInToday(date) ? Color.blue : Color.clear, lineWidth: 2)
                    )
            )
            .overlay(
                // Macro achievement border segments
                ZStack {
                    if macroData.caloriesAchieved {
                        MacroBorderSegment(position: .topLeft)
                    }
                    if macroData.proteinAchieved {
                        MacroBorderSegment(position: .topRight)
                    }
                    if macroData.carbsAchieved {
                        MacroBorderSegment(position: .bottomLeft)
                    }
                    if macroData.fatAchieved {
                        MacroBorderSegment(position: .bottomRight)
                    }
                }
            )
            .scaleEffect(workoutSession != nil ? 1.05 : 1.0)
            .shadow(color: workoutSession != nil ? 
                    Color.green.opacity(0.3) : 
                    .clear, radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(workoutSession == nil)
        .task {
            if let session = workoutSession {
                await loadMacroData(for: session)
            }
        }
    }
    
    private func loadMacroData(for session: WorkoutSession) async {
        // For now, use sample data - this will be replaced with actual macro data loading
        await MainActor.run {
            let day = calendar.component(.day, from: session.startedAt)
            switch day % 4 {
            case 0:
                macroData = MacroData.allAchieved
            case 1:
                macroData = MacroData.caloriesOnly
            case 2:
                macroData = MacroData.sample
            default:
                macroData = MacroData.empty
            }
        }
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

enum BorderPosition {
    case topLeft, topRight, bottomLeft, bottomRight
}

struct MacroBorderSegment: View {
    let position: BorderPosition
    let cornerRadius: CGFloat = 8
    let borderWidth: CGFloat = 2.5
    
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .strokeBorder(Color.clear, lineWidth: 0)
            .overlay(
                borderPath
                    .stroke(Color.green, lineWidth: borderWidth)
            )
    }
    
    private var borderPath: Path {
        Path { path in
            let rect = CGRect(x: 0, y: 0, width: 45, height: 45)
            let radius = cornerRadius
            
            switch position {
            case .topLeft:
                // Top edge
                path.move(to: CGPoint(x: radius, y: 0))
                path.addLine(to: CGPoint(x: rect.midX, y: 0))
                // Left edge
                path.move(to: CGPoint(x: 0, y: radius))
                path.addLine(to: CGPoint(x: 0, y: rect.midY))
                // Top-left corner
                path.addArc(center: CGPoint(x: radius, y: radius), 
                           radius: radius, 
                           startAngle: Angle(degrees: 180), 
                           endAngle: Angle(degrees: 270), 
                           clockwise: false)
                
            case .topRight:
                // Top edge
                path.move(to: CGPoint(x: rect.midX, y: 0))
                path.addLine(to: CGPoint(x: rect.width - radius, y: 0))
                // Right edge
                path.move(to: CGPoint(x: rect.width, y: radius))
                path.addLine(to: CGPoint(x: rect.width, y: rect.midY))
                // Top-right corner
                path.addArc(center: CGPoint(x: rect.width - radius, y: radius), 
                           radius: radius, 
                           startAngle: Angle(degrees: 270), 
                           endAngle: Angle(degrees: 0), 
                           clockwise: false)
                
            case .bottomLeft:
                // Bottom edge
                path.move(to: CGPoint(x: radius, y: rect.height))
                path.addLine(to: CGPoint(x: rect.midX, y: rect.height))
                // Left edge
                path.move(to: CGPoint(x: 0, y: rect.midY))
                path.addLine(to: CGPoint(x: 0, y: rect.height - radius))
                // Bottom-left corner
                path.addArc(center: CGPoint(x: radius, y: rect.height - radius), 
                           radius: radius, 
                           startAngle: Angle(degrees: 90), 
                           endAngle: Angle(degrees: 180), 
                           clockwise: false)
                
            case .bottomRight:
                // Bottom edge
                path.move(to: CGPoint(x: rect.midX, y: rect.height))
                path.addLine(to: CGPoint(x: rect.width - radius, y: rect.height))
                // Right edge
                path.move(to: CGPoint(x: rect.width, y: rect.midY))
                path.addLine(to: CGPoint(x: rect.width, y: rect.height - radius))
                // Bottom-right corner
                path.addArc(center: CGPoint(x: rect.width - radius, y: rect.height - radius), 
                           radius: radius, 
                           startAngle: Angle(degrees: 0), 
                           endAngle: Angle(degrees: 90), 
                           clockwise: false)
            }
        }
    }
}

