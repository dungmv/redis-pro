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
    
    private let logger = Logger(label: "data-table")

    var body: some View {
        List(viewModel.datasource, selection: $selection) { item in
            HStack(spacing: 12) {
                ForEach(viewModel.columns) { column in
                    Text(column.content(item))
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .frame(maxWidth: column.width ?? 100, alignment: .leading)
                }
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
