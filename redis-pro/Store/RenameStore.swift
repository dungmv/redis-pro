//
//  RenameStore.swift
//  redis-pro
//
//  Created by chengpan on 2022/5/14.
//  Migrated to MVVM (Swift 6)
//

import Logging
import Foundation
import Observation

private let logger = Logger(label: "rename-store")

@MainActor
@Observable
final class RenameViewModel {
    var key: String = ""
    var index: Int = -1
    var visible: Bool = false
    var newKey: String = ""

    // Callback when rename succeeds
    var onSetKey: ((Int, String) -> Void)?

    private let redisInstance: RedisInstanceModel

    init(redisInstance: RedisInstanceModel) {
        self.redisInstance = redisInstance
        logger.info("RenameViewModel init ...")
    }

    func hide() {
        visible = false
    }

    func submit() {
        let key = self.key
        let index = self.index
        let newKey = self.newKey

        Task {
            do {
                let r = try await redisInstance.getClient().rename(key, newKey: newKey)
                if r {
                    visible = false
                    onSetKey?(index, newKey)
                }
            } catch {
                Messages.show(error)
            }
        }
    }

    func setNewKey(_ value: String) {
        newKey = value
    }
}
