import SwiftUI

struct WorkoutProgressView: View {
    @EnvironmentObject var workoutDataManager: WorkoutDataManager
    @State private var weeklyVolume: [String: Int] = [:]
    @State private var personalRecords: [PersonalRecord] = []
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Weekly Volume
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Weekly Volume")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        if weeklyVolume.isEmpty {
                            Text("No workout data yet")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                        } else {
                            ForEach(Array(weeklyVolume.sorted(by: { $0.value > $1.value })), id: \.key) { muscleGroup, sets in
                                HStack {
                                    Text(muscleGroup)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    
                                    Spacer()
                                    
                                    Text("\(sets) sets")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Personal Records
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Personal Records")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        if personalRecords.isEmpty {
                            Text("Complete workouts to see personal records")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                        } else {
                            ForEach(personalRecords.prefix(10), id: \.id) { record in
                                PersonalRecordRow(record: record)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    Spacer(minLength: 100)
                }
                .padding()
            }
            .navigationTitle("Progress")
            .onAppear {
                loadProgressData()
            }
            .refreshable {
                loadProgressData()
            }
        }
    }
    
    private func loadProgressData() {
        isLoading = true
        
        Task {
            do {
                let volume = try await workoutDataManager.getWeeklyVolume()
                let records = try await workoutDataManager.getAllPersonalRecords()
                
                await MainActor.run {
                    weeklyVolume = volume
                    personalRecords = records
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                }
                print("Failed to load progress data: \(error)")
            }
        }
    }
}

struct PersonalRecordRow: View {
    let record: PersonalRecord
    @EnvironmentObject var exerciseDataManager: ExerciseDataManager
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                if let exercise = exerciseDataManager.getExercise(by: record.exerciseId) {
                    Text(exercise.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                } else {
                    Text(record.exerciseId)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Text(RelativeDateTimeFormatter().localizedString(for: record.achievedAt, relativeTo: Date()))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(record.maxWeightLbs))lbs")
                    .font(.subheadline)
                    .fontWeight(.bold)
                
                Text("\(record.reps) reps")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}