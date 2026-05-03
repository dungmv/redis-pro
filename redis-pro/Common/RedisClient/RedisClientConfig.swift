//
//  RedisClientConfig.swift
//  redis-pro
//
//  Created by chengpan on 2022/3/6.
//

import Foundation
import Valkey

// MARK: - config
extension RediStackClient {
    func getConfigList(_ pattern: String = "*") async throws -> [RedisConfigItemModel] {
        logger.info("get redis config list, pattern: \(pattern)...")
        guard let client = try await getClient() else { return [] }
        
        let res = try await client.command("CONFIG", args: ["GET", pattern.isEmpty ? "*" : pattern])
        guard case .array(let arr) = res else { return [] }
        
        var configList = [RedisConfigItemModel]()
        let max: Int = arr.count / 2
        for index in (0..<max) {
            configList.append(RedisConfigItemModel(key: String(fromValkeyValue: arr[index * 2]), value: String(fromValkeyValue: arr[index * 2 + 1])))
        }
        return configList
    }
    
    func configRewrite() async throws -> Bool {
        logger.info("redis config rewrite ...")
        guard let client = try await getClient() else { return false }
        let res = try await client.command("CONFIG", args: ["REWRITE"])
        return String(fromValkeyValue: res) == "OK"
    }
    
    func getConfigOne(key: String) async throws -> String? {
        logger.info("get redis config ...")
        guard let client = try await getClient() else { return nil }
        let res = try await client.command("CONFIG", args: ["GET", key])
        if case .array(let arr) = res, arr.count >= 2 {
            return String(fromValkeyValue: arr[1])
        }
        return nil
    }
    
    func setConfig(key: String, value: String) async throws -> Bool {
        logger.info("set redis config, key: \(key), value: \(value)")
        guard let client = try await getClient() else { return false }
        let res = try await client.command("CONFIG", args: ["SET", key, value])
        return String(fromValkeyValue: res) == "OK"
    }
}
