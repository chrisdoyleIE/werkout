import SwiftUI

struct HomeView: View {
    @EnvironmentObject var activeWorkout: ActiveWorkout
    @EnvironmentObject var workoutDataManager: WorkoutDataManager
    @EnvironmentObject var exerciseDataManager: ExerciseDataManager
    @State private var showingWorkoutCreator = false
    @State private var showingLiveWorkout = false
    @State private var showingAddWeight = false
    @State private var selectedDate = Date()
    @State private var selectedSession: WorkoutSession?
    
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 16) {
                Text("WERKOUT")
                    .font(.largeTitle)
                    .fontWeight(.black)
                
                HStack(spacing: 24) {
                    VStack {
                        Text("\(workoutDataManager.workoutSessions.count)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                        Text("Workouts")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack {
                        Text(dateFormatter.string(from: selectedDate))
                            .font(.headline)
                            .fontWeight(.semibold)
                        Text("Current Month")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            
            // Calendar
            CalendarView(
                selectedDate: $selectedDate,
                workoutSessions: workoutDataManager.workoutSessions
            ) { session in
                selectedSession = session
            }
            
            Spacer()
            
            // Action Buttons
            VStack(spacing: 12) {
                // Main Workout Button
                Button(action: {
                    showingWorkoutCreator = true
                }) {
                    HStack {
                        Image(systemName: "play.fill")
                            .font(.title3)
                        Text("LOG WORKOUT")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(
                        LinearGradient(
                            colors: [Color.blue, Color.blue.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                
                // Add Weight Button
                Button(action: {
                    showingAddWeight = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle")
                            .font(.title3)
                        Text("ADD WEIGHT")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                    )
                }
            }
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
            // Month navigation
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .padding()
                }
                
                Spacer()
                
                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .font(.title2)
                        .padding()
                }
            }
            .padding(.horizontal)
            
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
    
    private func previousMonth() {
        selectedDate = calendar.date(byAdding: .month, value: -1, to: selectedDate) ?? selectedDate
    }
    
    private func nextMonth() {
        selectedDate = calendar.date(byAdding: .month, value: 1, to: selectedDate) ?? selectedDate
    }
}

struct CalendarDayView: View {
    let date: Date
    let isCurrentMonth: Bool
    let workoutSession: WorkoutSession?
    let onTap: (WorkoutSession?) -> Void
    
    @EnvironmentObject var workoutDataManager: WorkoutDataManager
    @EnvironmentObject var exerciseDataManager: ExerciseDataManager
    @State private var workoutPreview: WorkoutPreviewData?
    
    private let calendar = Calendar.current
    
    var body: some View {
        Button(action: { onTap(workoutSession) }) {
            VStack(spacing: 1) {
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(workoutSession != nil ? .white : (isCurrentMonth ? .primary : .secondary))
                
                if let session = workoutSession, let preview = workoutPreview {
                    VStack(spacing: 1) {
                        // Exercise count or class indicator
                        if preview.exerciseCount > 0 {
                            Text("\(preview.exerciseCount)")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 16, height: 10)
                                .background(Color.white.opacity(0.3))
                                .cornerRadius(5)
                        } else {
                            // Show class icon for gym classes (0 exercises)
                            Image(systemName: "figure.strengthtraining.functional")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        // Duration
                        if let duration = preview.duration {
                            Text("\(duration)m")
                                .font(.system(size: 7, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                } else if workoutSession != nil {
                    Circle()
                        .fill(Color.white.opacity(0.8))
                        .frame(width: 4, height: 4)
                }
            }
            .frame(width: 45, height: 45)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        workoutSession != nil ? 
                        (workoutPreview?.isGymClass == true ? Color.purple : Color.green) :
                        Color.clear
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(calendar.isDateInToday(date) ? Color.blue : Color.clear, lineWidth: 2)
                    )
            )
            .scaleEffect(workoutSession != nil ? 1.05 : 1.0)
            .shadow(color: workoutSession != nil ? 
                    (workoutPreview?.isGymClass == true ? Color.purple.opacity(0.3) : Color.green.opacity(0.3)) : 
                    .clear, radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(workoutSession == nil)
        .task {
            if let session = workoutSession {
                await loadWorkoutPreview(for: session)
            }
        }
    }
    
    private func loadWorkoutPreview(for session: WorkoutSession) async {
        do {
            let sets = try await workoutDataManager.getSets(for: session.id)
            let uniqueExercises = Set(sets.map { $0.exerciseId })
            let isGymClass = uniqueExercises.isEmpty
            
            let abbreviatedName = session.name.components(separatedBy: " ").compactMap { $0.first }.map(String.init).joined()
            
            await MainActor.run {
                workoutPreview = WorkoutPreviewData(
                    abbreviatedName: String(abbreviatedName.prefix(3)).uppercased(),
                    exerciseCount: uniqueExercises.count,
                    duration: session.durationMinutes,
                    isGymClass: isGymClass
                )
            }
        } catch {
            print("Failed to load workout preview: \(error)")
        }
    }
}

struct WorkoutPreviewData {
    let abbreviatedName: String
    let exerciseCount: Int
    let duration: Int?
    let isGymClass: Bool
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

