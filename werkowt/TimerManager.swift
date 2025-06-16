import Foundation

// MARK: - Generic Timer
class WorkoutTimer: ObservableObject {
    @Published var timeRemaining: Int = 0
    @Published var isRunning: Bool = false
    
    private var timer: Timer?
    private(set) var totalDuration: Int = 0
    private let persistsTotalDuration: Bool
    
    init(persistsTotalDuration: Bool = false) {
        self.persistsTotalDuration = persistsTotalDuration
    }
    
    func start(duration: Int) {
        stop()
        
        totalDuration = duration
        timeRemaining = duration
        isRunning = true
        
        timer = Timer(timeInterval: 1.0, repeats: true) { _ in
            DispatchQueue.main.async {
                if self.timeRemaining > 0 {
                    self.timeRemaining -= 1
                } else {
                    self.stop()
                }
            }
        }
        
        RunLoop.main.add(timer!, forMode: .common)
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        timeRemaining = 0
        
        if !persistsTotalDuration {
            totalDuration = 0
        }
    }
    
    func pause() {
        timer?.invalidate()
        timer = nil
        isRunning = false
    }
    
    func resume() {
        guard timeRemaining > 0 else { return }
        
        isRunning = true
        
        timer = Timer(timeInterval: 1.0, repeats: true) { _ in
            DispatchQueue.main.async {
                if self.timeRemaining > 0 {
                    self.timeRemaining -= 1
                } else {
                    self.stop()
                }
            }
        }
        
        RunLoop.main.add(timer!, forMode: .common)
    }
    
    var formattedTime: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Timer Type Aliases for Convenience
typealias RestTimer = WorkoutTimer
typealias ExerciseTimer = WorkoutTimer