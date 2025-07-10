import SwiftUI

struct FoodLibraryView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var supabaseService = SupabaseService.shared
    
    @State private var searchText = ""
    @State private var selectedCategory: FoodCategory = .all
    @State private var recentFoods: [FoodItem] = []
    @State private var searchResults: [FoodItem] = []
    @State private var isSearching = false
    @State private var selectedFood: FoodItem?
    
    private let searchDebouncer = Debouncer()
    
    enum FoodCategory: String, CaseIterable {
        case all = "All"
        case recent = "Recent"
        case favorites = "Favorites"
        case custom = "Custom"
        
        var icon: String {
            switch self {
            case .all: return "list.bullet"
            case .recent: return "clock"
            case .favorites: return "heart"
            case .custom: return "plus.circle"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search foods...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .onChange(of: searchText) { _, newValue in
                            searchDebouncer.debounce {
                                Task {
                                    await performSearch(query: newValue)
                                }
                            }
                        }
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            searchResults = []
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding()
                
                // Category selection
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(FoodCategory.allCases, id: \.self) { category in
                            Button(action: {
                                selectedCategory = category
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: category.icon)
                                        .font(.system(size: 14, weight: .medium))
                                    Text(category.rawValue)
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .foregroundColor(selectedCategory == category ? .white : .primary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(selectedCategory == category ? Color.primary : Color(.systemGray5))
                                .cornerRadius(20)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 16)
                
                // Content
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if !searchText.isEmpty {
                            // Search results
                            if isSearching {
                                ProgressView()
                                    .padding()
                            } else if searchResults.isEmpty {
                                FoodLibraryEmptyStateView(
                                    icon: "magnifyingglass",
                                    title: "No results found",
                                    subtitle: "Try a different search term"
                                )
                                .padding(.top, 40)
                            } else {
                                ForEach(searchResults, id: \.id) { food in
                                    FoodItemRow(food: food) {
                                        selectedFood = food
                                    }
                                }
                            }
                        } else {
                            // Category content
                            switch selectedCategory {
                            case .all:
                                allFoodsContent
                            case .recent:
                                recentFoodsContent
                            case .favorites:
                                favoritesFoodsContent
                            case .custom:
                                customFoodsContent
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .navigationTitle("Food Library")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func performSearch(query: String) async {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            await MainActor.run {
                searchResults = []
                isSearching = false
            }
            return
        }
        
        await MainActor.run {
            isSearching = true
        }
        
        do {
            let results = try await supabaseService.searchFoods(query: query, limit: 20)
            await MainActor.run {
                searchResults = results
                isSearching = false
            }
        } catch {
            await MainActor.run {
                searchResults = []
                isSearching = false
            }
            print("Search error: \(error)")
        }
    }
    
    private var allFoodsContent: some View {
        VStack(spacing: 16) {
            Text("All Foods")
                .font(.system(size: 18, weight: .semibold))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            FoodLibraryEmptyStateView(
                icon: "list.bullet",
                title: "Food Database",
                subtitle: "Browse and search our complete food database"
            )
            .padding(.top, 40)
        }
    }
    
    private var recentFoodsContent: some View {
        VStack(spacing: 16) {
            Text("Recently Used")
                .font(.system(size: 18, weight: .semibold))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if recentFoods.isEmpty {
                FoodLibraryEmptyStateView(
                    icon: "clock",
                    title: "No recent foods",
                    subtitle: "Foods you log will appear here"
                )
                .padding(.top, 40)
            } else {
                ForEach(recentFoods, id: \.id) { food in
                    FoodItemRow(food: food) {
                        selectedFood = food
                    }
                }
            }
        }
    }
    
    private var favoritesFoodsContent: some View {
        VStack(spacing: 16) {
            Text("Favorites")
                .font(.system(size: 18, weight: .semibold))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            FoodLibraryEmptyStateView(
                icon: "heart",
                title: "No favorites yet",
                subtitle: "Star foods to add them here"
            )
            .padding(.top, 40)
        }
    }
    
    private var customFoodsContent: some View {
        VStack(spacing: 16) {
            Text("Custom Foods")
                .font(.system(size: 18, weight: .semibold))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            FoodLibraryEmptyStateView(
                icon: "square.grid.3x3",
                title: "No custom foods",
                subtitle: "Foods you create will appear here for editing"
            )
            .padding(.top, 40)
        }
    }
}

struct FoodItemRow: View {
    let food: FoodItem
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Food icon
                Image(systemName: "circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.primary.opacity(0.7))
                    .frame(width: 32)
                
                // Food info
                VStack(alignment: .leading, spacing: 4) {
                    Text(food.displayName)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text("Per 100g: \(Int(food.caloriesPer100g)) cal • P: \(Int(food.proteinPer100g))g")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct FoodLibraryEmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 36, weight: .light))
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.primary)
            
            Text(subtitle)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}
