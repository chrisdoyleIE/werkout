import SwiftUI

struct HomeView: View {
    @EnvironmentObject var activeWorkout: ActiveWorkout
    @EnvironmentObject var workoutDataManager: WorkoutDataManager
    @State private var showingWorkoutCreator = false
    @State private var showingLiveWorkout = false
    @State private var selectedDate = Date()
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Text("WERKOUT")
                    .font(.largeTitle)
                    .fontWeight(.black)
                
                Text("\(workoutDataManager.workoutSessions.count) workouts")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            .padding(.top)
            
            // Mini calendar
            VStack(spacing: 16) {
                Text("This Week")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                WeekCalendarView(
                    selectedDate: $selectedDate,
                    workoutSessions: workoutDataManager.workoutSessions
                )
            }
            
            Spacer()
            
            // Start Workout Button
            Button(action: {
                showingWorkoutCreator = true
            }) {
                Text("START WORKOUT")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(Color.blue)
                    .cornerRadius(12)
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

