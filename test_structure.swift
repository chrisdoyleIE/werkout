import SwiftUI

struct TestView: View {
    var body: some View {
        NavigationView {
            ZStack {
                Text("Test")
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private var test: String {
        return "test"
    }
}