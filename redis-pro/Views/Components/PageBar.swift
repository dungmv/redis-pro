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

                Picker("", selection: $store.size) {
                    Text("10").tag(10)
                    Text("50").tag(50)
                    Text("100").tag(100)
                    Text("200").tag(200)
                }
                .pickerStyle(.menu)
                .frame(width: 60)
                .labelsHidden()

                HStack(spacing: 6) {
                    MIcon(icon: "chevron.left", fontSize: 10, disabled: !store.hasPrev) {
                        store.send(.prevPage)
                    }

                    Text("\(store.current)/\(store.totalPageText)")
                        .font(LiquidGlass.FONT_FOOTER)
                        .foregroundStyle(.secondary)
                        .frame(minWidth: 36)
                        .multilineTextAlignment(.center)
                        .lineLimit(1)

                    MIcon(icon: "chevron.right", fontSize: 10, disabled: !store.hasNext) {
                        store.send(.nextPage)
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .glassCard(cornerRadius: LiquidGlass.radiusLG)
        }
    }
}
