//
//  RedisValueView.swift
//  redis-pro
//
//  Liquid Glass key value editor container.
//

import SwiftUI
import ComposableArchitecture

struct RedisValueView: View {
    var store: StoreOf<ValueStore>

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            RedisValueHeaderView(store: store.scope(state: \.keyState, action: \.keyAction))

            Divider()

            RedisValueEditView(store: store)
        }
    }
}
