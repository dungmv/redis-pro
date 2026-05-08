//
//  KeyObjectStore.swift
//  redis-pro
//
//  Created by chengpan on 2023/7/23.
//  Migrated to MVVM (Swift 6)
//

import Logging
import Foundation
import Observation

private let logger = Logger(label: "key-object-store")

@MainActor
@Observable
final class KeyObjectViewModel {
    var key: String = ""
    var encoding: String = ""
    var memoryUsage: Int = -1
    
    var memorySize: String {
        if memoryUsage < 0 { return "–" }
        return ByteCountFormatter.string(fromByteCount: Int64(memoryUsage), countStyle: .binary)
    }

    private let redisInstance: RedisInstanceModel

    init(redisInstance: RedisInstanceModel) {
        self.redisInstance = redisInstance
        logger.info("KeyObjectViewModel init ...")
    }

    func refresh() {
        Task {
            await getEncoding()
            await getMemoryUsage()
        }
    }

    func setKey(_ key: String) {
        self.key = key
    }

    func getEncoding() async {
        let key = self.key
        do {
            let r = try await redisInstance.getClient().objectEncoding(key)
            encoding = r
        } catch {
            logger.error("getEncoding error: \(error)")
        }
    }
    
    func getMemoryUsage() async {
        let key = self.key
        do {
            let r = try await redisInstance.getClient().memoryUsage(key)
            memoryUsage = r
        } catch {
            logger.error("getMemoryUsage error: \(error)")
        }
    }
}
