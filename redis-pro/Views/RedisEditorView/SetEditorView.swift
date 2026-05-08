//
//  SetEditorView.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/4/30.
//  Migrated to MVVM (Swift 6)
//

import SwiftUI
import Logging

struct SetEditorView: View {
    @State var viewModel: ValueViewModel
    let logger = Logger(label: "redis-set-editor")

    var body: some View {
        let vm = viewModel.setValue
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 4) {
                IconButton(icon: "plus", name: "Add", action: { vm.addNew() })

                SearchBar(placeholder: "Search element...", onCommit: { vm.search($0) })
                PageBar(viewModel: vm.page)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)

            NTableView(viewModel: vm.table)

            // footer
            HStack(alignment: .center, spacing: 0) {
                KeyObjectBar(viewModel: viewModel.keyObject)
                Spacer()
                IconButton(icon: "arrow.clockwise", name: "Refresh", action: { vm.refresh() })
                    .padding(.trailing, 8)
            }
            .frame(height: 30)
            .glassFooter()
        }
        .sheet(isPresented: Binding(get: { vm.editModalVisible }, set: { vm.editModalVisible = $0 })) {
            ModalView("Edit set element", action: { vm.submit() }) {
                VStack(alignment: .leading, spacing: 6) {
                    FormItemTextArea(placeholder: "value", value: Binding(get: { vm.editValue }, set: { vm.editValue = $0 }))
                }
            }
        }
    }
}
