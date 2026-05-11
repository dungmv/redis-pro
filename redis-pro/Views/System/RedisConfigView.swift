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
        VStack(alignment: .leading, spacing: LiquidGlass.V_SPACING) {
            HStack(alignment: .center, spacing: LiquidGlass.H_SPACING) {
                SearchBar(placeholder: "Search config...", onCommit: { viewModel.search($0) })
                Spacer()
                Button("Rewrite") { viewModel.rewrite() }
                    .buttonStyle(.bordered)
                    .help("REDIS_CONFIG_REWRITE")
            }.padding(LiquidGlass.HEADER_PADDING)

            NTableView(viewModel: viewModel.table)

            HStack(alignment: .center, spacing: LiquidGlass.H_SPACING) {
                Spacer()
                Button("Refresh") { viewModel.refresh() }
                    .buttonStyle(.bordered)
            }
        }
        .sheet(isPresented: Binding(get: { viewModel.editModalVisible }, set: { viewModel.editModalVisible = $0 })) {
            ModalView("Edit Config Key: \(viewModel.editKey)", action: { viewModel.submit() }) {
                MTextEditor(text: Binding(get: { viewModel.editValue }, set: { viewModel.editValue = $0 }))
                    .frame(minWidth: 500, minHeight: 300)
            }
        }
        .onAppear {
            viewModel.initial()
        }
    }
}
