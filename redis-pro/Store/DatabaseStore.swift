//
//  DatabaseStore.swift
//  redis-pro
//
//  Created by chengpanwang on 2022/5/6.
//  Migrated to MVVM (Swift 6)
//

import Logging
import Foundation
import Observation

private let logger = Logger(label: "database-store")

@MainActor
@Observable
final class DatabaseViewModel {
    var database: Int = 0
    var databases: Int = 16

    // Callbacks replacing TCA action propagation
    var onDBChange: ((Int) -> Void)?
    var onSelectDBSuccess: ((Int) -> Void)?

    private let redisInstance: RedisInstanceModel

    init(redisInstance: RedisInstanceModel) {
        self.redisInstance = redisInstance
        logger.info("DatabaseViewModel init ...")
    }

    func initial() {
        logger.info("database initial...")
        database = redisInstance.redisModel.database
        Task { await getDatabases() }
    }

    func getDatabases() async {
        do {
            let r = try await redisInstance.getClient().databases()
            databases = r
        } catch {
            Messages.show(error)
        }
    }

    func selectDB(_ db: Int) {
        logger.info("selectDB: switching to database \(db)")
        database = db
        onDBChange?(db)

        Task {
            do {
                let r = try await redisInstance.getClient().selectDB(db)
                if r {
                    onSelectDBSuccess?(db)
                }
            } catch {
                logger.error("Failed to switch to database \(db): \(error)")
                Messages.show(error)
            }
        }
    }
}
