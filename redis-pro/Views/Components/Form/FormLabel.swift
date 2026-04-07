//
//  FormLabel.swift
//  redis-pro
//
//  Liquid Glass form label.
//

import SwiftUI

struct FormLabel: View {
    var label: String
    var width: CGFloat?
    var required: Bool = false

    var body: some View {
        HStack(spacing: 2) {
            if required {
                Text("*")
                    .font(LiquidGlass.fontLabel)
                    .foregroundStyle(Color.red)
            }
            Text("\(label):")
                .font(LiquidGlass.fontLabel)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(width: width, alignment: .trailing)
    }
}
