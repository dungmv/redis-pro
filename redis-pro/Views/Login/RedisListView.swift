//
//  RedisListView.swift
//  redis-pro
//
//  Sidebar connection list + login form split view.
//  Migrated to MVVM (Swift 6)
//

import SwiftUI
import Logging

struct RedisListView: View {

    private static let logger = Logger(label: "redis-list-view")

    @State var viewModel: FavoriteViewModel

    private var selection: Binding<Int?> {
        Binding<Int?>(
            get: {
                let idx = viewModel.table.selectIndex
                return idx >= 0 ? idx : nil
            },
            set: { newValue in
                if let index = newValue {
                    viewModel.table.selectionChange(index: index, indexes: [index])
                }
            }
        )
    }

    var body: some View {
        HSplitView {
            // ── Connection list (left sidebar) ────────────────────────
            VStack(alignment: .leading, spacing: 0) {
                // Sidebar header
                HStack {
                    Text("CONNECTIONS")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.secondary)
                        .kerning(0.8)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .glassToolbar()

                Divider()

                // Connections list (single column, no table header)
                List(selection: selection) {
                    ForEach(Array(viewModel.table.datasource.enumerated()), id: \.offset) { index, model in
                        Text(model.name.isEmpty ? "New Connection" : model.name)
                            .tag(index)
                            .onTapGesture(count: 2) {
                                viewModel.connect(index)
                            }
                    }
                }
                .listStyle(.sidebar)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onDeleteCommand {
                    if let idx = selection.wrappedValue {
                        viewModel.deleteConfirm(idx)
                    }
                }

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
            .frame(minWidth: 200, idealWidth: 240, maxWidth: 320)
            .layoutPriority(0)
            .onAppear { onLoad() }

            // ── Login form (right panel) ───────────────────────────────
            LoginForm(viewModel: viewModel.login)
                .background(.regularMaterial)
                .layoutPriority(1)
                .frame(minWidth: 400, idealWidth: 500, maxWidth: .infinity, minHeight: 520, maxHeight: .infinity)
        }
        .glassWindowSurface()
    }

    private func onLoad() {
        viewModel.getAll()
        viewModel.initDefaultSelection()
        // Apply default selection now that datasource is loaded
        let idx = viewModel.table.defaultSelectIndex
        if idx >= 0, idx < viewModel.table.datasource.count {
            viewModel.table.selectionChange(index: idx, indexes: [idx])
        }
    }
}
