//
//  ListEditorView.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/4/30.
//  Migrated to MVVM (Swift 6)
//

import SwiftUI
import Logging

struct ListEditorView: View {
    @State var viewModel: ValueViewModel
    let logger = Logger(label: "redis-list-editor")

    var body: some View {
        let vm = viewModel.listValue
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 4) {
                IconButton(icon: "plus", name: "Add head", action: { vm.addNew(type: -1) })
                IconButton(icon: "plus", name: "Add tail", action: { vm.addNew(type: -2) })
                IconButton(icon: "trash", name: "Delete", disabled: vm.table.selectIndex < 0, action: { vm.deleteConfirm(vm.table.selectIndex) })

                Spacer()
                PageBar(viewModel: vm.page)
            }
            .padding(EdgeInsets(top: MTheme.V_SPACING, leading: 0, bottom: MTheme.V_SPACING, trailing: 0))

            NTableView(viewModel: vm.table)

            // footer
            HStack(alignment: .center, spacing: MTheme.H_SPACING) {
                KeyObjectBar(viewModel: viewModel.keyObject)
                Spacer()
                IconButton(icon: "arrow.clockwise", name: "Refresh", action: { vm.refresh() })
            }
            .padding(EdgeInsets(top: MTheme.V_SPACING, leading: 0, bottom: 0, trailing: 0))
        }
        .sheet(isPresented: Binding(get: { vm.editModalVisible }, set: { vm.editModalVisible = $0 })) {
            ModalView("Edit list item", action: { vm.submit() }) {
                VStack(alignment: .leading, spacing: MTheme.V_SPACING) {
                    FormItemTextArea(label: "", placeholder: "value", value: Binding(get: { vm.editValue }, set: { vm.editValue = $0 }))
                }
            }
        }
    }
}
