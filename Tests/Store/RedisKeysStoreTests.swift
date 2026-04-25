//
//  RedisKeysStoreTest.swift
//  Tests
//
//  Created by chengpan on 2024/1/1.
//

@testable import redis_pro
import Foundation
import XCTest
import ComposableArchitecture

@MainActor
class RedisKeysStoreTests: StoreBaseTests {
    func testSearchResetsPagingAndSelection() async {
        var state = RedisKeysStore.State()
        state.tableState = TableStore.State(
            columns: [.init(type: .KEY_TYPE, title: "Type", key: "type", width: 40),
                      .init(title: "Key", key: "key", width: 50)],
            datasource: [RedisKeyModel("existing-key", type: RedisKeyTypeEnum.STRING.rawValue)],
            contextMenus: [.COPY, .RENAME, .DELETE],
            selectIndex: 0,
            multiSelect: true
        )
        state.pageState.current = 3
        state.pageState.total = 42
        state.pageState.keywords = "old-pattern"

        let store = TestStore(initialState: state) {
            RedisKeysStore()
        } withDependencies: {
            $0.redisInstance = redisInstance
        }
        store.exhaustivity = Exhaustivity.off(showSkippedAssertions: false)
        
        await store.send(RedisKeysStore.Action.search("__keys_del_str_*")) {
            $0.pageState.current = 1
            $0.pageState.total = 0
            $0.pageState.keywords = "__keys_del_str_*"
            $0.tableState.datasource = []
            $0.tableState.selectIndex = -1
        }
    }
}
