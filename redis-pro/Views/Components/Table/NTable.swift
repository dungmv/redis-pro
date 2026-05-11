//
//  NTable.swift
//  redis-pro
//
//  Created by chengpan on 2021/12/17.
//  Consolidated table component
//

import SwiftUI

struct NTableColumn<Item>: Identifiable {
    let id = UUID()
    var title: String
    var width: CGFloat?
    var content: (Item) -> String

    init(
        title: String,
        width: CGFloat? = nil,
        content: @escaping (Item) -> String
    ) {
        self.title = title
        self.width = width
        self.content = content
    }
}

struct NTableView<Item: Identifiable & Sendable & Hashable, ContextMenu: View>: View {
    let viewModel: TableViewModel<Item>
    @ViewBuilder let contextMenu: (Int) -> ContextMenu
    @State private var selection: Item.ID?

    init(viewModel: TableViewModel<Item>, @ViewBuilder contextMenu: @escaping (Int) -> ContextMenu) {
        self.viewModel = viewModel
        self.contextMenu = contextMenu
    }

    var body: some View {
        Table(viewModel.datasource, selection: $selection) {
            TableColumnForEach(viewModel.columns) { column in
                TableColumn(column.title) { item in
                    Text(column.content(item))
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .frame(maxWidth: column.width == nil ? .infinity : nil, alignment: .leading)
                }
                .width(min: 80, ideal: column.width)
            }
        }
        .contextMenu(forSelectionType: Item.ID.self) { selectedIDs in
            if let selectedID = selectedIDs.first,
               let index = viewModel.datasource.firstIndex(where: { $0.id == selectedID }) {
                contextMenu(index)
            }
        }
        .onChange(of: selection) { oldValue, newValue in
            if let id = newValue, let index = viewModel.datasource.firstIndex(where: { $0.id == id }) {
                viewModel.selectionChange(index: index, indexes: index >= 0 ? [index] : [])
            } else {
                viewModel.selectionChange(index: -1, indexes: [])
            }
        }
    }
}

extension NTableView where ContextMenu == EmptyView {
    init(viewModel: TableViewModel<Item>) {
        self.viewModel = viewModel
        self.contextMenu = { _ in EmptyView() }
    }
}
