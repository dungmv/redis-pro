//
//  TestView.swift
//  redis-pro
//
//  Created by chengpan on 2024/9/21.
//  Migrated to MVVM (Swift 6)
//

import SwiftUI

struct TestView: View {
    @State var viewModel: AppViewModel
    var tag: String = "defaultTag"

    var body: some View {
        Text("Window with tag: \(viewModel.isConnect),  id: \(viewModel.id)")
            .frame(width: 300, height: 200)
        Button("connect", action: { viewModel.onConnect() })
        Button("disconnect", action: { viewModel.onDisconnect() })
    }
}
