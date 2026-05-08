//
//  JSONHighlighter.swift
//  redis-pro
//
//  JSON syntax highlighting using tree-sitter and TreeSitterJSON.
//

import Foundation
import AppKit
@preconcurrency import SwiftTreeSitter
import TreeSitterJSON

/// Provides JSON syntax highlighting using tree-sitter incremental parsing.
enum JSONHighlighter {

    // MARK: - Highlight Colors

    private static let keyColor = NSColor(red: 0.15, green: 0.45, blue: 0.82, alpha: 1.0)
    private static let stringColor = NSColor(red: 0.13, green: 0.60, blue: 0.35, alpha: 1.0)
    private static let numberColor = NSColor(red: 0.82, green: 0.45, blue: 0.13, alpha: 1.0)
    private static let booleanColor = NSColor(red: 0.70, green: 0.25, blue: 0.55, alpha: 1.0)
    private static let nullColor = NSColor(red: 0.50, green: 0.50, blue: 0.55, alpha: 1.0)
    private static let escapeColor = NSColor(red: 0.90, green: 0.35, blue: 0.20, alpha: 1.0)
    private static let commentColor = NSColor.secondaryLabelColor
    private static let punctuationColor = NSColor.labelColor

    // MARK: - Shared language, parser, and query

    private static let language = Language(tree_sitter_json())

    private static let parser: Parser = {
        let p = Parser()
        try! p.setLanguage(language)
        return p
    }()

    private static let highlightQuery: Query? = {
        let queryString = """
        (pair
          key: (_) @string.special.key)

        (string) @string

        (number) @number

        (null) @constant.builtin
        (true) @boolean
        (false) @boolean

        (escape_sequence) @escape

        (comment) @comment
        """
        guard let data = queryString.data(using: .utf8) else { return nil }
        return try? Query(language: language, data: data)
    }()

    // MARK: - Public API

    /// Highlights the given JSON string and returns an `NSAttributedString` with syntax coloring.
    static func highlightToNS(_ jsonString: String) -> NSAttributedString {
        guard let mutableTree = parser.parse(jsonString),
              let query = highlightQuery else {
            return NSAttributedString(string: jsonString)
        }

        let cursor = query.execute(in: mutableTree)

        let nsAttr = NSMutableAttributedString(string: jsonString)

        // Apply a default text color to the entire string first.
        nsAttr.addAttribute(.foregroundColor,
                            value: punctuationColor,
                            range: NSRange(location: 0, length: jsonString.utf16.count))

        // Overlay highlight colors for each named capture.
        for match in cursor {
            for capture in match.captures {
                let range = capture.range
                guard range.location + range.length <= nsAttr.length else { continue }
                let name = capture.name ?? ""
                let color = colorForCapture(name)
                nsAttr.addAttribute(.foregroundColor, value: color, range: range)
            }
        }

        return nsAttr
    }

    /// Highlights the given JSON string and returns an `AttributedString` with syntax coloring.
    ///
    /// If tree-sitter parsing fails or no highlight query is available the plain string is returned.
    static func highlight(_ jsonString: String) -> AttributedString {
        return AttributedString(highlightToNS(jsonString))
    }

    // MARK: - Helpers

    private static func colorForCapture(_ name: String) -> NSColor {
        switch name {
        case "string":
            return stringColor
        case "number":
            return numberColor
        case "boolean":
            return booleanColor
        case "constant.builtin":
            return nullColor
        case "string.special.key":
            return keyColor
        case "escape":
            return escapeColor
        case "comment":
            return commentColor
        default:
            return punctuationColor
        }
    }
}
