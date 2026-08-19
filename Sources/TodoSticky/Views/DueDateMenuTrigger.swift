import AppKit
import SwiftUI

/// Shows the due-date quick-pick menu via a raw AppKit `NSMenu`, rather than SwiftUI's `Menu`.
/// SwiftUI's `Menu` bridges to an AppKit pop-up control that recomputes accessibility-resolved
/// text for every menu item on every update of its containing view — with one of these per row,
/// that turned into a runaway CPU sink once the list grew past a handful of items (each hover
/// re-render across the list re-triggered it for every menu still on screen). A plain `NSMenu`,
/// shown imperatively only while open — the same approach already used for the title bar's
/// right-click Theme/Quit menu — sidesteps that path entirely.
struct DueDateMenuTrigger: NSViewRepresentable {
    var currentDate: Date?
    var onSelectQuickOption: (DueDateQuickOption) -> Void
    var onCustom: () -> Void
    var onClear: () -> Void

    func makeNSView(context: Context) -> DueDateMenuTriggerView {
        let view = DueDateMenuTriggerView()
        view.currentDate = currentDate
        view.onSelectQuickOption = onSelectQuickOption
        view.onCustom = onCustom
        view.onClear = onClear
        return view
    }

    func updateNSView(_ nsView: DueDateMenuTriggerView, context: Context) {
        nsView.currentDate = currentDate
        nsView.onSelectQuickOption = onSelectQuickOption
        nsView.onCustom = onCustom
        nsView.onClear = onClear
    }
}

final class DueDateMenuTriggerView: NSView {
    var currentDate: Date?
    var onSelectQuickOption: ((DueDateQuickOption) -> Void)?
    var onCustom: (() -> Void)?
    var onClear: (() -> Void)?

    override func mouseDown(with event: NSEvent) {
        let menu = NSMenu()
        for option in DueDateQuickOption.allCases {
            let item = NSMenuItem(title: option.rawValue, action: #selector(handleQuickOption(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = option
            menu.addItem(item)
        }
        let customItem = NSMenuItem(title: "Custom…", action: #selector(handleCustom), keyEquivalent: "")
        customItem.target = self
        menu.addItem(customItem)
        if currentDate != nil {
            menu.addItem(.separator())
            let clearItem = NSMenuItem(title: "Clear Due Date", action: #selector(handleClear), keyEquivalent: "")
            clearItem.target = self
            menu.addItem(clearItem)
        }
        NSMenu.popUpContextMenu(menu, with: event, for: self)
    }

    @objc private func handleQuickOption(_ sender: NSMenuItem) {
        guard let option = sender.representedObject as? DueDateQuickOption else { return }
        onSelectQuickOption?(option)
    }

    @objc private func handleCustom() {
        onCustom?()
    }

    @objc private func handleClear() {
        onClear?()
    }
}
