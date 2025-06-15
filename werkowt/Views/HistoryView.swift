import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var workoutDataManager: WorkoutDataManager
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
                Text("HISTORY")
                    .font(.largeTitle)
                    .fontWeight(.black)
                
                Text(dateFormatter.string(from: selectedDate))
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
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
        }
        .onAppear {
            Task {
                await workoutDataManager.loadWorkoutSessions()
            }
        }
        .sheet(item: $selectedSession) { session in
            WorkoutDetailView(session: session)
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
            
            // Day headers
            HStack {
                ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
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
        guard let monthInterval = calendar.dateInterval(of: .month, for: selectedDate),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfYear, for: monthInterval.start),
              let monthLastWeek = calendar.dateInterval(of: .weekOfYear, for: monthInterval.end) else {
            return []
        }
        
        var dates: [Date] = []
        var date = monthFirstWeek.start
        
        while date < monthLastWeek.end {
            dates.append(date)
            date = calendar.date(byAdding: .day, value: 1, to: date) ?? date
        }
        
        return dates
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
                    .foregroundColor(isCurrentMonth ? .primary : .secondary)
                
                if let session = workoutSession, let preview = workoutPreview {
                    VStack(spacing: 1) {
                        // Workout name (abbreviated)
                        Text(preview.abbreviatedName)
                            .font(.system(size: 8, weight: .medium))
                            .lineLimit(1)
                            .foregroundColor(.blue)
                        
                        // Exercise count and duration
                        HStack(spacing: 2) {
                            Text("\(preview.exerciseCount)")
                                .font(.system(size: 7, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 12, height: 8)
                                .background(Color.blue)
                                .cornerRadius(2)
                            
                            if let duration = preview.duration {
                                Text("\(duration)m")
                                    .font(.system(size: 7, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                } else if workoutSession != nil {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 4, height: 4)
                }
            }
            .frame(width: 45, height: 45)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(workoutSession != nil ? Color.blue.opacity(0.1) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(calendar.isDateInToday(date) ? Color.blue : Color.clear, lineWidth: 2)
                    )
            )
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
            
            let abbreviatedName = session.name.components(separatedBy: " ").compactMap { $0.first }.map(String.init).joined()
            
            await MainActor.run {
                workoutPreview = WorkoutPreviewData(
                    abbreviatedName: String(abbreviatedName.prefix(3)).uppercased(),
                    exerciseCount: uniqueExercises.count,
                    duration: session.durationMinutes
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
                            Text("No sets recorded")
                                .font(.title3)
                                .foregroundColor(.secondary)
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
                Text("Set \(set.setNumber): \(String(format: "%.1f", set.weightKg))kg × \(set.reps)")
                    .font(.title3)
                    .fontWeight(.medium)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}