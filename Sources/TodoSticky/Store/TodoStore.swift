import Foundation

@MainActor
final class TodoStore: ObservableObject {
    @Published private(set) var items: [TodoItem]

    enum UrgencyStatus {
        case overdue
        case dueSoon
        case none
    }

    init() {
        items = PersistenceController.loadTodos()
    }

    var sortedActive: [TodoItem] {
        items.filter { !$0.isCompleted }.sorted { lhs, rhs in
            switch (lhs.dueDate, rhs.dueDate) {
            case let (l?, r?):
                if l != r { return l < r }
                return lhs.createdAt < rhs.createdAt
            case (nil, nil):
                return lhs.createdAt < rhs.createdAt
            case (nil, _):
                return false
            case (_, nil):
                return true
            }
        }
    }

    var sortedCompleted: [TodoItem] {
        items.filter { $0.isCompleted }.sorted { lhs, rhs in
            (lhs.completedAt ?? .distantPast) > (rhs.completedAt ?? .distantPast)
        }
    }

    var incompleteCount: Int {
        items.filter { !$0.isCompleted }.count
    }

    /// Drives the collapsed bar's status dot: red if anything is overdue, yellow if anything
    /// is due within the next 5 hours, otherwise neutral.
    var urgencyStatus: UrgencyStatus {
        let active = items.filter { !$0.isCompleted }
        if active.contains(where: { $0.isOverdue }) { return .overdue }
        if active.contains(where: { $0.isDueSoon(within: 5 * 3600) }) { return .dueSoon }
        return .none
    }

    func addItem(text: String, dueDate: Date? = nil) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        items.append(TodoItem(text: trimmed, dueDate: dueDate))
        persist()
    }

    func deleteItem(_ item: TodoItem) {
        items.removeAll { $0.id == item.id }
        persist()
    }

    func toggleCompleted(_ item: TodoItem) {
        guard let idx = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[idx].isCompleted.toggle()
        items[idx].completedAt = items[idx].isCompleted ? Date() : nil
        persist()
    }

    func setDueDate(_ date: Date?, for item: TodoItem) {
        guard let idx = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[idx].dueDate = date
        persist()
    }

    /// Text is stored as-is (not trimmed) so `links`' UTF-16 offsets, captured against the
    /// exact edited string, stay valid.
    func updateText(_ text: String, links: [TextLink], for item: TodoItem) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let idx = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[idx].text = text
        items[idx].links = links
        persist()
    }

    func addSubtask(text: String, to item: TodoItem) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let idx = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[idx].subtasks.append(Subtask(text: trimmed))
        persist()
    }

    func toggleSubtaskCompleted(_ subtask: Subtask, in item: TodoItem) {
        guard let itemIdx = items.firstIndex(where: { $0.id == item.id }),
              let subIdx = items[itemIdx].subtasks.firstIndex(where: { $0.id == subtask.id }) else { return }
        items[itemIdx].subtasks[subIdx].isCompleted.toggle()
        items[itemIdx].subtasks[subIdx].completedAt = items[itemIdx].subtasks[subIdx].isCompleted ? Date() : nil
        persist()
    }

    /// Text is stored as-is (not trimmed) so `links`' UTF-16 offsets, captured against the
    /// exact edited string, stay valid.
    func updateSubtaskText(_ text: String, links: [TextLink], for subtask: Subtask, in item: TodoItem) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let itemIdx = items.firstIndex(where: { $0.id == item.id }),
              let subIdx = items[itemIdx].subtasks.firstIndex(where: { $0.id == subtask.id }) else { return }
        items[itemIdx].subtasks[subIdx].text = text
        items[itemIdx].subtasks[subIdx].links = links
        persist()
    }

    func setDueDate(_ date: Date?, for subtask: Subtask, in item: TodoItem) {
        guard let itemIdx = items.firstIndex(where: { $0.id == item.id }),
              let subIdx = items[itemIdx].subtasks.firstIndex(where: { $0.id == subtask.id }) else { return }
        items[itemIdx].subtasks[subIdx].dueDate = date
        persist()
    }

    func deleteSubtask(_ subtask: Subtask, from item: TodoItem) {
        guard let itemIdx = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[itemIdx].subtasks.removeAll { $0.id == subtask.id }
        persist()
    }

    private func persist() {
        PersistenceController.saveTodos(items)
    }
}
