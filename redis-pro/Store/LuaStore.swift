//
//  LuaStore.swift
//  redis-pro
//
//  Created by chengpan on 2022/7/17.
//  Migrated to MVVM (Swift 6)
//

import Logging
import Foundation
import Observation

private let logger = Logger(label: "lua-store")

@MainActor
@Observable
final class LuaViewModel {
    var lua: String = "\"return {KEYS[1],KEYS[2],ARGV[1],ARGV[2]}\" 2 key1 key2 arg1 arg2"
    var evalResult: String = ""
    var luaSHA: String = "-"

    private let redisInstance: RedisInstanceModel

    init(redisInstance: RedisInstanceModel) {
        self.redisInstance = redisInstance
        logger.info("LuaViewModel init ...")
    }

    func eval() {
        let lua = self.lua
        Task {
            do {
                let r = try await redisInstance.getClient().eval(lua)
                evalResult = r
            } catch {
                Messages.show(error)
            }
        }
    }

    func scriptKill() {
        Task {
            do {
                let _ = try await redisInstance.getClient().scriptKill()
            } catch {
                Messages.show(error)
            }
        }
    }

    func scriptFlush() {
        Task {
            do {
                let _ = try await redisInstance.getClient().scriptFlush()
            } catch {
                Messages.show(error)
            }
        }
    }

    func scriptLoad() {
        Task {
            luaSHA = ""
        }
    }
}
