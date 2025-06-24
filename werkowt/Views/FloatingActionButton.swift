import SwiftUI

struct FloatingActionButton: View {
    @State private var isExpanded = false
    let onWorkoutTap: () -> Void
    let onFoodTap: () -> Void
    let onWeightTap: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            if isExpanded {
                // Expanded menu items
                VStack(spacing: 12) {
                    FloatingMenuItem(
                        icon: "figure.stand",
                        label: "Weight",
                        color: .purple,
                        action: {
                            onWeightTap()
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                isExpanded = false
                            }
                        }
                    )
                    
                    FloatingMenuItem(
                        icon: "fork.knife",
                        label: "Food",
                        color: .green,
                        action: {
                            onFoodTap()
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                isExpanded = false
                            }
                        }
                    )
                    
                    FloatingMenuItem(
                        icon: "figure.strengthtraining.functional",
                        label: "Training",
                        color: .blue,
                        action: {
                            onWorkoutTap()
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                isExpanded = false
                            }
                        }
                    )
                }
                .transition(.scale.combined(with: .opacity))
            }
            
            // Main plus button - more native iOS style
            Button(action: {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            }) {
                ZStack {
                    // Blur background
                    Circle()
                        .fill(.thinMaterial)
                        .frame(width: 50, height: 50)
                    
                    Circle()
                        .strokeBorder(Color.blue.opacity(0.2), lineWidth: 0.5)
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: isExpanded ? "xmark" : "plus")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundColor(.blue)
                        .rotationEffect(.degrees(isExpanded ? 45 : 0))
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isExpanded)
                }
            }
            .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .padding(.bottom, 20)
    }
}

struct FloatingMenuItem: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Label
            Text(label)
                .font(.footnote)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Capsule()
                                .strokeBorder(Color.gray.opacity(0.2), lineWidth: 0.5)
                        )
                )
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
            
            // Icon button
            Button(action: {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isPressed = false
                    action()
                }
            }) {
                ZStack {
                    Circle()
                        .fill(.thinMaterial)
                        .frame(width: 44, height: 44)
                    
                    Circle()
                        .strokeBorder(color.opacity(0.2), lineWidth: 0.5)
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .regular))
                        .foregroundColor(color)
                }
            }
            .scaleEffect(isPressed ? 0.9 : 1.0)
        }
    }
}

#Preview {
    ZStack {
        Color(.systemGroupedBackground)
            .ignoresSafeArea()
        
        FloatingActionButton(
            onWorkoutTap: { print("Workout") },
            onFoodTap: { print("Food") },
            onWeightTap: { print("Weight") }
        )
    }
}