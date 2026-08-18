import AppKit
import SwiftUI

/// A single-field text editor backed by a real `NSTextView`, used instead of a plain SwiftUI
/// `TextField` so it can intercept Cmd+V: if the pasteboard holds a URL and there's a
/// non-empty text selection, the selection becomes a hyperlink to that URL instead of the URL
/// text being inserted. A plain SwiftUI `TextField` has no way to inspect the current
/// selection or override paste, hence the AppKit bridge.
struct LinkableTextEditor: NSViewRepresentable {
    var initialText: String
    var initialLinks: [TextLink]
    var font: NSFont
    var onCommit: (String, [TextLink]) -> Void
    var onCancel: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> LinkableNSTextView {
        let textView = LinkableNSTextView()
        textView.delegate = context.coordinator
        textView.font = font
        textView.textColor = .textColor
        // A visible field background makes it obvious this line is now editable, rather than
        // looking like plain text with a stray cursor.
        textView.drawsBackground = true
        textView.backgroundColor = .textBackgroundColor
        textView.textContainerInset = NSSize(width: 3, height: 2)
        textView.textContainer?.lineFragmentPadding = 2
        textView.textContainer?.widthTracksTextView = true
        textView.isRichText = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticLinkDetectionEnabled = false
        textView.onCommit = onCommit
        textView.onCancel = onCancel

        let attributed = NSMutableAttributedString(string: initialText)
        let fullRange = NSRange(location: 0, length: attributed.length)
        attributed.addAttribute(.font, value: font, range: fullRange)
        // Without an explicit foreground color, NSAttributedString defaults to black text,
        // which is invisible against a dark background/theme.
        attributed.addAttribute(.foregroundColor, value: NSColor.textColor, range: fullRange)
        for link in initialLinks {
            guard let url = link.url, link.nsRange.location + link.nsRange.length <= attributed.length else { continue }
            attributed.addAttribute(.link, value: url, range: link.nsRange)
            attributed.addAttribute(.foregroundColor, value: NSColor.linkColor, range: link.nsRange)
            attributed.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: link.nsRange)
        }
        textView.textStorage?.setAttributedString(attributed)

        DispatchQueue.main.async {
            textView.window?.makeFirstResponder(textView)
            textView.selectAll(nil)
        }

        return textView
    }

    func updateNSView(_ nsView: LinkableNSTextView, context: Context) {
        // One-directional: the view owns its content once created; changes flow out only via
        // onCommit/onCancel, so there's nothing to push back in on further SwiftUI updates.
    }

    func sizeThatFits(_ proposal: ProposedViewSize, nsView: LinkableNSTextView, context: Context) -> CGSize? {
        guard let width = proposal.width, width > 0,
              let layoutManager = nsView.layoutManager,
              let container = nsView.textContainer else { return nil }
        let inset = nsView.textContainerInset
        container.containerSize = NSSize(width: width - inset.width * 2, height: .greatestFiniteMagnitude)
        layoutManager.ensureLayout(for: container)
        let usedRect = layoutManager.usedRect(for: container)
        return CGSize(width: width, height: ceil(usedRect.height) + inset.height * 2)
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        func textDidEndEditing(_ notification: Notification) {
            guard let textView = notification.object as? LinkableNSTextView else { return }
            textView.finishCommit()
        }
    }
}

final class LinkableNSTextView: NSTextView {
    var onCommit: ((String, [TextLink]) -> Void)?
    var onCancel: (() -> Void)?
    private var didFinish = false

    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 36, 76: // Return, keypad Enter
            finishCommit()
        case 53: // Escape
            finishCancel()
        default:
            super.keyDown(with: event)
        }
    }

    /// Cmd+V: if there's a non-empty selection and the pasteboard holds an http(s) URL, turn
    /// the selection into a link to that URL instead of inserting the URL text.
    override func paste(_ sender: Any?) {
        let selection = selectedRange()
        if selection.length > 0,
           let pasted = NSPasteboard.general.string(forType: .string)?.trimmingCharacters(in: .whitespacesAndNewlines),
           let url = URL(string: pasted),
           let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https",
           let storage = textStorage {
            storage.beginEditing()
            storage.addAttribute(.link, value: url, range: selection)
            storage.addAttribute(.foregroundColor, value: NSColor.linkColor, range: selection)
            storage.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: selection)
            storage.endEditing()
            didChangeText()
            return
        }
        super.paste(sender)
    }

    func finishCommit() {
        guard !didFinish else { return }
        didFinish = true
        onCommit?(string, Self.extractLinks(from: textStorage))
    }

    func finishCancel() {
        guard !didFinish else { return }
        didFinish = true
        onCancel?()
    }

    private static func extractLinks(from textStorage: NSTextStorage?) -> [TextLink] {
        guard let textStorage else { return [] }
        var results: [TextLink] = []
        let full = NSRange(location: 0, length: textStorage.length)
        textStorage.enumerateAttribute(.link, in: full) { value, range, _ in
            let url: URL?
            switch value {
            case let value as URL: url = value
            case let value as String: url = URL(string: value)
            default: url = nil
            }
            if let url {
                results.append(TextLink(location: range.location, length: range.length, urlString: url.absoluteString))
            }
        }
        return results
    }
}
