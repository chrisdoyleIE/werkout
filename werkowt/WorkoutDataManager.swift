import Foundation
import Supabase
import os

class WorkoutDataManager: ObservableObject {
    @Published var workoutSessions: [WorkoutSession] = []
    @Published var bodyWeightEntries: [BodyWeightEntry] = []
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
    
    func logGymClass(type: String, durationMinutes: Int) async throws {
        let now = Date()
        let endTime = now.addingTimeInterval(TimeInterval(durationMinutes * 60))
        
        let session = WorkoutSession(
            id: UUID(),
            userId: try await getCurrentUserId(),
            name: "\(type) Class",
            startedAt: now,
            endedAt: endTime,
            durationMinutes: durationMinutes,
            createdAt: now
        )
        
        try await supabase
            .from("workout_sessions")
            .insert(session)
            .execute()
        
        await MainActor.run {
            workoutSessions.insert(session, at: 0) // Add to beginning for chronological order
        }
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
            .from("workout_sets")
            .insert(set)
            .execute()
    }
    
    func deleteSet(_ set: WorkoutSet) async throws {
        try await supabase
            .from("workout_sets")
            .delete()
            .eq("id", value: set.id)
            .execute()
    }
    
    func getSets(for workoutSessionId: UUID) async throws -> [WorkoutSet] {
        let response: [WorkoutSet] = try await supabase
            .from("workout_sets")
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
                .from("workout_sets")
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
    
    func checkAndUpdatePersonalRecord(for set: WorkoutSet) async throws {
        // Only process personal records for weight-based exercises
        guard let weight = set.weightKg, let reps = set.reps else { return }
        
        let userId = try await getCurrentUserId()
        
        // Calculate the estimated 1RM using Epley formula: weight * (1 + reps/30)
        let estimated1RM = weight * (1 + Double(reps) / 30.0)
        
        do {
            let existingPR = try await getPersonalRecord(for: set.exerciseId)
            
            if let pr = existingPR {
                // Calculate existing 1RM
                let existing1RM = pr.maxWeightKg * (1 + Double(pr.reps) / 30.0)
                
                // Only update if new estimated 1RM is higher
                if estimated1RM > existing1RM {
                    try await updatePersonalRecord(
                        exerciseId: set.exerciseId,
                        weight: weight,
                        reps: reps
                    )
                }
            } else {
                // No existing PR, create new one
                try await createPersonalRecord(
                    exerciseId: set.exerciseId,
                    weight: weight,
                    reps: reps
                )
            }
        } catch {
            Logger.error("Failed to check/update personal record: \(error)", category: Logger.data)
        }
    }
    
    private func createPersonalRecord(exerciseId: String, weight: Double, reps: Int) async throws {
        let userId = try await getCurrentUserId()
        
        let newPR = PersonalRecord(
            id: UUID(),
            userId: userId,
            exerciseId: exerciseId,
            maxWeightKg: weight,
            reps: reps,
            achievedAt: Date()
        )
        
        try await supabase
            .from("personal_records")
            .insert(newPR)
            .execute()
    }
    
    private func updatePersonalRecord(exerciseId: String, weight: Double, reps: Int) async throws {
        struct UpdateData: Codable {
            let max_weight_kg: Double
            let reps: Int
            let achieved_at: String
        }
        
        let updateData = UpdateData(
            max_weight_kg: weight,
            reps: reps,
            achieved_at: Date().ISO8601Format()
        )
        
        try await supabase
            .from("personal_records")
            .update(updateData)
            .eq("exercise_id", value: exerciseId)
            .execute()
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
            .from("workout_sets")
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
            .from("workout_sets")
            .select("*, workout_sessions!inner(started_at)")
            .eq("exercise_id", value: exerciseId)
            .gte("workout_sessions.started_at", value: startDate)
            .order("completed_at", ascending: true)
            .execute()
            .value
        
        return sets
    }
    
    // MARK: - Body Weight Tracking
    
    func addBodyWeightEntry(weightKg: Double, notes: String? = nil) async throws {
        let userId = try await getCurrentUserId()
        
        let entry = BodyWeightEntry(
            userId: userId,
            weightKg: weightKg,
            notes: notes
        )
        
        try await supabase
            .from("body_weight_entries")
            .insert(entry)
            .execute()
        
        await MainActor.run {
            bodyWeightEntries.insert(entry, at: 0) // Add to beginning for chronological order
        }
    }
    
    func loadBodyWeightEntries() async {
        do {
            let response: [BodyWeightEntry] = try await supabase
                .from("body_weight_entries")
                .select()
                .order("recorded_at", ascending: false)
                .execute()
                .value
            
            await MainActor.run {
                bodyWeightEntries = response
            }
        } catch {
            await MainActor.run {
                self.error = error
            }
        }
    }
    
    func deleteBodyWeightEntry(_ entry: BodyWeightEntry) async throws {
        try await supabase
            .from("body_weight_entries")
            .delete()
            .eq("id", value: entry.id)
            .execute()
        
        await MainActor.run {
            bodyWeightEntries.removeAll { $0.id == entry.id }
        }
    }
    
    func getRecentBodyWeightEntries(days: Int = 90) async throws -> [BodyWeightEntry] {
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        
        let response: [BodyWeightEntry] = try await supabase
            .from("body_weight_entries")
            .select()
            .gte("recorded_at", value: startDate)
            .order("recorded_at", ascending: true)
            .execute()
            .value
        
        return response
    }
    
    // MARK: - Helper Methods
    
    private func getCurrentUserId() async throws -> UUID {
        guard let userId = await AuthManager.shared.userId else {
            throw WorkoutError.notAuthenticated
        }
        return userId
    }
}