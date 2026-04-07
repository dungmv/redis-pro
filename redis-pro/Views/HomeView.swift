//
//  HomeView.swift
//  redis-pro
//
//  Created by chengpan on 2021/4/4.
//

import SwiftUI
import Logging
import ComposableArchitecture


struct HomeView: View {
    private static let logger = Logger(label: "home-view")
    var store:StoreOf<AppStore>

    var body: some View {
        RedisKeysListView(store)
            .onAppear {
                Self.logger.info("redis pro home view init complete")
                store.send(.initial)
            }
            .onDisappear {
                Self.logger.info("redis pro home view destroy...")
                store.send(.onClose)
            }
        // 设置window标题
        .navigationTitle(store.title)
    }
}
