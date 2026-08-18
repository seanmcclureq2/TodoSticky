import SwiftUI

struct AddItemView: View {
    @ObservedObject var store: TodoStore
    @State private var text = ""
    @State private var pendingDueDate: Date?

    var body: some View {
        HStack(spacing: 6) {
            TextField("Add a task…", text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .onSubmit(addItem)

            DueDatePickerMenu(date: pendingDueDate) { newDate in
                pendingDueDate = newDate
            }

            Button(action: addItem) {
                Image(systemName: "plus.circle.fill")
            }
            .buttonStyle(.plain)
            .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(8)
    }

    private func addItem() {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        store.addItem(text: text, dueDate: pendingDueDate)
        text = ""
        pendingDueDate = nil
    }
}
