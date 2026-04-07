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
                .frame(width: fontSize + 8, height: fontSize + 8)
                .background(
                    Circle()
                        .fill(isHovered && !disabled
                              ? Color.primary.opacity(0.10)
                              : Color.clear)
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
