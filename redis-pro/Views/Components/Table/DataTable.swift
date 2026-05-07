//
//  DataTable.swift
//  redis-pro
//
//  SwiftUI Table replacement for NSTableView
//

import SwiftUI
import Logging

struct DataTable<Item: Identifiable & Sendable & Hashable>: View {
    @State var viewModel: TableViewModel<Item>
    @State private var selection: Item.ID?

    var body: some View {
        Table(viewModel.datasource, selection: $selection) {
            TableColumnForEach(viewModel.columns) { column in
                TableColumn(column.title) { item in
                    Text(column.content(item))
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                .width(min: 80, ideal: column.width)
            }
        }
        .contextMenu(forSelectionType: Item.ID.self) { selectedIDs in
            if let selectedID = selectedIDs.first,
               let index = viewModel.datasource.firstIndex(where: { $0.id == selectedID }) {
                ForEach(viewModel.contextMenus, id: \.self) { menu in
                    Button(menu.rawValue) {
                        viewModel.contextMenu(title: menu.rawValue, index: index)
                    }
                    if menu == .COPY {
                        Divider()
                    }
                }
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
