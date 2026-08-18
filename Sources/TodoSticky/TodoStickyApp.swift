import SwiftUI

@main
struct TodoStickyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // No default window: the floating panel is created and managed entirely by
        // AppDelegate/PanelController. A Settings scene is the smallest no-op SwiftUI
        // requires an App to declare.
        Settings {
            EmptyView()
        }
    }
}
