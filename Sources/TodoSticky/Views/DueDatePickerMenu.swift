import SwiftUI

struct DueDatePickerMenu: View {
    var date: Date?
    var onChange: (Date?) -> Void

    @State private var showingCustomPicker = false
    @State private var customDate = Date()

    var body: some View {
        ZStack {
            Image(systemName: date == nil ? "calendar" : "calendar.badge.clock")
                .foregroundStyle(date == nil ? Color.secondary : Color.accentColor)
                .accessibilityLabel("Set due date")

            DueDateMenuTrigger(
                currentDate: date,
                onSelectQuickOption: { option in
                    onChange(option.resolvedDate())
                },
                onCustom: {
                    customDate = date ?? Date()
                    showingCustomPicker = true
                },
                onClear: {
                    onChange(nil)
                }
            )
        }
        .frame(width: 18, height: 18)
        .popover(isPresented: $showingCustomPicker) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Due Date")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                DatePicker("", selection: $customDate, displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.compact)
                    .labelsHidden()
                HStack {
                    Spacer()
                    Button("Cancel") {
                        showingCustomPicker = false
                    }
                    Button("Set") {
                        onChange(customDate)
                        showingCustomPicker = false
                    }
                    .keyboardShortcut(.defaultAction)
                }
            }
            .padding(12)
        }
    }
}
