import AppKit
import SwiftUI

/// A transparent AppKit shim used under the title bar and collapsed bar. Single-click-drag
/// moves the window (via `performDrag`, which works reliably over hosted SwiftUI content,
/// unlike `isMovableByWindowBackground`); double-click toggles collapse/expand; right-click
/// offers a Quit item since there's no Dock icon or app menu to quit from.
struct DragHandle: NSViewRepresentable {
    var onDoubleClick: () -> Void
    var onQuit: () -> Void
    var currentTheme: AppTheme
    var onSelectTheme: (AppTheme) -> Void
    var showCompleted: Bool
    var onToggleShowCompleted: () -> Void
    var onToggleLoginItem: () -> Void

    func makeNSView(context: Context) -> DragHandleView {
        let view = DragHandleView()
        view.onDoubleClick = onDoubleClick
        view.onQuit = onQuit
        view.currentTheme = currentTheme
        view.onSelectTheme = onSelectTheme
        view.showCompleted = showCompleted
        view.onToggleShowCompleted = onToggleShowCompleted
        view.onToggleLoginItem = onToggleLoginItem
        return view
    }

    func updateNSView(_ nsView: DragHandleView, context: Context) {
        nsView.onDoubleClick = onDoubleClick
        nsView.onQuit = onQuit
        nsView.currentTheme = currentTheme
        nsView.onSelectTheme = onSelectTheme
        nsView.showCompleted = showCompleted
        nsView.onToggleShowCompleted = onToggleShowCompleted
        nsView.onToggleLoginItem = onToggleLoginItem
    }
}

final class DragHandleView: NSView {
    var onDoubleClick: (() -> Void)?
    var onQuit: (() -> Void)?
    var currentTheme: AppTheme = .system
    var onSelectTheme: ((AppTheme) -> Void)?
    var showCompleted: Bool = false
    var onToggleShowCompleted: (() -> Void)?
    var onToggleLoginItem: (() -> Void)?

    override func mouseDown(with event: NSEvent) {
        if event.clickCount == 2 {
            onDoubleClick?()
            return
        }
        window?.performDrag(with: event)
    }

    override func rightMouseDown(with event: NSEvent) {
        let menu = NSMenu()

        let themeMenu = NSMenu()
        for theme in AppTheme.allCases {
            let item = NSMenuItem(title: theme.title, action: #selector(handleSelectTheme(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = theme
            item.state = theme == currentTheme ? .on : .off
            themeMenu.addItem(item)
        }
        let themeItem = NSMenuItem(title: "Theme", action: nil, keyEquivalent: "")
        themeItem.submenu = themeMenu
        menu.addItem(themeItem)

        let showCompletedItem = NSMenuItem(title: "Show Completed", action: #selector(handleToggleShowCompleted), keyEquivalent: "")
        showCompletedItem.target = self
        showCompletedItem.state = showCompleted ? .on : .off
        menu.addItem(showCompletedItem)

        menu.addItem(.separator())

        let loginItem = NSMenuItem(title: "Start at Login", action: #selector(handleToggleLoginItem), keyEquivalent: "")
        loginItem.target = self
        loginItem.state = LoginItemManager.isEnabled ? .on : .off
        menu.addItem(loginItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit TodoSticky", action: #selector(handleQuit), keyEquivalent: "")
        quitItem.target = self
        menu.addItem(quitItem)

        NSMenu.popUpContextMenu(menu, with: event, for: self)
    }

    @objc private func handleSelectTheme(_ sender: NSMenuItem) {
        guard let theme = sender.representedObject as? AppTheme else { return }
        onSelectTheme?(theme)
    }

    @objc private func handleToggleShowCompleted() {
        onToggleShowCompleted?()
    }

    @objc private func handleToggleLoginItem() {
        onToggleLoginItem?()
    }

    @objc private func handleQuit() {
        onQuit?()
    }
}
