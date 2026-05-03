//
//  RedisListView.swift
//  redis-pro
//
//  Liquid Glass connection list + login form split view.
//

import SwiftUI
import Logging
import ComposableArchitecture

struct RedisListView: View {

    private static let logger = Logger(label: "redis-list-view")

    var store: StoreOf<FavoriteStore>

    var body: some View {
        WithPerceptionTracking {
            HSplitView {
                // ── Connection list (left sidebar) ────────────────────────
                VStack(alignment: .leading, spacing: 0) {
                    // Sidebar header
                    HStack {
                        Text("FAVORITES")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.secondary)
                            .kerning(0.8)
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .glassToolbar()

                    Divider()

                    // Connections table
                    NTableView(store: store.scope(state: \.tableState, action: \.tableAction))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    Divider()

                    // Footer controls
                    HStack(alignment: .center, spacing: 2) {
                        MIcon(icon: "plus", fontSize: 13) { store.send(.addNew) }
                            .help("Add new connection")
                        MIcon(
                            icon: "minus",
                            fontSize: 13,
                            disabled: store.tableState.selectIndex < 0
                        ) {
                            store.send(.deleteConfirm(store.tableState.selectIndex))
                        }
                        .help("Remove connection")
                        Spacer()
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .glassToolbar()
                }
                .background(.thinMaterial)
                .frame(minWidth: 200, idealWidth: 220)
                .layoutPriority(0)
                .onAppear { onLoad() }

                // ── Login form (right panel) ───────────────────────────────
                LoginForm(store: store.scope(state: \.loginState, action: \.loginAction))
                    .background(.regularMaterial)
                    .frame(minWidth: 800, maxWidth: .infinity, minHeight: 520, maxHeight: .infinity)
            }
            .glassWindowSurface()
        }
    }

    private func onLoad() {
        store.send(.getAll)
        store.send(.initDefaultSelection)
    }
}
