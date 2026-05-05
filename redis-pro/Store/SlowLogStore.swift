//
//  SlowLogStore.swift
//  redis-pro
//
//  Created by chengpan on 2022/6/4.
//  Migrated to MVVM (Swift 6)
//

import Logging
import Foundation
import Observation

private let logger = Logger(label: "slow-log-store")

@MainActor
@Observable
final class SlowLogViewModel {
    var slowerThan: Int = 10000
    var maxLen: Int = 128
    var size: Int = 50
    var total: Int = 0

    let table: TableViewModel

    private let redisInstance: RedisInstanceModel

    init(redisInstance: RedisInstanceModel) {
        self.redisInstance = redisInstance
        self.table = TableViewModel(
            columns: [
                .init(title: "Id", key: "id", width: 60),
                .init(title: "Timestamp", key: "timestamp", width: 120),
                .init(title: "Exec Time(us)", key: "execTime", width: 90),
                .init(title: "Client", key: "client", width: 140),
                .init(title: "Client Name", key: "clientName", width: 100),
                .init(title: "Cmd", key: "cmd", width: 100),
            ],
            datasource: []
        )
        logger.info("SlowLogViewModel init ...")
    }

    func initial() {
        logger.info("slow log initial...")
        getValue()
    }

    func refresh() {
        getValue()
    }

    func getValue() {
        let size = self.size
        Task {
            do {
                let datasource = try await redisInstance.getClient().getSlowLog(size)
                let total = try await redisInstance.getClient().slowLogLen()
                let maxLen = try await redisInstance.getClient().getConfigOne(key: "slowlog-max-len")
                let slowerThan = try await redisInstance.getClient().getConfigOne(key: "slowlog-log-slower-than")
                self.table.datasource = datasource
                self.total = total
                self.maxLen = NumberHelper.toInt(maxLen)
                self.slowerThan = NumberHelper.toInt(slowerThan)
            } catch {
                Messages.show(error)
            }
        }
    }

    func reset() {
        Task {
            do {
                let _ = try await redisInstance.getClient().slowLogReset()
                refresh()
            } catch {
                Messages.show(error)
            }
        }
    }

    func setSlowerThan() {
        let slowerThan = self.slowerThan
        Task {
            do {
                let _ = try await redisInstance.getClient().setConfig(key: "slowlog-log-slower-than", value: "\(slowerThan)")
            } catch {
                Messages.show(error)
            }
        }
    }

    func setMaxLen() {
        let maxLen = self.maxLen
        Task {
            do {
                let _ = try await redisInstance.getClient().setConfig(key: "slowlog-max-len", value: "\(maxLen)")
            } catch {
                Messages.show(error)
            }
        }
    }

    func setSize() {
        getValue()
    }
}
