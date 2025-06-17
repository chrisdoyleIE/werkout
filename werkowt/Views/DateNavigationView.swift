import SwiftUI

struct DateNavigationView: View {
    @Binding var selectedDate: Date
    let onPreviousDay: () -> Void
    let onNextDay: () -> Void
    let showEditButton: Bool
    let onEditTap: (() -> Void)?
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE - MMMM d"
        return formatter
    }()
    
    init(
        selectedDate: Binding<Date>,
        onPreviousDay: @escaping () -> Void,
        onNextDay: @escaping () -> Void,
        showEditButton: Bool = false,
        onEditTap: (() -> Void)? = nil
    ) {
        self._selectedDate = selectedDate
        self.onPreviousDay = onPreviousDay
        self.onNextDay = onNextDay
        self.showEditButton = showEditButton
        self.onEditTap = onEditTap
    }
    
    var body: some View {
        HStack {
            Button(action: onPreviousDay) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .padding()
            }
            
            Spacer()
            
            Text(dateFormatter.string(from: selectedDate))
                .font(.headline)
                .fontWeight(.semibold)
            
            Spacer()
            
            Button(action: onNextDay) {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .padding()
            }
            
            if showEditButton, let editAction = onEditTap {
                Button(action: editAction) {
                    HStack(spacing: 6) {
                        Image(systemName: "flag.fill")
                            .font(.subheadline)
                        Text("Edit")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(16)
                }
            }
        }
    }
}

#Preview {
    DateNavigationView(
        selectedDate: .constant(Date()),
        onPreviousDay: {},
        onNextDay: {},
        showEditButton: true,
        onEditTap: {}
    )
    .padding()
}