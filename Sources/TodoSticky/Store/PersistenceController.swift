import Foundation

enum PersistenceController {
    private static let appFolderName = "TodoSticky"
    private static let todosFileName = "todos.json"
    private static let windowStateFileName = "windowState.json"
    private static let themeDefaultsKey = "TodoSticky.appTheme"
    private static let showCompletedDefaultsKey = "TodoSticky.showCompleted"

    private static var appSupportDirectory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let dir = base.appendingPathComponent(appFolderName, isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    private static var todosURL: URL { appSupportDirectory.appendingPathComponent(todosFileName) }
    private static var windowStateURL: URL { appSupportDirectory.appendingPathComponent(windowStateFileName) }

    static func loadTodos() -> [TodoItem] {
        load(from: todosURL) ?? []
    }

    static func saveTodos(_ items: [TodoItem]) {
        save(items, to: todosURL)
    }

    static func loadWindowState() -> WindowState {
        load(from: windowStateURL) ?? .default
    }

    static func saveWindowState(_ state: WindowState) {
        save(state, to: windowStateURL)
    }

    static func loadTheme() -> AppTheme {
        guard let raw = UserDefaults.standard.string(forKey: themeDefaultsKey) else { return .system }
        return AppTheme(rawValue: raw) ?? .system
    }

    static func saveTheme(_ theme: AppTheme) {
        UserDefaults.standard.set(theme.rawValue, forKey: themeDefaultsKey)
    }

    /// `UserDefaults.bool(forKey:)` returns `false` for a missing key, which conveniently
    /// matches the desired default of hiding completed tasks.
    static func loadShowCompleted() -> Bool {
        UserDefaults.standard.bool(forKey: showCompletedDefaultsKey)
    }

    static func saveShowCompleted(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: showCompletedDefaultsKey)
    }

    private static func load<T: Decodable>(from url: URL) -> T? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(T.self, from: data)
    }

    private static func save<T: Encodable>(_ value: T, to url: URL) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(value) else { return }
        try? data.write(to: url, options: .atomic)
    }
}
