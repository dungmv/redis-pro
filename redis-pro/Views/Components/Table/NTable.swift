//
//  NTable.swift
//  redis-pro
//
//  Created by chengpan on 2021/12/17.
//  Migrated to SwiftUI Table
//

import SwiftUI

struct NTableView<Item: Identifiable & Sendable & Hashable>: View {
    let viewModel: TableViewModel<Item>
    
    var body: some View {
        DataTable(viewModel: viewModel)
    }
}
