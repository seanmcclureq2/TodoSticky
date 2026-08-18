import Foundation

struct Subtask: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var text: String
    var links: [TextLink] = []
    var isCompleted: Bool = false
    var completedAt: Date? = nil
    var dueDate: Date? = nil

    init(
        id: UUID = UUID(),
        text: String,
        links: [TextLink] = [],
        isCompleted: Bool = false,
        completedAt: Date? = nil,
        dueDate: Date? = nil
    ) {
        self.id = id
        self.text = text
        self.links = links
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.dueDate = dueDate
    }

    // Custom decoder so `links` (added after subtasks already existed on disk) defaults to
    // empty instead of failing to decode entirely when the key is missing from older saved data.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        text = try container.decode(String.self, forKey: .text)
        links = try container.decodeIfPresent([TextLink].self, forKey: .links) ?? []
        isCompleted = try container.decodeIfPresent(Bool.self, forKey: .isCompleted) ?? false
        completedAt = try container.decodeIfPresent(Date.self, forKey: .completedAt)
        dueDate = try container.decodeIfPresent(Date.self, forKey: .dueDate)
    }

    var attributedText: AttributedString {
        text.attributedString(applying: links)
    }

    var isOverdue: Bool {
        guard !isCompleted, let dueDate else { return false }
        return dueDate < Date()
    }
}
