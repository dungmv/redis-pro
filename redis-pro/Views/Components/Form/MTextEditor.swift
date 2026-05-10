//
//  MTextEditor.swift
//  redis-pro
//
//  Migrated to LiquidGlass (Swift 6)
//

import SwiftUI

struct MTextEditor: View {
    @Binding var text: String
    @FocusState private var isFocused: Bool

    var body: some View {
        TextEditor(text: $text)
            .font(.body)
            .multilineTextAlignment(.leading)
            .lineSpacing(1.5)
            .disableAutocorrection(true)
            .scrollContentBackground(.hidden)
            .focused($isFocused)
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .glassField(cornerRadius: LiquidGlass.radiusXS, isActive: isFocused)
    }
}

extension NSTextView {
    open override var frame: CGRect {
        didSet {
            self.isAutomaticQuoteSubstitutionEnabled = false
        }
    }
}
