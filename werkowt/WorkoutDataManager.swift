import Foundation
import Supabase

class WorkoutDataManager: ObservableObject {
    @Published var workoutSessions: [WorkoutSession] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let supabase = SupabaseManager.shared.client
    
    static let shared = WorkoutDataManager()
    
    private init() {}
    
    // MARK: - Workout Sessions
    
    func createWorkoutSession(name: String) async throws -> WorkoutSession {
        let session = WorkoutSession(
            id: UUID(),
            userId: try await getCurrentUserId(),
            name: name,
            startedAt: Date(),
            endedAt: nil,
            durationMinutes: nil,
            createdAt: Date()
        )
        
        try await supabase
            .from("workout_sessions")
            .insert(session)
            .execute()
        
        await MainActor.run {
            workoutSessions.append(session)
        }
        
        return session
    }
    
    func finishWorkoutSession(_ session: WorkoutSession) async throws {
        let endTime = Date()
        let duration = Int(endTime.timeIntervalSince(session.startedAt) / 60)
        
        struct UpdateData: Codable {
            let ended_at: String
            let duration_minutes: Int
        }
        
        let updateData = UpdateData(
            ended_at: endTime.ISO8601Format(),
            duration_minutes: duration
        )
        
        try await supabase
            .from("workout_sessions")
            .update(updateData)
            .eq("id", value: session.id)
            .execute()
        
        await loadWorkoutSessions()
    }
    
    func loadWorkoutSessions() async {
        await MainActor.run { isLoading = true }
        
        do {
            let response: [WorkoutSession] = try await supabase
                .from("workout_sessions")
                .select()
                .order("started_at", ascending: false)
                .execute()
                .value
            
            await MainActor.run {
                workoutSessions = response
                isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = error
                isLoading = false
            }
        }
    }
    
    // MARK: - Sets
    
    func addSet(_ set: WorkoutSet) async throws {
        try await supabase
            .from("sets")
            .insert(set)
            .execute()
    }
    
    func getSets(for workoutSessionId: UUID) async throws -> [WorkoutSet] {
        let response: [WorkoutSet] = try await supabase
            .from("sets")
            .select()
            .eq("workout_session_id", value: workoutSessionId)
            .order("set_number", ascending: true)
            .execute()
            .value
        
        return response
    }
    
    func getPreviousSessionData(for exerciseId: String) async throws -> PreviousSessionData? {
        // Get the most recent completed workout session that included this exercise
        let sessionsResponse: [WorkoutSession] = try await supabase
            .from("workout_sessions")
            .select()
            .order("started_at", ascending: false)
            .limit(20)
            .execute()
            .value
            
        // Filter completed sessions (those with ended_at) in Swift
        let completedSessions = sessionsResponse.filter { $0.endedAt != nil }
        
        for session in completedSessions {
            let sets: [WorkoutSet] = try await supabase
                .from("sets")
                .select()
                .eq("workout_session_id", value: session.id)
                .eq("exercise_id", value: exerciseId)
                .order("set_number", ascending: true)
                .execute()
                .value
            
            if !sets.isEmpty {
                return PreviousSessionData(
                    exerciseId: exerciseId,
                    sets: sets,
                    sessionDate: session.endedAt ?? session.startedAt
                )
            }
        }
        
        return nil
    }
    
    // MARK: - Personal Records
    
    func getPersonalRecord(for exerciseId: String) async throws -> PersonalRecord? {
        let response: [PersonalRecord] = try await supabase
            .from("personal_records")
            .select()
            .eq("exercise_id", value: exerciseId)
            .execute()
            .value
        
        return response.first
    }
    
    func getAllPersonalRecords() async throws -> [PersonalRecord] {
        let response: [PersonalRecord] = try await supabase
            .from("personal_records")
            .select()
            .order("achieved_at", ascending: false)
            .execute()
            .value
        
        return response
    }
    
    // MARK: - Analytics
    
    func getWeeklyVolume() async throws -> [String: Int] {
        let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        
        let sets: [WorkoutSet] = try await supabase
            .from("sets")
            .select("*, workout_sessions!inner(started_at)")
            .gte("workout_sessions.started_at", value: oneWeekAgo)
            .execute()
            .value
        
        var volumeByMuscleGroup: [String: Int] = [:]
        
        for set in sets {
            if let muscleGroup = ExerciseDataManager.shared.getMuscleGroup(for: set.exerciseId) {
                volumeByMuscleGroup[muscleGroup.name, default: 0] += 1
            }
        }
        
        return volumeByMuscleGroup
    }
    
    func getProgressData(for exerciseId: String, days: Int = 90) async throws -> [WorkoutSet] {
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        
        let sets: [WorkoutSet] = try await supabase
            .from("sets")
            .select("*, workout_sessions!inner(started_at)")
            .eq("exercise_id", value: exerciseId)
            .gte("workout_sessions.started_at", value: startDate)
            .order("completed_at", ascending: true)
            .execute()
            .value
        
        return sets
    }
    
    // MARK: - Helper Methods
    
    private func getCurrentUserId() async throws -> UUID {
        guard let userId = await AuthManager.shared.userId else {
            throw WorkoutDataError.notAuthenticated
        }
        return userId
    }
}

enum WorkoutDataError: Error, LocalizedError {
    case notAuthenticated
    case sessionNotFound
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User not authenticated"
        case .sessionNotFound:
            return "Workout session not found"
        case .invalidData:
            return "Invalid workout data"
        }
    }
}