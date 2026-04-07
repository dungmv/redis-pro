//
//  IconButton.swift
//  redis-pro
//
//  Liquid Glass icon + label button.
//

import SwiftUI

struct IconButton: View {
    var icon: String
    var name: String
    var disabled: Bool = false
    var action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: LiquidGlass.fontSizeSM, weight: .medium))
                    .symbolRenderingMode(.hierarchical)
                if !name.isEmpty {
                    Text(name)
                        .font(.system(size: LiquidGlass.fontSizeSM, weight: .medium))
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: LiquidGlass.radiusXS)
                    .fill(isHovered && !disabled
                          ? Color.primary.opacity(0.1)
                          : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(disabled ? Color.secondary : Color.primary)
        .disabled(disabled)
        .animation(.easeOut(duration: 0.15), value: isHovered)
        .onHover { inside in
            isHovered = inside
            if !disabled && inside { NSCursor.pointingHand.push() } else { NSCursor.pop() }
        }
    }
}
