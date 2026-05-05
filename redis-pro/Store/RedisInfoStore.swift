//
//  RedisInfoStore.swift
//  redis-pro
//
//  Created by chengpan on 2022/6/4.
//  Migrated to MVVM (Swift 6)
//

import Logging
import Foundation
import Observation

private let logger = Logger(label: "redis-info-store")

@MainActor
@Observable
final class RedisInfoViewModel {
    var section: String = "Server"
    var redisInfoModels: [RedisInfoModel] = [RedisInfoModel(section: "Server")]
    let table: TableViewModel

    private let redisInstance: RedisInstanceModel

    init(redisInstance: RedisInstanceModel) {
        self.redisInstance = redisInstance
        self.table = TableViewModel(
            columns: [
                .init(title: "Key", key: "key", width: 120),
                .init(title: "Value", key: "value", width: 100),
                .init(title: "Desc", key: "desc", width: 800)
            ],
            datasource: []
        )
        logger.info("RedisInfoViewModel init ...")
    }

    func initial() {
        logger.info("redis info initial...")
        getValue()
    }

    func refresh() {
        getValue()
    }

    func getValue() {
        Task {
            do {
                let r = try await redisInstance.getClient().info()
                setValue(r)
            } catch {
                Messages.show(error)
            }
        }
    }

    func setValue(_ redisInfos: [RedisInfoModel]) {
        let section = redisInfos.count > 0 ? redisInfos[0].section : ""
        redisInfoModels = redisInfos
        setTab(section)
    }

    func setTab(_ tab: String) {
        section = tab
        table.selectIndex = -1
        guard redisInfoModels.count > 0 else {
            table.reset()
            return
        }
        let redisInfoModel = redisInfoModels.first(where: { $0.section == tab })
        table.datasource = redisInfoModel?.infos ?? []
    }

    func resetState() {
        Task {
            do {
                let _ = try await redisInstance.getClient().resetState()
                refresh()
            } catch {
                Messages.show(error)
            }
        }
    }
}
