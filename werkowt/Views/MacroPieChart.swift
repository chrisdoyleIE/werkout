import SwiftUI

struct MacroPieChart: View {
    let title: String
    let current: Double
    let target: Double
    let unit: String
    let color: Color
    
    private var progress: Double {
        guard target > 0 else { return 0 }
        return min(current / target, 1.0)
    }
    
    private var percentage: Int {
        Int(progress * 100)
    }
    
    var body: some View {
        VStack(spacing: 4) {
            // Pie chart circle
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 3)
                    .frame(width: 32, height: 32)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 32, height: 32)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: progress)
            }
            
            // Label
            Text(title)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            // Current value
            Text("\(Int(current))\(unit)")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            // Target only
            Text("\(Int(target))\(unit)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct HorizontalMacroCharts: View {
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let goals: MacroGoals
    
    var body: some View {
        HStack(spacing: 8) {
            MacroPieChart(
                title: "Cal",
                current: calories,
                target: goals.calories,
                unit: "",
                color: .red
            )
            
            MacroPieChart(
                title: "Protein",
                current: protein,
                target: goals.protein,
                unit: "g",
                color: .blue
            )
            
            MacroPieChart(
                title: "Carbs",
                current: carbs,
                target: goals.carbs,
                unit: "g",
                color: .orange
            )
            
            MacroPieChart(
                title: "Fat",
                current: fat,
                target: goals.fat,
                unit: "g",
                color: .purple
            )
        }
        .frame(height: 90)
        .padding(.vertical, 8)
    }
}

#Preview {
    VStack(spacing: 20) {
        // Individual pie chart
        MacroPieChart(
            title: "Protein",
            current: 90,
            target: 150,
            unit: "g",
            color: .blue
        )
        .frame(width: 80)
        
        // Full horizontal layout
        HorizontalMacroCharts(
            calories: 1600,
            protein: 90,
            carbs: 140,
            fat: 30,
            goals: MacroGoals.default
        )
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    .padding()
}