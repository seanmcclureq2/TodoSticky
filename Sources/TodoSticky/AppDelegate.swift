import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var store: TodoStore?
    private var panelController: PanelController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Accessory: no Dock icon, no Cmd+Tab entry — a pure floating utility panel.
        NSApp.setActivationPolicy(.accessory)

        let store = TodoStore()
        self.store = store
        self.panelController = PanelController(store: store)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
