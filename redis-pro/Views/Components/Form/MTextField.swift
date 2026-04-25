//
//  MTextField.swift
//  redis-pro
//
//  Liquid Glass styled text field.
//

import SwiftUI

struct MTextField: View {
    @Binding var value: String
    var placeholder: String?
    var onCommit: (() -> Void)?
    var autoCommit: Bool = true
    var editable: Bool = true
    var autoTrim: Bool = false

    @FocusState private var isFocused: Bool

    private var trimmedBinding: Binding<String> {
        Binding(
            get: { value },
            set: { value = autoTrim ? $0.trimmingCharacters(in: .whitespacesAndNewlines) : $0 }
        )
    }

    var body: some View {
        Group {
            if editable {
                TextField("", text: trimmedBinding, prompt: Text(placeholder ?? "").foregroundColor(.secondary))
                    .textFieldStyle(.plain)
                    .onSubmit { onCommit?() }
                    .focused($isFocused)
                    .onHover { isHovered in
                        if isHovered { NSCursor.iBeam.push() } else { NSCursor.pop() }
                    }
            } else {
                Text(value)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .font(LiquidGlass.fontBody)
        .lineLimit(1)
        .multilineTextAlignment(.leading)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: LiquidGlass.radiusXS)
                .fill(editable
                      ? Color(NSColor.textBackgroundColor).opacity(0.85)
                      : Color.primary.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: LiquidGlass.radiusXS)
                .strokeBorder(
                    isFocused ? Color.accentColor.opacity(0.6) : LiquidGlass.glassStroke,
                    lineWidth: isFocused ? 1.5 : 1
                )
        )
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isFocused)
    }
}
