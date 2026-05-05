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
        VStack(alignment: .leading, spacing: MTheme.V_SPACING) {
            NTableView(viewModel: viewModel.table)

            HStack(alignment: .center, spacing: 8) {
                Spacer()
                MButton(
                    text: "Kill Client",
                    action: { viewModel.killConfirm(viewModel.table.selectIndex) },
                    disabled: viewModel.table.selectIndex < 0
                )
                MButton(text: "Refresh", action: { viewModel.refresh() })
            }
        }
        .onAppear {
            viewModel.initial()
        }
    }
}
