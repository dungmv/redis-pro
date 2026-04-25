//
//  AppStoreTest.swift
//  Tests
//
//  Created by chengpan on 2023/8/5.
//

@testable import redis_pro
import Foundation
import XCTest
import ComposableArchitecture

@MainActor
class KeysDelStoreTests: StoreBaseTests {
    func testDeleteSuccessRemovesKeysAndClearsSelection() async {
        let first = RedisKeyModel("key-1", type: RedisKeyTypeEnum.STRING.rawValue)
        let second = RedisKeyModel("key-2", type: RedisKeyTypeEnum.STRING.rawValue)
        let third = RedisKeyModel("key-3", type: RedisKeyTypeEnum.STRING.rawValue)
        let datasource: [AnyHashable] = [first, second, third]

        var state = RedisKeysStore.State()
        state.tableState = TableStore.State(
            columns: [.init(type: .KEY_TYPE, title: "Type", key: "type", width: 40),
                      .init(title: "Key", key: "key", width: 50)],
            datasource: datasource,
            contextMenus: [.COPY, .RENAME, .DELETE],
            selectIndex: 1,
            multiSelect: true
        )
        state.redisKeyNodes = RedisKeyNode.buildTree(from: [first, second, third])
        state.selectedKeyId = second.key

        let store = TestStore(initialState: state) {
            RedisKeysStore()
        } withDependencies: {
            $0.redisInstance = redisInstance
        }
        store.exhaustivity = Exhaustivity.off(showSkippedAssertions: false)
        
        await store.send(RedisKeysStore.Action.deleteSuccess([1])) {
            $0.tableState.datasource = [first, third]
            $0.redisKeyNodes = RedisKeyNode.buildTree(from: [first, third])
            $0.tableState.selectIndex = -1
            $0.selectedKeyId = nil
        }
    }
}
