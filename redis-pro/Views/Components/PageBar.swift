//
//  PageBar.swift
//  redis-pro
//
//  Liquid Glass pagination controls.
//

import SwiftUI
import ComposableArchitecture

struct PageBar: View {
    @Bindable var store: StoreOf<PageStore>

    var body: some View {
        WithPerceptionTracking {
            HStack(alignment: .center, spacing: 4) {
                if store.showTotal {
                    Text("Total: \(store.total)")
                        .font(LiquidGlass.FONT_FOOTER)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                // Page size picker
                Picker("", selection: $store.size) {
                    Text("10").tag(10)
                    Text("50").tag(50)
                    Text("100").tag(100)
                    Text("200").tag(200)
                }
                .pickerStyle(.menu)
                .frame(width: 60)
                .labelsHidden()

                // Prev / page info / Next
                HStack(spacing: 2) {
                    Button(action: { store.send(.prevPage) }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .buttonStyle(.plain)
                    .disabled(!store.hasPrev)
                    .foregroundStyle(store.hasPrev ? Color.primary : Color.secondary)

                    Text("\(store.current)/\(store.totalPageText)")
                        .font(LiquidGlass.FONT_FOOTER)
                        .foregroundStyle(.secondary)
                        .frame(minWidth: 36)
                        .multilineTextAlignment(.center)
                        .lineLimit(1)

                    Button(action: { store.send(.nextPage) }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .buttonStyle(.plain)
                    .disabled(!store.hasNext)
                    .foregroundStyle(store.hasNext ? Color.primary : Color.secondary)
                }
            }
        }
    }
}
