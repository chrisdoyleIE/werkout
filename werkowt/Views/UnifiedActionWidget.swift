import SwiftUI

struct UnifiedActionWidget: View {
    let onWorkoutTap: () -> Void
    let onFoodTap: () -> Void
    let onWeightTap: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            // Header label
            Text("Record")
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
                
                Divider()
                    .frame(height: 50)
                    .foregroundColor(.white.opacity(0.3))
                
                ActionSegment(
                    icon: "fork.knife",
                    title: "FOOD",
                    action: onFoodTap
                )
                
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

#Preview {
    VStack(spacing: 20) {
        UnifiedActionWidget(
            onWorkoutTap: { print("Workout tapped") },
            onFoodTap: { print("Food tapped") },
            onWeightTap: { print("Weight tapped") }
        )
        .padding()
        
        // Show individual segment for testing
        ActionSegment(
            icon: "figure.strengthtraining.functional",
            title: "WORKOUT",
            action: { print("Individual segment") }
        )
        .frame(width: 120, height: 80)
        .background(Color.blue)
        .cornerRadius(12)
    }
    .padding()
}
