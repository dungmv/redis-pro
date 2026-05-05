//
//  IndexView.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/4/8.
//  Migrated to MVVM (Swift 6)
//

import SwiftUI
import Logging

struct IndexView: View {
    private static let logger = Logger(label: "index-view")

    @State var viewModel: AppViewModel

    var body: some View {
        if viewModel.isConnect {
            HomeView(viewModel: viewModel)
        } else {
            LoginView(viewModel: viewModel)
        }
    }
}
