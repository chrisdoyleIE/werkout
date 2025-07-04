import SwiftUI

struct UnifiedActionWidget: View {
    let onWorkoutTap: () -> Void
    let onFoodTap: (() -> Void)?
    let onWeightTap: () -> Void
    let compactStyle: Bool
    
    init(onWorkoutTap: @escaping () -> Void, onFoodTap: (() -> Void)? = nil, onWeightTap: @escaping () -> Void, compactStyle: Bool = false) {
        self.onWorkoutTap = onWorkoutTap
        self.onFoodTap = onFoodTap
        self.onWeightTap = onWeightTap
        self.compactStyle = compactStyle
    }
    
    var body: some View {
        if compactStyle {
            compactActionView
        } else {
            originalActionView
        }
    }
    
    private var compactActionView: some View {
        HStack(spacing: 8) {
            CompactActionButton(
                icon: "figure.strengthtraining.functional",
                title: "Training",
                action: onWorkoutTap
            )
            
            if let foodAction = onFoodTap {
                CompactActionButton(
                    icon: "fork.knife",
                    title: "Food",
                    action: foodAction
                )
            }
            
            CompactActionButton(
                icon: "figure.stand",
                title: "Weight",
                action: onWeightTap
            )
        }
    }
    
    private var originalActionView: some View {
        VStack(spacing: 8) {
            // Header label
            Text("Track Your")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.8))
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
            
            // Action segments
            HStack(spacing: 0) {
                ActionSegment(
                    icon: "figure.strengthtraining.functional",
                    title: "WORKOUT",
                    action: onWorkoutTap
                )
                
                if let foodAction = onFoodTap {
                    Divider()
                        .frame(height: 50)
                        .foregroundColor(.white.opacity(0.3))
                    ActionSegment(
                        icon: "fork.knife",
                        title: "FOOD",
                        action: foodAction
                    )
                }
                
                Divider()
                    .frame(height: 50)
                    .foregroundColor(.white.opacity(0.3))
                
                ActionSegment(
                    icon: "figure.stand",
                    title: "WEIGHT",
                    action: onWeightTap
                )
            }
        }
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
}

struct ActionSegment: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
                action()
            }
        }) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                Color.white.opacity(isPressed ? 0.2 : 0.0)
            )
            .cornerRadius(isPressed ? 12 : 0)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.95 : 1.0)
    }
}

struct CompactActionButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
                action()
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isPressed ? Color.blue.opacity(0.8) : Color.blue)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.96 : 1.0)
    }
}

#Preview {
    VStack(spacing: 20) {
        // Original style
        UnifiedActionWidget(
            onWorkoutTap: { print("Workout tapped") },
            onFoodTap: { print("Food tapped") },
            onWeightTap: { print("Weight tapped") }
        )
        .padding()
        
        // Compact style
        UnifiedActionWidget(
            onWorkoutTap: { print("Workout tapped") },
            onFoodTap: { print("Food tapped") },
            onWeightTap: { print("Weight tapped") },
            compactStyle: true
        )
        .padding()
        
        // Individual compact button for testing
        CompactActionButton(
            icon: "figure.strengthtraining.functional",
            title: "Training",
            action: { print("Compact button") }
        )
        .padding()
    }
    .padding()
}
