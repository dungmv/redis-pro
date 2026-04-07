//
//  RedisValueHeaderView.swift
//  redis-pro
//
//  Liquid Glass key editor toolbar.
//

import SwiftUI
import Logging
import ComposableArchitecture

struct RedisValueHeaderView: View {

    @Bindable var store: StoreOf<KeyStore>
    private static let logger = Logger(label: "redis-value-header")

    var body: some View {
        WithPerceptionTracking {
            HStack(alignment: .center, spacing: 12) {
                // Key field
                FormItemText(
                    label: "Key",
                    labelWidth: 36,
                    required: true,
                    editable: store.isNew,
                    value: $store.key
                )
                .frame(maxWidth: .infinity)
                .font(LiquidGlass.fontMono)

                // Type picker
                RedisKeyTypePicker(label: "Type", value: $store.type, disabled: !store.isNew)

                // TTL field
                ttlView
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .glassToolbar()
        }
    }

    private var ttlView: some View {
        HStack(spacing: 6) {
            FormItemInt(
                label: "TTL(s)",
                labelWidth: 46,
                value: $store.ttl,
                suffix: "square.and.pencil",
                onCommit: { store.send(.saveTtl) }
            )
            .disabled(store.isNew)
            .help("TTL in seconds, -1 = no expiry")
            .frame(width: 180)

            // TTL indicator chip
            if !store.isNew {
                ttlBadge
            }
        }
    }

    @ViewBuilder
    private var ttlBadge: some View {
        let ttl = store.ttl
        if ttl == -1 {
            Label("No Expiry", systemImage: "infinity")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.green)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(.green.opacity(0.1), in: Capsule())
        } else if ttl > 0 {
            Label("\(ttl)s", systemImage: "clock")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(ttl < 60 ? Color.red : Color.orange)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background((ttl < 60 ? Color.red : Color.orange).opacity(0.1), in: Capsule())
        }
    }
}
