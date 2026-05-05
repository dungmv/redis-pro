//
//  RedisListView.swift
//  redis-pro
//
//  Liquid Glass connection list + login form split view.
//  Migrated to MVVM (Swift 6)
//

import SwiftUI
import Logging

struct RedisListView: View {

    private static let logger = Logger(label: "redis-list-view")

    @State var viewModel: FavoriteViewModel

    var body: some View {
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
                NTableView(viewModel: viewModel.table)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                Divider()

                // Footer controls
                HStack(alignment: .center, spacing: 2) {
                    MIcon(icon: "plus", fontSize: 13) { viewModel.addNew() }
                        .help("Add new connection")
                    MIcon(
                        icon: "minus",
                        fontSize: 13,
                        disabled: viewModel.table.selectIndex < 0
                    ) {
                        viewModel.deleteConfirm(viewModel.table.selectIndex)
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
            LoginForm(viewModel: viewModel.login)
                .background(.regularMaterial)
                .frame(minWidth: 800, maxWidth: .infinity, minHeight: 520, maxHeight: .infinity)
        }
        .glassWindowSurface()
    }

    private func onLoad() {
        viewModel.getAll()
        viewModel.initDefaultSelection()
    }
}
