import SwiftUI

struct DueDatePickerMenu: View {
    var date: Date?
    var onChange: (Date?) -> Void

    @State private var showingCustomPicker = false
    @State private var customDate = Date()

    var body: some View {
        Menu {
            Button("Today") { onChange(DueDateQuickOption.today.resolvedDate()) }
            Button("Tomorrow") { onChange(DueDateQuickOption.tomorrow.resolvedDate()) }
            Button("End of Week") { onChange(DueDateQuickOption.endOfWeek.resolvedDate()) }
            Button("Custom…") {
                customDate = date ?? Date()
                showingCustomPicker = true
            }
            if date != nil {
                Divider()
                Button("Clear Due Date", role: .destructive) { onChange(nil) }
            }
        } label: {
            Image(systemName: date == nil ? "calendar" : "calendar.badge.clock")
                .foregroundStyle(date == nil ? Color.secondary : Color.accentColor)
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
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
