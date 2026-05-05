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
            .clipShape(RoundedRectangle(cornerRadius: LiquidGlass.radiusSM, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: LiquidGlass.radiusSM, style: .continuous)
                    .strokeBorder(borderColor(for: configuration), lineWidth: 0.5)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(isEnabled ? 1.0 : 0.45)
            .animation(.spring(response: 0.2, dampingFraction: 0.8), value: configuration.isPressed)
    }

    @ViewBuilder
    private func background(for configuration: Configuration) -> some View {
        switch variant {
        case .primary:
            RoundedRectangle(cornerRadius: LiquidGlass.radiusSM, style: .continuous)
                .fill(Color.accentColor.opacity(configuration.isPressed ? 0.82 : 0.95))
        case .destructive:
            RoundedRectangle(cornerRadius: LiquidGlass.radiusSM, style: .continuous)
                .fill(Color.red.opacity(configuration.isPressed ? 0.82 : 0.92))
        case .plain:
            RoundedRectangle(cornerRadius: LiquidGlass.radiusSM, style: .continuous)
                .fill(Color.clear)
        default:
            RoundedRectangle(cornerRadius: LiquidGlass.radiusSM, style: .continuous)
                .fill(configuration.isPressed ? AnyShapeStyle(.regularMaterial) : AnyShapeStyle(.thinMaterial))
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

    private func borderColor(for configuration: Configuration) -> Color {
        switch variant {
        case .primary:
            return Color.accentColor.opacity(configuration.isPressed ? 0.45 : 0.35)
        case .destructive:
            return Color.red.opacity(configuration.isPressed ? 0.45 : 0.35)
        default:
            return configuration.isPressed ? LiquidGlass.glassStroke : LiquidGlass.glassBorder
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


