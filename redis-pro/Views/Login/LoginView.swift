//
//  Login.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/1/25.
//

import SwiftUI
import NIO
import Valkey
import Logging
import ComposableArchitecture


struct LoginView: View {
    private static let logger = Logger(label: "login-view")
    
    var store: StoreOf<AppStore>
    
    init(store: StoreOf<AppStore>) {
        Self.logger.info("login view init...")
        self.store = store
    }
    
    var body: some View {
        RedisListView(store: store.scope(state: \.favoriteState, action: \.favoriteAction))
    }
}
