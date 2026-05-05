//
//  RedisValueEditView.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/4/7.
//  Migrated to MVVM (Swift 6)
//

import SwiftUI
import Logging

struct RedisValueEditView: View {

    @State var viewModel: ValueViewModel
    let logger = Logger(label: "redis-value-edit-view")

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if viewModel.key.type == RedisKeyTypeEnum.STRING.rawValue {
                StringEditorView(viewModel: viewModel)
            } else if viewModel.key.type == RedisKeyTypeEnum.HASH.rawValue {
                HashEditorView(viewModel: viewModel)
            } else if viewModel.key.type == RedisKeyTypeEnum.LIST.rawValue {
                ListEditorView(viewModel: viewModel)
            } else if viewModel.key.type == RedisKeyTypeEnum.SET.rawValue {
                SetEditorView(viewModel: viewModel)
            } else if viewModel.key.type == RedisKeyTypeEnum.ZSET.rawValue {
                ZSetEditorView(viewModel: viewModel)
            } else {
                EmptyView()
            }
        }
    }
}
