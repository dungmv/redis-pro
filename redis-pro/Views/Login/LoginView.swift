//
//  Login.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/1/25.
//  Migrated to MVVM (Swift 6)
//

import SwiftUI
import Logging

struct LoginView: View {
    private static let logger = Logger(label: "login-view")

    @State var viewModel: AppViewModel

    init(viewModel: AppViewModel) {
        Self.logger.info("login view init...")
        self.viewModel = viewModel
    }

    var body: some View {
        RedisListView(viewModel: viewModel.favorite)
    }
}
