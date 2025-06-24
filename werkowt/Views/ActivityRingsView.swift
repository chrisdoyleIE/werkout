import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    // CSS colors from the design
    static let caloriesColor = Color(hex: "333333")
    static let proteinColor = Color(hex: "ff6b6b")
    static let carbsColor = Color(hex: "ffa500")
    static let fatColor = Color(hex: "4dabf7")
}

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
            // Outer ring - Calories (#333) - Top position
            ActivityRingWithEmoji(
                progress: animateRings ? caloriesProgress : 0,
                color: .caloriesColor,
                lineWidth: 16,
                radius: 140,
                emoji: "🔥",
                value: "\(Int(calories)) cal",
                position: .top,
                isCalories: true
            )
            
            // Second ring - Protein (#ff6b6b) - Left position  
            ActivityRingWithEmoji(
                progress: animateRings ? proteinProgress : 0,
                color: .proteinColor,
                lineWidth: 16,
                radius: 110,
                emoji: "🥩",
                value: "\(Int(protein))g",
                position: .left,
                isCalories: false
            )
            
            // Third ring - Carbs (#ffa500) - Right position
            ActivityRingWithEmoji(
                progress: animateRings ? carbsProgress : 0,
                color: .carbsColor,
                lineWidth: 16,
                radius: 80,
                emoji: "🌾",
                value: "\(Int(carbs))g",
                position: .right,
                isCalories: false
            )
            
            // Inner ring - Fat (#4dabf7) - Bottom position
            ActivityRingWithEmoji(
                progress: animateRings ? fatProgress : 0,
                color: .fatColor,
                lineWidth: 16,
                radius: 50,
                emoji: "🥑",
                value: "\(Int(fat))g",
                position: .bottom,
                isCalories: false
            )
            
            // Center calories remaining - sized to fit innermost ring
            VStack(spacing: 0) {
                Text("\(Int(goals.calories - calories))")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                Text("calories left")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            .multilineTextAlignment(.center)
        }
        .frame(width: 300, height: 300)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).delay(0.2)) {
                animateRings = true
            }
        }
    }
}

struct ActivityRingWithEmoji: View {
    let progress: Double
    let color: Color
    let lineWidth: CGFloat
    let radius: CGFloat
    let emoji: String
    let value: String
    let position: RingPosition
    let isCalories: Bool
    
    var body: some View {
        ZStack {
            // Background ring - always grey
            Circle()
                .stroke(Color.gray.opacity(0.3), style: StrokeStyle(lineWidth: lineWidth))
                .frame(width: radius * 2, height: radius * 2)
            
            // Progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .frame(width: radius * 2, height: radius * 2)
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.8, dampingFraction: 0.8), value: progress)
            
            // Combined emoji + value pill positioned on the ring
            let pillRadians = position.angle * .pi / 180
            let pillX = radius * cos(pillRadians)
            let pillY = radius * sin(pillRadians)
            
            Text("\(emoji) \(value)")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isCalories ? .white : color)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(isCalories ? Color.black : Color.white)
                )
                .offset(x: pillX, y: pillY)
        }
    }
}

enum RingPosition {
    case top, right, bottom, left
    
    var angle: Double {
        switch self {
        case .top: return -90      // 12 o'clock
        case .right: return 0      // 3 o'clock
        case .bottom: return 90    // 6 o'clock
        case .left: return 180     // 9 o'clock
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


#Preview {
    VStack(spacing: 40) {
        ActivityRingsView(
            calories: 1600,
            protein: 120,
            carbs: 180,
            fat: 60,
            goals: MacroGoals(calories: 2000, protein: 150, carbs: 200, fat: 80)
        )
    }
    .padding()
}
