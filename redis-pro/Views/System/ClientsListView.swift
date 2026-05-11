//
//  ClientsListView.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/6/18.
//  Migrated to MVVM (Swift 6)
//

import SwiftUI
import Logging

struct ClientsListView: View {

    @State var viewModel: ClientListViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: LiquidGlass.spacing6) {
            NTableView(viewModel: viewModel.table)

            HStack(alignment: .center, spacing: LiquidGlass.spacing8) {
                Spacer()
                Button("Kill Client") {
                    viewModel.killConfirm(viewModel.table.selectIndex)
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.table.selectIndex < 0)
                Button("Refresh") { viewModel.refresh() }
                    .buttonStyle(.bordered)
            }
        }
        .onAppear {
            viewModel.initial()
        }
    }
}
