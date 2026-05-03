//
//  LiquidGlass.swift
//  redis-pro
//
//  Liquid Glass Design System for macOS 15 Sequoia
//

import SwiftUI
import AppKit

// Keep MTheme as a thin alias for backward-compat
typealias MTheme = LiquidGlass

// MARK: - Design Tokens

enum LiquidGlass {

    // ── Spacing ─────────────────────────────────────────────────────────────
    static let spacing2:  CGFloat = 2
    static let spacing4:  CGFloat = 4
    static let spacing6:  CGFloat = 6
    static let spacing8:  CGFloat = 8
    static let spacing12: CGFloat = 12
    static let spacing16: CGFloat = 16
    static let spacing20: CGFloat = 20
    static let spacing24: CGFloat = 24

    // backward-compat aliases
    static var H_SPACING:   CGFloat { spacing6 }
    static var H_SPACING_L: CGFloat { spacing10 }
    static var V_SPACING:   CGFloat { spacing6 }
    static var spacing10:   CGFloat { 10 }

    // ── Corner Radius ────────────────────────────────────────────────────────
    static let radiusXS:  CGFloat = 4
    static let radiusSM:  CGFloat = 6
    static let radiusMD:  CGFloat = 8
    static let radiusLG:  CGFloat = 12
    static let radiusXL:  CGFloat = 16
    static let radiusFull: CGFloat = 50

    // backward-compat
    static var CORNER_RADIUS: CGFloat { radiusSM }

    // ── Dialog sizes ─────────────────────────────────────────────────────────
    static var DIALOG_W: CGFloat { 640 }
    static var DIALOG_H: CGFloat { 400 }

    // ── Header Padding ───────────────────────────────────────────────────────
    static var HEADER_PADDING: EdgeInsets { .init(top: 4, leading: 0, bottom: 4, trailing: 0) }

    // ── Font sizes ───────────────────────────────────────────────────────────
    static let fontSizeXS:   CGFloat = 10
    static let fontSizeSM:   CGFloat = 11
    static let fontSizeMD:   CGFloat = 12
    static let fontSizeLG:   CGFloat = 13
    static let fontSizeXL:   CGFloat = 15

    // backward-compat button font sizes
    static var FONT_SIZE_BUTTON:       CGFloat { fontSizeMD }
    static var FONT_SIZE_BUTTON_ICON:  CGFloat { fontSizeSM }
    static var FONT_SIZE_BUTTON_S:     CGFloat { fontSizeXS }
    static var FONT_SIZE_BUTTON_ICON_S: CGFloat { 9 }
    static var FONT_SIZE_BUTTON_L:     CGFloat { fontSizeLG }
    static var FONT_SIZE_BUTTON_ICON_L: CGFloat { fontSizeMD }

    // ── Typography ───────────────────────────────────────────────────────────
    static var FONT_FOOTER: Font { .system(size: fontSizeXS, weight: .regular) }
    static var fontCaption: Font { .system(size: fontSizeXS, weight: .medium) }
    static var fontBody:    Font { .system(size: fontSizeMD, weight: .regular) }
    static var fontMono:    Font { .system(size: fontSizeMD, design: .monospaced) }
    static var fontLabel:   Font { .system(size: fontSizeSM, weight: .medium) }

    // ── Null placeholder ─────────────────────────────────────────────────────
    static var NULL_STRING: String { "–" }
    static var PRIMARY: Color { .secondary }

    // ── Semantic Colors ──────────────────────────────────────────────────────
    /// Shared semantic surfaces tuned toward native macOS materials.
    static var glassSurface: Color { Color(NSColor.windowBackgroundColor).opacity(0.42) }
    static var glassBorder:  Color { Color(NSColor.separatorColor).opacity(0.45) }
    static var glassStroke:  Color { Color.primary.opacity(0.18) }
    static var glassHighlight: Color { Color.white.opacity(0.16) }
    static var glassShadow: Color { Color.black.opacity(0.10) }

    // ── Redis type colors ────────────────────────────────────────────────────
    static func typeColor(for type: String) -> Color {
        switch type.uppercased() {
        case "STRING": return Color(red: 0.20, green: 0.74, blue: 0.40) // jade green
        case "HASH":   return Color(red: 0.94, green: 0.36, blue: 0.36) // coral red
        case "LIST":   return Color(red: 0.28, green: 0.56, blue: 0.95) // sky blue
        case "SET":    return Color(red: 0.98, green: 0.62, blue: 0.22) // amber
        case "ZSET":   return Color(red: 0.62, green: 0.38, blue: 0.96) // violet
        default:       return Color.secondary
        }
    }
}

