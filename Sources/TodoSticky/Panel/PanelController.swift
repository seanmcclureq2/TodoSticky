import AppKit
import SwiftUI

@MainActor
final class PanelController: NSObject, ObservableObject, NSWindowDelegate {
    let panel: StickyPanel
    let store: TodoStore

    @Published private(set) var isCollapsed: Bool
    @Published private(set) var theme: AppTheme

    static let collapsedHeight: CGFloat = 32
    static let minExpandedWidth: CGFloat = 220
    static let minExpandedHeight: CGFloat = 160
    static let collapseExpandDuration: TimeInterval = 0.28

    private var expandedSize: CGSize

    init(store: TodoStore) {
        self.store = store
        let state = PersistenceController.loadWindowState()
        self.expandedSize = CGSize(width: state.expandedWidth, height: state.expandedHeight)
        self.isCollapsed = state.isCollapsed
        self.theme = PersistenceController.loadTheme()

        let initialHeight = state.isCollapsed ? Self.collapsedHeight : state.expandedHeight
        let candidateFrame = NSRect(x: state.originX, y: state.originY, width: state.expandedWidth, height: initialHeight)
        let contentRect = Self.validated(frame: candidateFrame)

        let panel = StickyPanel(contentRect: contentRect)
        self.panel = panel

        super.init()

        panel.delegate = self
        panel.quitHandler = { [weak self] in self?.quit() }

        let rootView = RootView(store: store, controller: self)
        let hostingView = NSHostingView(rootView: rootView)
        // Never let SwiftUI's own content-driven sizing nudge the window on its own — the
        // window's frame should be dictated only by our explicit setFrame calls, otherwise it
        // can visibly "correct" itself by a few points right after an animation lands.
        hostingView.sizingOptions = []
        panel.contentView = hostingView
        panel.appearance = self.theme.appearance

        applyResizeConstraints(forCollapsed: state.isCollapsed, referenceWidth: contentRect.width)
        panel.makeKeyAndOrderFront(nil)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenParametersChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    /// Displays can disconnect (e.g. undocking a laptop) while the app is already running, not
    /// just at launch. If that leaves the panel with no on-screen home, bring it back onto
    /// whatever screen is now available instead of leaving it stranded off-screen.
    @objc private func screenParametersChanged() {
        let frame = panel.frame
        guard !NSScreen.screens.contains(where: { $0.frame.intersects(frame) }) else { return }
        guard let target = NSScreen.main ?? NSScreen.screens.first else { return }

        let visible = target.visibleFrame
        let width = min(frame.width, visible.width)
        let height = min(frame.height, visible.height)
        let x = visible.minX + 40
        let y = visible.maxY - height - 40
        panel.setFrame(NSRect(x: x, y: y, width: width, height: height), display: true, animate: true)

        if !isCollapsed {
            expandedSize = CGSize(width: width, height: height)
        }
        persistWindowState()
    }

    func toggleCollapsed() {
        setCollapsed(!isCollapsed)
    }

    func setTheme(_ theme: AppTheme) {
        self.theme = theme
        panel.appearance = theme.appearance
        PersistenceController.saveTheme(theme)
    }

    func toggleLoginItem() {
        LoginItemManager.setEnabled(!LoginItemManager.isEnabled)
    }

    private func setCollapsed(_ collapsed: Bool) {
        guard collapsed != isCollapsed else { return }
        let currentFrame = panel.frame

        if collapsed {
            expandedSize = currentFrame.size
        }

        let newHeight = collapsed ? Self.collapsedHeight : expandedSize.height
        let newWidth = collapsed ? currentFrame.width : expandedSize.width

        // Anchor toward the bottom (grow/shrink upward, like a drawer) only when the panel is
        // actually resting at the very bottom of the screen (e.g. on top of the Dock);
        // anywhere else on screen, keep the usual top-anchored behavior. AppKit frames are
        // bottom-left origin.
        let newY: CGFloat
        if anchorsToBottomEdge(of: currentFrame) {
            newY = currentFrame.origin.y
        } else {
            newY = currentFrame.origin.y + (currentFrame.height - newHeight)
        }
        // Never let the result land even partly off-screen, regardless of anchor direction —
        // e.g. if the panel had been dragged so its bottom edge dipped below the screen, that
        // would otherwise get misread as "anchor to bottom" and permanently strand the
        // collapsed bar off-screen with no way to reach it.
        let newFrame = Self.clamped(
            NSRect(x: currentFrame.origin.x, y: newY, width: newWidth, height: newHeight),
            toFit: Self.screen(containing: currentFrame)
        )

        // Fully relax size constraints for the duration of the animation. AppKit enforces
        // minSize/maxSize immediately (not just on future resizes), so locking in the tight
        // collapsed-size constraint (or the normal expanded minimum) *before* animating would
        // make it instantly clamp the still-differently-sized window, causing a visible snap
        // right before our own animated setFrame corrects it. The real constraints get applied
        // only after the frame has actually settled at its target.
        panel.minSize = NSSize(width: 1, height: 1)
        panel.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)

        if collapsed {
            // Shrink the frame first and only swap to the compact bar content once the
            // animation finishes, so the full content doesn't visibly snap small before the
            // window catches up — mirrors the reveal effect expanding already has.
            NSAnimationContext.runAnimationGroup { context in
                context.duration = Self.collapseExpandDuration
                panel.animator().setFrame(newFrame, display: true)
            } completionHandler: {
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    self.isCollapsed = true
                    self.applyResizeConstraints(forCollapsed: true, referenceWidth: newWidth)
                    self.persistWindowState()
                }
            }
        } else {
            // Swap to full content immediately so growing the frame reveals it drawer-style.
            isCollapsed = false
            NSAnimationContext.runAnimationGroup { context in
                context.duration = Self.collapseExpandDuration
                panel.animator().setFrame(newFrame, display: true)
            } completionHandler: {
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    self.applyResizeConstraints(forCollapsed: false, referenceWidth: newWidth)
                    self.persistWindowState()
                }
            }
        }
    }

    private func applyResizeConstraints(forCollapsed collapsed: Bool, referenceWidth: CGFloat) {
        if collapsed {
            let size = NSSize(width: referenceWidth, height: Self.collapsedHeight)
            panel.minSize = size
            panel.maxSize = size
        } else {
            panel.minSize = NSSize(width: Self.minExpandedWidth, height: Self.minExpandedHeight)
            panel.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        }
    }

    private func quit() {
        NSApp.terminate(nil)
    }

    private func persistWindowState() {
        let frame = panel.frame
        let state = WindowState(
            originX: frame.origin.x,
            originY: frame.origin.y,
            expandedWidth: isCollapsed ? expandedSize.width : frame.width,
            expandedHeight: isCollapsed ? expandedSize.height : frame.height,
            isCollapsed: isCollapsed
        )
        PersistenceController.saveWindowState(state)
    }

    /// How close to the bottom of the screen's usable area (e.g. resting on top of the Dock)
    /// counts as "at the very bottom" for anchor purposes.
    static let bottomAnchorThreshold: CGFloat = 80

    /// True only if `frame` is actually at (or extremely near) the very bottom of its screen —
    /// within `bottomAnchorThreshold`, and not already dipping below it — meaning
    /// collapse/expand should keep the bottom edge fixed and grow/shrink upward. Everywhere
    /// else (including already off-screen below) uses the default top-anchored behavior.
    private func anchorsToBottomEdge(of frame: NSRect) -> Bool {
        guard let screen = Self.screen(containing: frame) else { return false }
        let visible = screen.visibleFrame
        let distanceToBottom = frame.minY - visible.minY
        return distanceToBottom >= 0 && distanceToBottom <= Self.bottomAnchorThreshold
    }

    /// Clamps `frame` so it lies fully within `screen`'s visible area (falls back to
    /// `NSScreen.main` if `screen` is nil). Leaves size untouched, only adjusts origin.
    private static func clamped(_ frame: NSRect, toFit screen: NSScreen?) -> NSRect {
        guard let visible = (screen ?? NSScreen.main)?.visibleFrame else { return frame }
        var result = frame
        if result.maxX > visible.maxX { result.origin.x = visible.maxX - result.width }
        if result.minX < visible.minX { result.origin.x = visible.minX }
        if result.maxY > visible.maxY { result.origin.y = visible.maxY - result.height }
        if result.minY < visible.minY { result.origin.y = visible.minY }
        return result
    }

    /// The screen `frame` overlaps most; falls back to the main screen if it overlaps none.
    private static func screen(containing frame: NSRect) -> NSScreen? {
        let best = NSScreen.screens.max { lhs, rhs in
            let lhsArea = lhs.frame.intersection(frame)
            let rhsArea = rhs.frame.intersection(frame)
            return lhsArea.width * lhsArea.height < rhsArea.width * rhsArea.height
        }
        if let best, best.frame.intersects(frame) {
            return best
        }
        return NSScreen.main ?? best
    }

    /// Falls back to a default on-screen position if the saved frame no longer intersects
    /// any connected screen (e.g. an external monitor was disconnected).
    private static func validated(frame: NSRect) -> NSRect {
        if NSScreen.screens.contains(where: { $0.frame.intersects(frame) }) {
            return frame
        }
        let fallback = WindowState.default
        return NSRect(x: fallback.originX, y: fallback.originY, width: frame.width, height: frame.height)
    }

    // MARK: NSWindowDelegate

    func windowDidResize(_ notification: Notification) {
        guard !isCollapsed else { return }
        persistWindowState()
    }

    func windowDidMove(_ notification: Notification) {
        persistWindowState()
    }
}
