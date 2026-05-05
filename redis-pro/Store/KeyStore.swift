//
//  KeyStore.swift
//  redis-pro
//
//  Created by chengpanwang on 2022/5/6.
//  Migrated to MVVM (Swift 6)
//

import Logging
import Foundation
import Observation

private let logger = Logger(label: "key-store")

@MainActor
@Observable
final class KeyViewModel {
    var type: String = RedisKeyTypeEnum.STRING.rawValue
    var key: String = ""
    var ttl: Int = -1
    var isNew: Bool = false

    var redisKeyModel: RedisKeyModel {
        get {
            let r = RedisKeyModel()
            r.type = type
            r.key = key
            r.isNew = isNew
            return r
        }
        set(n) {
            type = n.type
            key = n.key
            isNew = n.isNew
        }
    }

    private let redisInstance: RedisInstanceModel

    init(redisInstance: RedisInstanceModel) {
        self.redisInstance = redisInstance
        logger.info("KeyViewModel init ...")
    }

    func refresh() {
        Task { await getTtl() }
    }

    func setKey(_ key: String) {
        self.key = key
    }

    func getTtl() async {
        if isNew {
            ttl = -1
            return
        }
        let key = self.key
        do {
            let r = try await redisInstance.getClient().ttl(key)
            ttl = r
        } catch {
            logger.error("getTtl error: \(error)")
        }
    }

    func saveTtl() async {
        if isNew { return }
        logger.info("update redis key ttl: \(redisKeyModel)")
        let key = self.key
        let ttl = self.ttl
        do {
            let _ = try await redisInstance.getClient().expire(key, seconds: ttl)
        } catch {
            logger.error("saveTtl error: \(error)")
        }
    }

    func submit() {
        Task { await saveTtl() }
    }

    func setType(_ type: String) {
        self.type = type
    }
}
