import AppKit
import SwiftUI

struct TodoRowView: View {
    @ObservedObject var store: TodoStore
    let item: TodoItem

    @State private var isAddingSubtask = false
    @State private var newSubtaskText = ""
    @FocusState private var isSubtaskFieldFocused: Bool

    @State private var isEditingText = false

    @State private var isHovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top, spacing: 8) {
                checkbox

                VStack(alignment: .leading, spacing: 2) {
                    if isEditingText {
                        LinkableTextEditor(
                            initialText: item.text,
                            initialLinks: item.links,
                            font: .systemFont(ofSize: 13),
                            onCommit: { newText, newLinks in
                                store.updateText(newText, links: newLinks, for: item)
                                isEditingText = false
                            },
                            onCancel: {
                                isEditingText = false
                            }
                        )
                    } else {
                        // The double-click-to-edit gesture is attached to this extra wrapper
                        // VStack, not directly on the Text — attaching it straight to the Text
                        // would compete with the Text's own native link hover-cursor/click
                        // handling when it contains a hyperlink. Scoping it to only this
                        // (non-editing) branch also keeps it from ever intercepting the
                        // double-click-to-select-word gesture inside LinkableTextEditor above.
                        VStack(alignment: .leading, spacing: 2) {
                            Group {
                                if item.isCompleted {
                                    Text(item.attributedText).foregroundStyle(.secondary)
                                } else {
                                    Text(item.attributedText)
                                }
                            }
                            .font(.system(size: 13))
                            .strikethrough(item.isCompleted)
                            .fixedSize(horizontal: false, vertical: true)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture(count: 2) { isEditingText = true }
                        .onHover { hovering in
                            // SwiftUI's automatic link hover-cursor doesn't reliably show up
                            // inside this custom-windowed setup, so manage it directly.
                            guard !item.links.isEmpty else { return }
                            if hovering {
                                NSCursor.pointingHand.push()
                            } else {
                                NSCursor.pop()
                            }
                        }
                    }

                    if let dueDate = item.effectiveDueDate {
                        Text(dueDate, format: .dateTime.month().day().hour().minute())
                            .font(.system(size: 10))
                            .foregroundStyle(item.isOverdue ? .red : .secondary)
                    }
                }

                Spacer(minLength: 4)

                if !item.isCompleted {
                    Button {
                        isAddingSubtask = true
                        isSubtaskFieldFocused = true
                    } label: {
                        Image(systemName: "plus.circle")
                            .foregroundStyle(.secondary)
                            .accessibilityLabel("Add subtask")
                    }
                    .buttonStyle(.plain)
                    .opacity(isHovering ? 1 : 0)

                    DueDatePickerMenu(date: item.dueDate) { newDate in
                        store.setDueDate(newDate, for: item)
                    }
                    .opacity(isHovering ? 1 : 0)
                }

                Button {
                    store.deleteItem(item)
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("Delete task")
                }
                .buttonStyle(.plain)
                .opacity(isHovering ? 1 : 0)
            }
            .contentShape(Rectangle())
            .onHover { hovering in
                isHovering = hovering
            }

            if !item.sortedSubtasks.isEmpty || isAddingSubtask {
                VStack(alignment: .leading, spacing: 3) {
                    ForEach(item.sortedSubtasks) { subtask in
                        SubtaskRowView(store: store, parent: item, subtask: subtask)
                    }
                    if isAddingSubtask {
                        HStack(spacing: 6) {
                            TextField("Add subtask", text: $newSubtaskText)
                                .textFieldStyle(.plain)
                                .font(.system(size: 12))
                                .focused($isSubtaskFieldFocused)
                                .onSubmit {
                                    store.addSubtask(text: newSubtaskText, to: item)
                                    newSubtaskText = ""
                                    // Keep the field open and focused so Enter can be pressed
                                    // repeatedly to add several subtasks in a row.
                                    isSubtaskFieldFocused = true
                                }
                                .onExitCommand {
                                    isAddingSubtask = false
                                    newSubtaskText = ""
                                }
                            Button {
                                isAddingSubtask = false
                                newSubtaskText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                                    .accessibilityLabel("Cancel adding subtask")
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.leading, 24)
                        .onChange(of: isSubtaskFieldFocused) { _, isFocused in
                            if !isFocused && newSubtaskText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                isAddingSubtask = false
                            }
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var checkbox: some View {
        Button {
            store.toggleCompleted(item)
        } label: {
            Image(systemName: item.isCompleted ? "checkmark.square.fill" : "square")
                .foregroundStyle(item.isCompleted ? .secondary : .primary)
                .accessibilityLabel(item.isCompleted ? "Completed" : "Not completed")
        }
        .buttonStyle(.plain)
    }
}
