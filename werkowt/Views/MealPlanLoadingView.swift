import SwiftUI

struct MealPlanLoadingView: View {
    @State private var currentStepIndex = 0
    @State private var progress: Double = 60.0
    @State private var animationOffset: CGFloat = 0
    
    private let steps = [
        "Analyzing your preferences...",
        "Selecting perfect recipes...",
        "Calculating nutrition targets...",
        "Creating shopping list...",
        "Finalizing your meal plan..."
    ]
    
    private let timer = Timer.publish(every: 8.0, on: .main, in: .common).autoconnect()
    private let progressTimer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                VStack(spacing: 32) {
                // Unified Timer + AI Icon Component
                VStack(spacing: 16) {
                    ZStack {
                        // Background circle
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                            .frame(width: 120, height: 120)
                        
                        // Progress arc
                        Circle()
                            .trim(from: 0, to: progress / 60.0)
                            .stroke(
                                LinearGradient(
                                    colors: [.blue, .blue.opacity(0.6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 8, lineCap: .round)
                            )
                            .frame(width: 120, height: 120)
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 0.1), value: progress)
                        
                        // AI icon in center with timer overlay
                        VStack(spacing: 4) {
                            Image(systemName: "wand.and.stars")
                                .font(.system(size: 28, weight: .medium))
                                .foregroundColor(.blue)
                                .scaleEffect(1.0 + sin(animationOffset) * 0.1)
                                .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: animationOffset)
                            
                            Text("\(Int(progress))s")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Text("AI Meal Planning")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                
                // Progress Steps
                VStack(spacing: 20) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(stepColor(for: index))
                                    .frame(width: 32, height: 32)
                                
                                if index < currentStepIndex {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                } else if index == currentStepIndex {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.7)
                                } else {
                                    Text("\(index + 1)")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                }
                            }
                            
                            Text(step)
                                .font(.subheadline)
                                .fontWeight(index == currentStepIndex ? .semibold : .medium)
                                .foregroundColor(index <= currentStepIndex ? .primary : .secondary)
                                .animation(.easeInOut(duration: 0.3), value: currentStepIndex)
                            
                            Spacer()
                        }
                        .opacity(index <= currentStepIndex ? 1.0 : 0.6)
                        .animation(.easeInOut(duration: 0.5), value: currentStepIndex)
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer()
                Spacer()
            }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .shadow(radius: 20)
            )
            .padding()
        }
        .onReceive(timer) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                if currentStepIndex < steps.count - 1 {
                    currentStepIndex += 1
                }
            }
        }
        .onReceive(progressTimer) { _ in
            if progress > 0 {
                progress -= 0.1
            }
        }
        .onAppear {
            animationOffset = 1.0
        }
    }
    
    private func stepColor(for index: Int) -> Color {
        if index < currentStepIndex {
            return .green
        } else if index == currentStepIndex {
            return .blue
        } else {
            return .gray.opacity(0.4)
        }
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.1)
            .ignoresSafeArea()
        
        MealPlanLoadingView()
    }
}