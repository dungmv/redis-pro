//
//  RedisConfigView.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/7/21.
//  Migrated to MVVM (Swift 6)
//

import SwiftUI
import Logging

struct RedisConfigView: View {

    @State var viewModel: RedisConfigViewModel
    let logger = Logger(label: "redis-config-view")

    var body: some View {
        VStack(alignment: .leading, spacing: MTheme.V_SPACING) {
            HStack(alignment: .center, spacing: MTheme.H_SPACING) {
                SearchBar(placeholder: "Search config...", onCommit: { viewModel.search($0) })
                Spacer()
                MButton(text: "Rewrite", action: { viewModel.rewrite() })
                    .help("REDIS_CONFIG_REWRITE")
            }.padding(MTheme.HEADER_PADDING)

            NTableView(viewModel: viewModel.table)

            HStack(alignment: .center, spacing: MTheme.H_SPACING) {
                Spacer()
                MButton(text: "Refresh", action: { viewModel.refresh() })
            }
        }
        .sheet(isPresented: Binding(get: { viewModel.editModalVisible }, set: { viewModel.editModalVisible = $0 })) {
            ModalView("Edit Config Key: \(viewModel.editKey)", action: { viewModel.submit() }) {
                VStack(alignment: .leading, spacing: MTheme.V_SPACING) {
                    MTextView(text: Binding(get: { viewModel.editValue }, set: { viewModel.editValue = $0 }))
                }
                .frame(minWidth: 500, minHeight: 300)
            }
        }
        .onAppear {
            viewModel.initial()
        }
    }
}
