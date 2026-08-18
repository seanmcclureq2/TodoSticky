import Foundation

struct TodoItem: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var text: String
    var links: [TextLink] = []
    var isCompleted: Bool = false
    var dueDate: Date? = nil
    var subtasks: [Subtask] = []
    var createdAt: Date = Date()
    var completedAt: Date? = nil

    init(
        id: UUID = UUID(),
        text: String,
        links: [TextLink] = [],
        isCompleted: Bool = false,
        dueDate: Date? = nil,
        subtasks: [Subtask] = [],
        createdAt: Date = Date(),
        completedAt: Date? = nil
    ) {
        self.id = id
        self.text = text
        self.links = links
        self.isCompleted = isCompleted
        self.dueDate = dueDate
        self.subtasks = subtasks
        self.createdAt = createdAt
        self.completedAt = completedAt
    }

    // Custom decoder so `links` (added after tasks already existed on disk) defaults to empty
    // instead of failing to decode entirely when the key is missing from older saved data.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        text = try container.decode(String.self, forKey: .text)
        links = try container.decodeIfPresent([TextLink].self, forKey: .links) ?? []
        isCompleted = try container.decodeIfPresent(Bool.self, forKey: .isCompleted) ?? false
        dueDate = try container.decodeIfPresent(Date.self, forKey: .dueDate)
        subtasks = try container.decodeIfPresent([Subtask].self, forKey: .subtasks) ?? []
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        completedAt = try container.decodeIfPresent(Date.self, forKey: .completedAt)
    }

    var attributedText: AttributedString {
        text.attributedString(applying: links)
    }

    /// Used for sort ordering only (never persisted/displayed as the task's own due date): if
    /// the task itself has no due date, falls back to the earliest due date among its
    /// incomplete subtasks, so a task with an urgent-but-undated parent still surfaces near
    /// the top of the list instead of sorting as if nothing were due.
    var effectiveDueDate: Date? {
        if let dueDate {
            return dueDate
        }
        return subtasks.compactMap { $0.isCompleted ? nil : $0.dueDate }.min()
    }

    var isOverdue: Bool {
        guard !isCompleted, let dueDate else { return false }
        return dueDate < Date()
    }

    func isDueSoon(within interval: TimeInterval) -> Bool {
        guard !isCompleted, let dueDate else { return false }
        let now = Date()
        return dueDate >= now && dueDate <= now.addingTimeInterval(interval)
    }

    /// Incomplete subtasks first (in original order), completed subtasks pushed to the bottom (in original order).
    var sortedSubtasks: [Subtask] {
        subtasks.sorted { !$0.isCompleted && $1.isCompleted }
    }
}
