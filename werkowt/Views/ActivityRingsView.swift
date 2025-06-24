import SwiftUI

struct ActivityRingsView: View {
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let goals: MacroGoals
    
    @State private var animateRings = false
    
    private var caloriesProgress: Double {
        guard goals.calories > 0 else { return 0 }
        return min(calories / goals.calories, 1.0)
    }
    
    private var proteinProgress: Double {
        guard goals.protein > 0 else { return 0 }
        return min(protein / goals.protein, 1.0)
    }
    
    private var carbsProgress: Double {
        guard goals.carbs > 0 else { return 0 }
        return min(carbs / goals.carbs, 1.0)
    }
    
    private var fatProgress: Double {
        guard goals.fat > 0 else { return 0 }
        return min(fat / goals.fat, 1.0)
    }
    
    var body: some View {
        ZStack {
            // Outer ring - Calories (Red)
            ActivityRing(
                progress: animateRings ? caloriesProgress : 0,
                color: .red,
                lineWidth: 8,
                radius: 54
            )
            
            // Second ring - Carbs (Orange)
            ActivityRing(
                progress: animateRings ? carbsProgress : 0,
                color: .orange,
                lineWidth: 8,
                radius: 42
            )
            
            // Third ring - Protein (Green)
            ActivityRing(
                progress: animateRings ? proteinProgress : 0,
                color: .green,
                lineWidth: 8,
                radius: 30
            )
            
            // Inner ring - Fat (Purple)
            ActivityRing(
                progress: animateRings ? fatProgress : 0,
                color: .purple,
                lineWidth: 8,
                radius: 18
            )
            
            // No center text - keep it clean
        }
        .frame(width: 120, height: 120)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).delay(0.2)) {
                animateRings = true
            }
        }
    }
}

struct ActivityRing: View {
    let progress: Double
    let color: Color
    let lineWidth: CGFloat
    let radius: CGFloat
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(color.opacity(0.2), style: StrokeStyle(lineWidth: lineWidth))
                .frame(width: radius * 2, height: radius * 2)
            
            // Progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .frame(width: radius * 2, height: radius * 2)
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.8, dampingFraction: 0.8), value: progress)
        }
    }
}

struct MacroLegend: View {
    let goals: MacroGoals
    let current: (calories: Double, protein: Double, carbs: Double, fat: Double)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Calories")
                    .foregroundColor(.red)
                    .fontWeight(.medium)
                Spacer()
                Text("\(Int(goals.calories))")
                    .foregroundColor(.red)
                    .fontWeight(.semibold)
            }
            .font(.subheadline)
            
            HStack {
                Text("Carbs")
                    .foregroundColor(.orange)
                    .fontWeight(.medium)
                Spacer()
                Text("\(Int(goals.carbs))g")
                    .foregroundColor(.orange)
                    .fontWeight(.semibold)
            }
            .font(.subheadline)
            
            HStack {
                Text("Protein")
                    .foregroundColor(.green)
                    .fontWeight(.medium)
                Spacer()
                Text("\(Int(goals.protein))g")
                    .foregroundColor(.green)
                    .fontWeight(.semibold)
            }
            .font(.subheadline)
            
            HStack {
                Text("Fat")
                    .foregroundColor(.purple)
                    .fontWeight(.medium)
                Spacer()
                Text("\(Int(goals.fat))g")
                    .foregroundColor(.purple)
                    .fontWeight(.semibold)
            }
            .font(.subheadline)
        }
    }
}

// Removed CompactMacroLine - no longer needed

#Preview {
    VStack(spacing: 40) {
        ActivityRingsView(
            calories: 1600,
            protein: 120,
            carbs: 180,
            fat: 60,
            goals: MacroGoals(calories: 2000, protein: 150, carbs: 200, fat: 80)
        )
        
        MacroLegend(
            goals: MacroGoals(calories: 2000, protein: 150, carbs: 200, fat: 80),
            current: (calories: 1600, protein: 120, carbs: 180, fat: 60)
        )
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    .padding()
}