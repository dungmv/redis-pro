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
        Button(action: { action?() }) {
            Text(text)
                .font(.system(size: LiquidGlass.fontSizeMD, weight: .medium))
        }
        .buttonStyle(LiquidButtonStyle(variant: style))
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

// MARK: - LiquidButtonStyle

struct LiquidButtonStyle: ButtonStyle {
    let variant: MButtonVariant
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(background(for: configuration))
            .foregroundStyle(foreground)
            .clipShape(RoundedRectangle(cornerRadius: LiquidGlass.radiusXS))
            .overlay(
                RoundedRectangle(cornerRadius: LiquidGlass.radiusXS)
                    .strokeBorder(borderColor, lineWidth: 0.5)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(isEnabled ? 1.0 : 0.45)
            .animation(.spring(response: 0.2, dampingFraction: 0.8), value: configuration.isPressed)
    }

    @ViewBuilder
    private func background(for configuration: Configuration) -> some View {
        switch variant {
        case .primary:
            RoundedRectangle(cornerRadius: LiquidGlass.radiusXS)
                .fill(Color.accentColor.opacity(configuration.isPressed ? 0.75 : 1.0))
        case .destructive:
            RoundedRectangle(cornerRadius: LiquidGlass.radiusXS)
                .fill(Color.red.opacity(configuration.isPressed ? 0.75 : 0.85))
        case .plain:
            RoundedRectangle(cornerRadius: LiquidGlass.radiusXS)
                .fill(Color.clear)
        default:
            RoundedRectangle(cornerRadius: LiquidGlass.radiusXS)
                .fill(.ultraThinMaterial)
                .brightness(configuration.isPressed ? -0.05 : 0)
        }
    }

    private var foreground: AnyShapeStyle {
        switch variant {
        case .primary, .destructive:
            return AnyShapeStyle(.white)
        default:
            return AnyShapeStyle(.primary)
        }
    }

    private var borderColor: Color {
        switch variant {
        case .primary:   return Color.accentColor.opacity(0.3)
        case .destructive: return Color.red.opacity(0.3)
        default:         return LiquidGlass.glassBorder
        }
    }
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
        .buttonStyle(LiquidButtonStyle(variant: .default))
        .disabled(disabled)
    }
}

// MARK: - ControlActionClosureProtocol (backward-compat for any remaining NSControl usage)

private var controlActionClosureProtocolAssociatedObjectKey: UInt8 = 0

protocol ControlActionClosureProtocol: NSObjectProtocol {
    var target: AnyObject? { get set }
    var action: Selector? { get set }
}

private final class ActionTrampoline<T>: NSObject {
    let action: (T) -> Void
    init(action: @escaping (T) -> Void) { self.action = action }

    @objc func action(sender: AnyObject) { action(sender as! T) }
}

extension ControlActionClosureProtocol {
    func onAction(_ action: @escaping (Self) -> Void) {
        let trampoline = ActionTrampoline(action: action)
        self.target = trampoline
        self.action = #selector(ActionTrampoline<Self>.action(sender:))
        objc_setAssociatedObject(self, &controlActionClosureProtocolAssociatedObjectKey, trampoline, .OBJC_ASSOCIATION_RETAIN)
    }
}

extension NSControl: ControlActionClosureProtocol {}
