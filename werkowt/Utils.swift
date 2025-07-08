import Foundation

class Debouncer {
    private var workItem: DispatchWorkItem?
    
    func debounce(delay: TimeInterval = 0.5, action: @escaping () -> Void) {
        workItem?.cancel()
        let newWorkItem = DispatchWorkItem(block: action)
        workItem = newWorkItem
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: newWorkItem)
    }
}