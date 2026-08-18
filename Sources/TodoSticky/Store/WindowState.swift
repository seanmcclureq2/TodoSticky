import Foundation

struct WindowState: Codable, Equatable {
    var originX: Double
    var originY: Double
    var expandedWidth: Double
    var expandedHeight: Double
    var isCollapsed: Bool

    static let `default` = WindowState(
        originX: 200,
        originY: 400,
        expandedWidth: 280,
        expandedHeight: 380,
        isCollapsed: false
    )
}
