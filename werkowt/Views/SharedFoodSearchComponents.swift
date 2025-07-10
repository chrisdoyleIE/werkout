import SwiftUI

// MARK: - Shared Food Search Components

struct SharedFoodSearchBar: View {
    @Binding var searchText: String
    let placeholder: String
    let onClear: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField(placeholder, text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !searchText.isEmpty {
                Button(action: onClear) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct SharedFoodSearchSection<Content: View>: View {
    let title: String
    @ViewBuilder let items: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.horizontal)
            
            VStack(spacing: 8) {
                items()
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
}

struct SharedRecentItemRow: View {
    let item: RecentFoodItem
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: item.isMeal ? "square.stack.3d.up.fill" : "circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.primary.opacity(0.7))
                    .frame(width: 32)
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(item.subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Time since last used
                Text(item.lastUsed.relativeTime)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray5), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SharedDatabaseFoodRow: View {
    let food: FoodItem
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Verified badge or generic icon
                if food.isVerified {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.primary.opacity(0.8))
                        .frame(width: 32)
                } else {
                    Image(systemName: "circle")
                        .font(.system(size: 20))
                        .foregroundColor(.primary.opacity(0.5))
                        .frame(width: 32)
                }
                
                // Food info
                VStack(alignment: .leading, spacing: 4) {
                    Text(food.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text("Per 100g: \(Int(food.caloriesPer100g)) cal • P: \(Int(food.proteinPer100g))g")
                        .font(.caption)
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

struct SharedCreateOptionsSection: View {
    let searchText: String
    let onCreateFood: () -> Void
    let onCreateMeal: () -> Void
    
    var body: some View {
        if !searchText.isEmpty {
            SharedFoodSearchSection(
                title: "Can't find it?",
                items: {
                    VStack(spacing: 8) {
                        SharedCreateFoodRow(foodName: searchText, onTap: onCreateFood)
                        SharedCreateMealRow(onTap: onCreateMeal)
                    }
                }
            )
        }
    }
}

struct SharedCreateFoodRow: View {
    let foodName: String
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.primary)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Create new food")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text("\"\(foodName)\"")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.primary.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SharedCreateMealRow: View {
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: "square.stack.3d.up.badge.plus")
                    .font(.system(size: 20))
                    .foregroundColor(.primary)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Create new meal")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text("Combine multiple foods")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.primary.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Empty States

struct SharedEmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.5))
            
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}

struct SharedNoResultsView: View {
    let query: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "questionmark.circle")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.5))
            
            Text("No results for \"\(query)\"")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Try a different search or create a new food")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

struct FoodLibraryItemRow: View {
    let food: FoodItem
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Food icon
                Image(systemName: food.isVerified ? "checkmark.seal.fill" : "circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(food.isVerified ? .primary : .primary.opacity(0.7))
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
                
                // Browse/edit icon
                Image(systemName: "chevron.right")
                    .font(.system(size: 16))
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

// MARK: - Helper Extensions (if not already defined elsewhere)

// relativeTime extension is defined in ManualFoodSearchView.swift