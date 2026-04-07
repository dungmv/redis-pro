//
//  RedisKeysListView.swift
//  redis-pro
//
//  Liquid Glass main split view (sidebar + content).
//

import SwiftUI
import Logging
import ComposableArchitecture

struct RedisKeysListView: View {

    var appStore: StoreOf<AppStore>
    var store: StoreOf<RedisKeysStore>

    private static let logger = Logger(label: "redis-key-list-view")

    init(_ store: StoreOf<AppStore>) {
        self.appStore = store
        self.store = store.scope(state: \.redisKeysState, action: \.redisKeysAction)
    }

    var body: some View {
        WithPerceptionTracking {
            HSplitView {
                // Sidebar
                sidebarPanel
                    .frame(minWidth: 260, idealWidth: 320, maxWidth: 440)
                    .layoutPriority(0)

                // Content
                contentPanel
                    .frame(minWidth: 560, maxWidth: .infinity, minHeight: 400, maxHeight: .infinity)
                    .layoutPriority(1)
            }
        }
    }

    // MARK: - Sidebar

    private var sidebarPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            sidebarHeader
            Divider()
            RedisKeysTreeView(store: store)
            Divider()
            sidebarFooter
        }
    }

    private var sidebarHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            SearchBar(placeholder: "Search keys...", onCommit: { store.send(.search($0)) })

            HStack(spacing: 4) {
                IconButton(icon: "plus", name: "Add") { store.send(.addNew) }
                IconButton(
                    icon: "trash",
                    name: "Delete",
                    disabled: !store.tableState.isSelect
                ) { store.send(.deleteConfirm(store.tableState.selectIndexes)) }

                Spacer()
                DatabasePicker(store: store.scope(state: \.databaseState, action: \.databaseAction))
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 8)
        .padding(.bottom, 6)
        .glassToolbar()
    }

    private var sidebarFooter: some View {
        HStack(alignment: .center, spacing: 6) {
            Menu {
                Button("Keys Del")     { store.send(.redisSystemAction(.setSystemView(.KEYS_DEL))) }
                Button("Redis Info")   { store.send(.redisSystemAction(.setSystemView(.REDIS_INFO))) }
                Button("Redis Config") { store.send(.redisSystemAction(.setSystemView(.REDIS_CONFIG))) }
                Button("Clients")      { store.send(.redisSystemAction(.setSystemView(.CLIENT_LIST))) }
                Button("Slow Log")     { store.send(.redisSystemAction(.setSystemView(.SLOW_LOG))) }
                Button("Lua")          { store.send(.redisSystemAction(.setSystemView(.LUA))) }
                Divider()
                Button("Flush DB", role: .destructive) { store.send(.flushDBConfirm) }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .menuStyle(.borderlessButton)
            .frame(width: 24)

            MIcon(icon: "arrow.clockwise", fontSize: 12) { store.send(.refresh) }
                .help("Refresh keys")

            Spacer(minLength: 0)

            Text("db: \(store.dbsize)")
                .font(LiquidGlass.FONT_FOOTER)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            PageBar(store: store.scope(state: \.pageState, action: \.pageAction))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .glassToolbar()
    }

    // MARK: - Content

    private var contentPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            switch store.mainViewType {
            case .EDITOR:
                RedisValueView(store: store.scope(state: \.valueState, action: \.valueAction))
            case .SYSTEM:
                RedisSystemView(store: store.scope(state: \.redisSystemState, action: \.redisSystemAction))
            case .NONE:
                EmptyView()
            }
            Spacer()
        }
        .padding(LiquidGlass.spacing8)
    }
}
