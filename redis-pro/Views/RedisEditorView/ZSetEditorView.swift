//
//  ZSetEditorView.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/5/7.
//  Migrated to MVVM (Swift 6)
//

import SwiftUI
import Logging

struct ZSetEditorView: View {
    @State var viewModel: ValueViewModel
    let logger = Logger(label: "redis-zset-editor")

    var body: some View {
        let vm = viewModel.zsetValue
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 4) {
                IconButton(icon: "plus", name: "Add", action: { vm.addNew() })
                IconButton(icon: "trash", name: "Delete", disabled: vm.table.selectIndex < 0, action: { vm.deleteConfirm(vm.table.selectIndex) })

                SearchBar(placeholder: "Search element...", onCommit: { vm.search($0) })
                PageBar(viewModel: vm.page)
            }
            .padding(EdgeInsets(top: MTheme.V_SPACING, leading: 0, bottom: MTheme.V_SPACING, trailing: 0))

            NTableView(viewModel: vm.table)

            // footer
            HStack(alignment: .center, spacing: 4) {
                KeyObjectBar(viewModel: viewModel.keyObject)
                Spacer()
                IconButton(icon: "arrow.clockwise", name: "Refresh", action: { vm.refresh() })
            }
            .padding(EdgeInsets(top: MTheme.V_SPACING, leading: 0, bottom: 0, trailing: 0))
        }
        .sheet(isPresented: Binding(get: { vm.editModalVisible }, set: { vm.editModalVisible = $0 })) {
            ModalView("Edit zset element", action: { vm.submit() }) {
                VStack(alignment: .leading, spacing: MTheme.H_SPACING) {
                    FormItemDouble(
                        label: "Score", placeholder: "score",
                        value: Binding(get: { vm.editScore }, set: { vm.editScore = $0 })
                    )
                    FormItemTextArea(
                        label: "Value", placeholder: "value",
                        value: Binding(get: { vm.editValue }, set: { vm.editValue = $0 })
                    )
                }
            }
        }
    }
}
