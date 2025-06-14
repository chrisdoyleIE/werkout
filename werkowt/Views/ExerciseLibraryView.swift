import SwiftUI

struct ExerciseLibraryView: View {
    @EnvironmentObject var exerciseDataManager: ExerciseDataManager
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            VStack {
                // Search bar
                SearchBar(text: $searchText)
                    .padding(.horizontal)
                
                ScrollView {
                    LazyVStack(spacing: 16) {
                        if searchText.isEmpty {
                            // Show muscle groups when not searching
                            ForEach(exerciseDataManager.muscleGroups, id: \.id) { muscleGroup in
                                MuscleGroupSection(muscleGroup: muscleGroup)
                            }
                        } else {
                            // Show search results
                            let searchResults = exerciseDataManager.searchExercises(query: searchText)
                            if searchResults.isEmpty {
                                VStack(spacing: 8) {
                                    Image(systemName: "magnifyingglass")
                                        .font(.largeTitle)
                                        .foregroundColor(.secondary)
                                    Text("No exercises found")
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.top, 40)
                            } else {
                                ForEach(searchResults, id: \.id) { exercise in
                                    ExerciseCard(exercise: exercise)
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Exercises")
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
                .textFieldStyle(PlainTextFieldStyle())
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct MuscleGroupSection: View {
    let muscleGroup: MuscleGroup
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: { isExpanded.toggle() }) {
                HStack {
                    Text(muscleGroup.emoji)
                        .font(.title2)
                    
                    Text(muscleGroup.name.uppercased())
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                ForEach(muscleGroup.exercises, id: \.id) { exercise in
                    ExerciseCard(exercise: exercise)
                }
            }
        }
    }
}

struct ExerciseCard: View {
    let exercise: Exercise
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(exercise.name)
                .font(.headline)
                .fontWeight(.medium)
            
            Text(exercise.instructions)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}