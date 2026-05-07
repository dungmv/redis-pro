//
//  MButton.swift
//  redis-pro
//
//  Liquid Glass native SwiftUI button — replaces the old NSButton wrapper.
//

import SwiftUI

// MARK: - MButton

struct MButton: View {
    var text: String
    var action: (() -> Void)?
    var disabled: Bool = false
    var style: MButtonVariant = .default
    var keyEquivalent: MKeyEquivalent?

    var body: some View {
        Group {
            switch style {
            case .primary:
                Button(role: style == .destructive ? .destructive : nil, action: { action?() }) {
                    Text(text)
                        .font(.callout.weight(.medium))
                }
                .buttonStyle(.borderedProminent)
            case .plain:
                Button(role: style == .destructive ? .destructive : nil, action: { action?() }) {
                    Text(text)
                        .font(.callout.weight(.medium))
                }
                .buttonStyle(.plain)
            default:
                Button(role: style == .destructive ? .destructive : nil, action: { action?() }) {
                    Text(text)
                        .font(.callout.weight(.medium))
                }
                .buttonStyle(.bordered)
            }
        }
        .disabled(disabled)
        .apply {
            if let ke = keyEquivalent {
                $0.keyboardShortcut(KeyboardShortcut(ke.swiftUIEquivalent))
            } else {
                $0
            }
        }
    }
}

// MARK: - Button Variant

enum MButtonVariant {
    case `default`
    case primary
    case destructive
    case plain
}


// MARK: - MKeyEquivalent

enum MKeyEquivalent: String {
    case escape  = "\u{1b}"
    case `return` = "\r"

    var swiftUIEquivalent: KeyEquivalent {
        switch self {
        case .escape:  return .escape
        case .return:  return .return
        }
    }
}

// MARK: - View apply helper

private extension View {
    @ViewBuilder
    func apply<V: View>(@ViewBuilder transform: (Self) -> V) -> V {
        transform(self)
    }
}

// MARK: - Backward-compat NButton kept for any call sites that use it directly
// (NButton is no longer needed but kept temporarily to avoid compile errors
//  while other callers are updated)

@available(macOS 15.0, *)
struct NButton: View {
    var title: String? = nil
    var keyEquivalent: MKeyEquivalent? = nil
    let action: () -> Void
    var icon: String? = nil
    var disabled: Bool = false

    var body: some View {
        Button(action: action) {
            if let icon = icon {
                if icon.isEmpty || title == nil || title!.isEmpty {
                    Label(title ?? "", systemImage: icon)
                        .labelStyle(.iconOnly)
                } else {
                    Label(title ?? "", systemImage: icon)
                        .labelStyle(.titleAndIcon)
                }
            } else {
                Text(title ?? "")
            }
        }
        .buttonStyle(.bordered)
        .disabled(disabled)
    }
}


