import AppKit
import SwiftUI

struct SubtaskRowView: View {
    @ObservedObject var store: TodoStore
    let parent: TodoItem
    let subtask: Subtask

    @State private var isHovering = false
    @State private var isEditingText = false

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Button {
                store.toggleSubtaskCompleted(subtask, in: parent)
            } label: {
                Image(systemName: subtask.isCompleted ? "checkmark.square.fill" : "square")
                    .font(.system(size: 11))
                    .foregroundStyle(subtask.isCompleted ? .secondary : .primary)
                    .accessibilityLabel(subtask.isCompleted ? "Completed" : "Not completed")
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 1) {
                if isEditingText {
                    LinkableTextEditor(
                        initialText: subtask.text,
                        initialLinks: subtask.links,
                        font: .systemFont(ofSize: 12),
                        onCommit: { newText, newLinks in
                            store.updateSubtaskText(newText, links: newLinks, for: subtask, in: parent)
                            isEditingText = false
                        },
                        onCancel: {
                            isEditingText = false
                        }
                    )
                } else {
                    // Attached to this wrapper, not directly on the Text, so it doesn't
                    // compete with the Text's own native link hover-cursor/click handling.
                    VStack(alignment: .leading, spacing: 0) {
                        Group {
                            if subtask.isCompleted {
                                Text(subtask.attributedText).foregroundStyle(.secondary)
                            } else {
                                Text(subtask.attributedText)
                            }
                        }
                        .font(.system(size: 12))
                        .strikethrough(subtask.isCompleted)
                        .fixedSize(horizontal: false, vertical: true)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture(count: 2) { isEditingText = true }
                    .onHover { hovering in
                        guard !subtask.links.isEmpty else { return }
                        if hovering {
                            NSCursor.pointingHand.push()
                        } else {
                            NSCursor.pop()
                        }
                    }
                }

                if let dueDate = subtask.dueDate {
                    Text(dueDate, format: .dateTime.month().day().hour().minute())
                        .font(.system(size: 9))
                        .foregroundStyle(subtask.isOverdue ? .red : .secondary)
                }
            }

            Spacer(minLength: 4)

            if !subtask.isCompleted {
                DueDatePickerMenu(date: subtask.dueDate) { newDate in
                    store.setDueDate(newDate, for: subtask, in: parent)
                }
                .opacity(isHovering ? 1 : 0)
            }

            Button {
                store.deleteSubtask(subtask, from: parent)
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Delete subtask")
            }
            .buttonStyle(.plain)
            .opacity(isHovering ? 1 : 0)
        }
        .padding(.leading, 24)
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovering = hovering
        }
    }
}
