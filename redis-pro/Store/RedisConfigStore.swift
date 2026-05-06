//
//  RedisConfigStore.swift
//  redis-pro
//
//  Created by chengpan on 2022/6/4.
//  Migrated to MVVM (Swift 6)
//

import Logging
import Foundation
import Observation

private let logger = Logger(label: "redis-config-store")

@MainActor
@Observable
final class RedisConfigViewModel {
    var editModalVisible: Bool = false
    var editValue: String = ""
    var pattern: String = ""
    var editKey: String = ""
    var editIndex: Int = 0

    let table: TableViewModel<RedisConfigItemModel>

    private let redisInstance: RedisInstanceModel

    init(redisInstance: RedisInstanceModel) {
        self.redisInstance = redisInstance
        self.table = TableViewModel<RedisConfigItemModel>(
            columns: [
                .init(title: "Key", width: 200) { $0.key },
                .init(title: "Value", width: 800) { $0.value }
            ],
            datasource: [],
            contextMenus: [.EDIT]
        )
        setupTableCallbacks()
        logger.info("RedisConfigViewModel init ...")
    }

    private func setupTableCallbacks() {
        table.onContextMenu = { [weak self] title, index in
            guard let self else { return }
            if title == "Edit" { self.edit(index) }
        }
        table.onDouble = { [weak self] index in self?.edit(index) }
    }

    func initial() {
        logger.info("redis config initial...")
        getValue()
    }

    func refresh() {
        getValue()
    }

    func getValue() {
        let pattern = self.pattern
        Task {
            do {
                let r = try await redisInstance.getClient().getConfigList(pattern)
                table.datasource = r
            } catch {
                Messages.show(error)
            }
        }
    }

    func search(_ keywords: String) {
        pattern = keywords
        getValue()
    }

    func rewrite() {
        Task {
            do {
                let _ = try await redisInstance.getClient().configRewrite()
                refresh()
            } catch {
                Messages.show(error)
            }
        }
    }

    func edit(_ index: Int) {
        editIndex = index
        let item = table.datasource[index]
        editKey = item.key
        editValue = item.value
        editModalVisible = true
    }

    func submit() {
        let key = editKey
        let value = editValue
        Task {
            do {
                let _ = try await redisInstance.getClient().setConfig(key: key, value: value)
                refresh()
            } catch {
                Messages.show(error)
            }
        }
    }
}
