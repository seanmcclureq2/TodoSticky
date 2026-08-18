import Foundation

/// A hyperlink applied to a sub-range of an item's or subtask's text, stored as a UTF-16
/// offset/length pair (matching NSRange/NSAttributedString semantics) rather than a
/// String.Index range, since only the former is trivially Codable.
struct TextLink: Codable, Equatable {
    var location: Int
    var length: Int
    var urlString: String

    var url: URL? { URL(string: urlString) }

    var nsRange: NSRange { NSRange(location: location, length: length) }
}

extension String {
    /// Renders `self` as an `AttributedString` with each `link` applied to its range, styled
    /// like a standard hyperlink. Out-of-bounds or invalid links are skipped rather than
    /// crashing, since stored ranges could in principle go stale if text is edited elsewhere.
    func attributedString(applying links: [TextLink]) -> AttributedString {
        var attributed = AttributedString(self)
        for link in links {
            guard let url = link.url,
                  let stringRange = Range(link.nsRange, in: self),
                  let lower = AttributedString.Index(stringRange.lowerBound, within: attributed),
                  let upper = AttributedString.Index(stringRange.upperBound, within: attributed) else {
                continue
            }
            // SwiftUI's Text renders `.link` runs with standard link styling (color +
            // underline) automatically, no need to set those attributes explicitly.
            attributed[lower..<upper].link = url
        }
        return attributed
    }
}