// MARK: - Glass ViewModifiers

/// Full vibrancy glass card.
struct GlassCard: ViewModifier {
    var cornerRadius: CGFloat = LiquidGlass.radiusMD

    func body(content: Content) -> some View {
        content
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(LiquidGlass.glassBorder, lineWidth: 0.5)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(LiquidGlass.glassHighlight, lineWidth: 0.5)
                    .blendMode(.screen)
            )
            .shadow(color: LiquidGlass.glassShadow, radius: 10, x: 0, y: 4)
    }
}

/// Subtle glass background for input fields.
struct GlassField: ViewModifier {
    var cornerRadius: CGFloat = LiquidGlass.radiusXS
    var isActive: Bool = false

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.thinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(
                        isActive ? Color.accentColor.opacity(0.55) : LiquidGlass.glassStroke,
                        lineWidth: isActive ? 1.5 : 1
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(LiquidGlass.glassHighlight, lineWidth: 0.5)
                    .blendMode(.screen)
            )
            .animation(.spring(duration: 0.2), value: isActive)
    }
}

/// Floating toolbar background (thin material + separator).
struct GlassToolbar: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.thinMaterial)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(LiquidGlass.glassBorder)
                    .frame(height: 0.5)
            }
    }
}

struct GlassWindowSurface: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.regularMaterial)
            .overlay {
                LinearGradient(
                    colors: [
                        LiquidGlass.glassHighlight.opacity(0.45),
                        .clear
                    ],
                    startPoint: .top,
                    endPoint: .center
                )
                .allowsHitTesting(false)
            }
    }
}

// MARK: - View Extensions

extension View {
    func glassCard(cornerRadius: CGFloat = LiquidGlass.radiusMD) -> some View {
        modifier(GlassCard(cornerRadius: cornerRadius))
    }

    func glassField(cornerRadius: CGFloat = LiquidGlass.radiusXS, isActive: Bool = false) -> some View {
        modifier(GlassField(cornerRadius: cornerRadius, isActive: isActive))
    }

    func glassToolbar() -> some View {
        modifier(GlassToolbar())
    }

    func glassWindowSurface() -> some View {
        modifier(GlassWindowSurface())
    }

    /// Hover cursor + subtle scale animation for interactive elements.
    func hoverEffect(scale: CGFloat = 1.04) -> some View {
        modifier(HoverScaleEffect(scale: scale))
    }

    // backward-compat border helpers
    func border(width: CGFloat, edges: [Edge], color: Color) -> some View {
        overlay(EdgeBorder(width: width, edges: edges).foregroundColor(color))
    }

    func addBorder<S: ShapeStyle>(_ content: S, width: CGFloat = 1, cornerRadius: CGFloat) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius)
        return clipShape(shape)
            .overlay(shape.strokeBorder(content, lineWidth: width))
    }
}

// MARK: - HoverScaleEffect

private struct HoverScaleEffect: ViewModifier {
    let scale: CGFloat
    @State private var isHovered = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isHovered ? scale : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isHovered)
            .onHover { inside in
                isHovered = inside
                if inside { NSCursor.pointingHand.push() } else { NSCursor.pop() }
            }
    }
}

// MARK: - EdgeBorder (kept from Extensions.swift)

struct EdgeBorder: Shape {
    var width: CGFloat
    var edges: [Edge]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        for edge in edges {
            let x: CGFloat
            let y: CGFloat
            let w: CGFloat
            let h: CGFloat

            switch edge {
            case .top:
                x = rect.minX; y = rect.minY; w = rect.width; h = width
            case .bottom:
                x = rect.minX; y = rect.maxY - width; w = rect.width; h = width
            case .leading:
                x = rect.minX; y = rect.minY; w = width; h = rect.height
            case .trailing:
                x = rect.maxX - width; y = rect.minY; w = width; h = rect.height
            }
            path.addPath(Path(CGRect(x: x, y: y, width: w, height: h)))
        }
        return path
    }
}

// MARK: - Date helpers (kept from Extensions.swift)

extension Date {
    var timestamp: Int { Int(timeIntervalSince1970) }
    var millis: Int64 { Int64((timeIntervalSince1970 * 1000).rounded()) }
}
