import AppKit
import SwiftUI

/// Transparent overlay layered above the SwiftUI content. Its `hitTest` only claims points
/// within an ~8pt band along each edge/corner (everywhere else it returns nil so clicks pass
/// through to the checkboxes/text field beneath). This replaces the native borderless-window
/// resize edge, which is only a couple of points wide and has no visible affordance. Disabled
/// and hidden while the panel is collapsed.
struct ResizeOverlay: NSViewRepresentable {
    var isEnabled: Bool
    var minSize: NSSize

    func makeNSView(context: Context) -> ResizeOverlayView {
        let view = ResizeOverlayView()
        view.isEnabledForResize = isEnabled
        view.minimumSize = minSize
        return view
    }

    func updateNSView(_ nsView: ResizeOverlayView, context: Context) {
        nsView.isEnabledForResize = isEnabled
        nsView.minimumSize = minSize
        nsView.needsDisplay = true
        nsView.window?.invalidateCursorRects(for: nsView)
    }
}

final class ResizeOverlayView: NSView {
    var isEnabledForResize = true {
        didSet { needsDisplay = true }
    }
    var minimumSize = NSSize(width: 220, height: 160)

    private let edgeMargin: CGFloat = 8
    private let gripSize: CGFloat = 12

    private enum ResizeDirection {
        case n, s, e, w, ne, nw, se, sw
    }

    private var activeDirection: ResizeDirection?
    private var initialMouseLocation: NSPoint = .zero
    private var initialFrame: NSRect = .zero

    override func hitTest(_ point: NSPoint) -> NSView? {
        guard isEnabledForResize, direction(for: point) != nil else { return nil }
        return self
    }

    private func direction(for point: NSPoint) -> ResizeDirection? {
        let b = bounds
        guard b.width > 0, b.height > 0 else { return nil }
        let nearLeft = point.x <= edgeMargin
        let nearRight = point.x >= b.width - edgeMargin
        let nearBottom = point.y <= edgeMargin
        let nearTop = point.y >= b.height - edgeMargin

        if nearLeft && nearBottom { return .sw }
        if nearLeft && nearTop { return .nw }
        if nearRight && nearBottom { return .se }
        if nearRight && nearTop { return .ne }
        if nearLeft { return .w }
        if nearRight { return .e }
        if nearBottom { return .s }
        if nearTop { return .n }
        return nil
    }

    override func mouseDown(with event: NSEvent) {
        guard let window else { return }
        let pointInView = convert(event.locationInWindow, from: nil)
        activeDirection = direction(for: pointInView)
        initialMouseLocation = NSEvent.mouseLocation
        initialFrame = window.frame
    }

    override func mouseDragged(with event: NSEvent) {
        guard let window, let direction = activeDirection else { return }
        let current = NSEvent.mouseLocation
        let dx = current.x - initialMouseLocation.x
        let dy = current.y - initialMouseLocation.y

        var frame = initialFrame

        switch direction {
        case .e:
            frame.size.width = max(minimumSize.width, initialFrame.width + dx)
        case .w:
            let newWidth = max(minimumSize.width, initialFrame.width - dx)
            frame.origin.x = initialFrame.maxX - newWidth
            frame.size.width = newWidth
        case .n:
            frame.size.height = max(minimumSize.height, initialFrame.height + dy)
        case .s:
            let newHeight = max(minimumSize.height, initialFrame.height - dy)
            frame.origin.y = initialFrame.maxY - newHeight
            frame.size.height = newHeight
        case .ne:
            frame.size.width = max(minimumSize.width, initialFrame.width + dx)
            frame.size.height = max(minimumSize.height, initialFrame.height + dy)
        case .nw:
            let newWidth = max(minimumSize.width, initialFrame.width - dx)
            frame.origin.x = initialFrame.maxX - newWidth
            frame.size.width = newWidth
            frame.size.height = max(minimumSize.height, initialFrame.height + dy)
        case .se:
            let newHeight = max(minimumSize.height, initialFrame.height - dy)
            frame.origin.y = initialFrame.maxY - newHeight
            frame.size.height = newHeight
            frame.size.width = max(minimumSize.width, initialFrame.width + dx)
        case .sw:
            let newWidth = max(minimumSize.width, initialFrame.width - dx)
            let newHeight = max(minimumSize.height, initialFrame.height - dy)
            frame.origin.x = initialFrame.maxX - newWidth
            frame.origin.y = initialFrame.maxY - newHeight
            frame.size.width = newWidth
            frame.size.height = newHeight
        }

        window.setFrame(frame, display: true)
    }

    override func mouseUp(with event: NSEvent) {
        activeDirection = nil
    }

    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        window?.invalidateCursorRects(for: self)
    }

    override func resetCursorRects() {
        guard isEnabledForResize else { return }
        let b = bounds
        addCursorRect(NSRect(x: 0, y: b.height - edgeMargin, width: b.width, height: edgeMargin), cursor: .resizeUpDown)
        addCursorRect(NSRect(x: 0, y: 0, width: b.width, height: edgeMargin), cursor: .resizeUpDown)
        addCursorRect(NSRect(x: 0, y: 0, width: edgeMargin, height: b.height), cursor: .resizeLeftRight)
        addCursorRect(NSRect(x: b.width - edgeMargin, y: 0, width: edgeMargin, height: b.height), cursor: .resizeLeftRight)
    }

    override func draw(_ dirtyRect: NSRect) {
        guard isEnabledForResize else { return }
        let inset: CGFloat = 3
        let origin = NSPoint(x: bounds.width - gripSize - inset, y: inset)
        NSColor.secondaryLabelColor.withAlphaComponent(0.5).setStroke()

        let lineCount = 3
        let spacing = gripSize / CGFloat(lineCount)
        for i in 0..<lineCount {
            let offset = CGFloat(i) * spacing
            let path = NSBezierPath()
            path.lineWidth = 1
            path.move(to: NSPoint(x: origin.x + gripSize, y: origin.y + offset))
            path.line(to: NSPoint(x: origin.x + offset, y: origin.y))
            path.stroke()
        }
    }
}
