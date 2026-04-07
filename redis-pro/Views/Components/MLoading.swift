//
//  MLoading.swift
//  redis-pro
//
//  Liquid Glass inline loading indicator.
//

import SwiftUI

struct MLoading: View {
    var text: String
    var loadingText: String = "Connecting..."
    var loading: Bool = false

    var body: some View {
        HStack(spacing: 6) {
            if loading {
                ProgressView()
                    .controlSize(.small)
                    .tint(.accentColor)
                    .transition(.opacity.combined(with: .scale(scale: 0.7)))
            }
            Text(loading ? loadingText : text)
                .font(LiquidGlass.fontBody)
                .foregroundStyle(loading ? Color.accentColor : Color.primary)
                .lineLimit(1)
                .contentTransition(.numericText())
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: loading)
    }
}
