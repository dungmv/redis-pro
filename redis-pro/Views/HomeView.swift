//
//  HomeView.swift
//  redis-pro
//
//  Created by chengpan on 2021/4/4.
//  Migrated to MVVM (Swift 6)
//

import SwiftUI
import Logging

struct HomeView: View {
    private static let logger = Logger(label: "home-view")
    @State var viewModel: AppViewModel

    var body: some View {
        RedisKeysListView(viewModel: viewModel.redisKeys)
            .onAppear {
                Self.logger.info("redis pro home view init complete")
                viewModel.initial()
            }
            .onDisappear {
                Self.logger.info("redis pro home view destroy...")
                viewModel.onClose()
            }
            // 设置window标题
            .navigationTitle(viewModel.title)
    }
}
