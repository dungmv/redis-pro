//
//  MIcon.swift
//  redis-pro
//
//  Liquid Glass icon-only button.
//

import SwiftUI

struct MIcon: View {
    var icon: String
    var fontSize: CGFloat = LiquidGlass.fontSizeSM
    var disabled: Bool = false
    var action: () -> Void = {}

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: fontSize, weight: .medium))
                .symbolRenderingMode(.hierarchical)
                .frame(width: fontSize + 12, height: fontSize + 12)
                .background(
                    Circle()
                        .fill(
                            disabled
                            ? AnyShapeStyle(Color.clear)
                            : AnyShapeStyle(isHovered ? .regularMaterial : .thinMaterial)
                        )
                )
                .overlay(
                    Circle()
                        .strokeBorder(
                            disabled
                            ? Color.clear
                            : (isHovered ? LiquidGlass.glassStroke : LiquidGlass.glassBorder),
                            lineWidth: 0.5
                        )
                )
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(disabled ? AnyShapeStyle(Color.secondary) : AnyShapeStyle(Color.primary))
        .disabled(disabled)
        .animation(.easeOut(duration: 0.15), value: isHovered)
        .onHover { inside in
            isHovered = inside
            if !disabled && inside { NSCursor.pointingHand.push() } else { NSCursor.pop() }
        }
    }
}
