//
//  HashEditorView.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/4/9.
//  Migrated to MVVM (Swift 6)
//

import SwiftUI
import Logging

struct HashEditorView: View {
    @State var viewModel: ValueViewModel
    private let logger = Logger(label: "redis-hash-editor")

    var body: some View {
        let vm = viewModel.hashValue
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 6) {
                IconButton(icon: "plus", name: "Add", action: { vm.addNew() })
                IconButton(icon: "trash", name: "Delete", disabled: vm.table.selectIndex < 0, action: { vm.deleteConfirm(vm.table.selectIndex) })

                SearchBar(placeholder: "Search field...", onCommit: { vm.search($0) })
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
        .onAppear {
            logger.info("redis hash editor view appear ...")
            vm.initial()
        }
        .sheet(isPresented: Binding(get: { vm.editModalVisible }, set: { vm.editModalVisible = $0 })) {
            ModalView("Edit hash entry", action: { vm.submit() }) {
                VStack(alignment: .leading, spacing: 8) {
                    FormItemText(placeholder: "Field", editable: vm.isNew, value: Binding(get: { vm.field }, set: { vm.field = $0 }))
                    FormItemTextArea(placeholder: "Value", value: Binding(get: { vm.value }, set: { vm.value = $0 }))
                }
            }
        }
    }
}
