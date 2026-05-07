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
                TextField("", text: trimmedBinding, prompt: Text(placeholder ?? ""))
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { onCommit?() }
                    .focused($isFocused)
            } else {
                Text(value)
                    .textSelection(.enabled)
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
            }
        }
        .lineLimit(1)
        .multilineTextAlignment(.leading)
        .opacity(editable ? 1 : 0.82)
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isFocused)
    }
}
