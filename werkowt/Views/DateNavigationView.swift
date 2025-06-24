import SwiftUI

struct DateNavigationView: View {
    @Binding var selectedDate: Date
    let onPrevious: () -> Void
    let onNext: () -> Void
    let showEditButton: Bool
    let onEditTap: (() -> Void)?
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    init(
        selectedDate: Binding<Date>,
        onPrevious: @escaping () -> Void,
        onNext: @escaping () -> Void,
        showEditButton: Bool = false,
        onEditTap: (() -> Void)? = nil
    ) {
        self._selectedDate = selectedDate
        self.onPrevious = onPrevious
        self.onNext = onNext
        self.showEditButton = showEditButton
        self.onEditTap = onEditTap
    }
    
    var body: some View {
        HStack(spacing: 20) {
            Button(action: onPrevious) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            Text(dateFormatter.string(from: selectedDate))
                .font(.title3)
                .fontWeight(.semibold)
            
            Spacer()
            
            Button(action: onNext) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            
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
        onPrevious: {},
        onNext: {},
        showEditButton: true,
        onEditTap: {}
    )
    .padding()
}