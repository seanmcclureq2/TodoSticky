import Foundation

enum DueDateQuickOption: String, CaseIterable, Identifiable {
    case today = "Today"
    case tomorrow = "Tomorrow"
    case endOfWeek = "End of Week"

    var id: String { rawValue }

    /// Sensible end-of-day default: 5:00 PM. Callers can override via a custom date/time picker.
    private static let defaultHour = 17

    func resolvedDate(calendar: Calendar = .current, now: Date = Date()) -> Date {
        switch self {
        case .today:
            return Self.endOfDay(on: now, calendar: calendar)
        case .tomorrow:
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) ?? now
            return Self.endOfDay(on: tomorrow, calendar: calendar)
        case .endOfWeek:
            let weekday = calendar.component(.weekday, from: now) // 1 = Sunday ... 6 = Friday
            let daysUntilFriday = (6 - weekday + 7) % 7
            let friday = calendar.date(byAdding: .day, value: daysUntilFriday, to: now) ?? now
            return Self.endOfDay(on: friday, calendar: calendar)
        }
    }

    private static func endOfDay(on date: Date, calendar: Calendar) -> Date {
        calendar.date(bySettingHour: defaultHour, minute: 0, second: 0, of: date) ?? date
    }
}
