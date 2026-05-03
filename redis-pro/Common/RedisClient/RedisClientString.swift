//
//  RedisClientString.swift
//  redis-pro
//
//  Created by chengpan on 2022/8/21.
//

import Foundation
import Valkey

// MARK: - string operator
extension RediStackClient {

    /**
     set value expire(seconds)
     */
    func set(_ key: String, value: String, ex: Int = -1) async throws {
        logger.info("set value, key:\(key), value:\(value), ex:\(ex)")
        
        guard let client = try await getClient() else { return }
        
        if ex == -1 {
            try await client.set(key: key, value: value)
        } else {
            try await client.setex(key: key, seconds: ex, value: value)
        }
    }
    
    func set(_ key: String, value: String) async throws {
        try await set(key, value: value, ex: -1)
    }
    
    func get(_ key: String) async throws -> String {
        logger.info("get value, key:\(key)")
        guard let client = try await getClient() else { return Const.EMPTY_STRING }
        
        let val = try await client.get(key: key)
        return String(fromValkeyValue: val) ?? Const.EMPTY_STRING
    }
    
    func getRange(_ key: String, start: Int = 0, end: Int) async throws -> String {
        logger.info("get value range, key:\(key), start:\(start), end:\(end)")
        guard let client = try await getClient() else { return Const.EMPTY_STRING }
        
        let val = try await client.getrange(key: key, start: start, end: end)
        return String(fromValkeyValue: val) ?? Const.EMPTY_STRING
    }
    
    func strLen(_ key: String) async throws -> Int {
        logger.info("get value length, key:\(key)")
        guard let client = try await getClient() else { return 0 }
        
        return try await client.strlen(key: key)
    }
    
    func del(_ key: String) async throws -> Int {
        return try await del([key])
    }
    
    func del(_ keys: [String]) async throws -> Int {
        self.logger.info("delete keys \(keys)")
        guard !keys.isEmpty else { return 0 }
        guard let client = try await getClient() else { return 0 }
        
        return try await client.del(keys: keys)
    }
    
    func expire(_ key: String, seconds: Int = -1) async throws -> Bool {
        logger.info("set key expire key:\(key), seconds:\(seconds)")
        guard let client = try await getClient() else { return false }
        
        if seconds < 0 {
            return try await client.persist(key: key)
        } else {
            return try await client.expire(key: key, seconds: seconds)
        }
    }
    
    func exist(_ key: String) async throws -> Bool {
        logger.info("get key exist: \(key)")
        guard let client = try await getClient() else { return false }
        
        return try await client.exists(keys: [key]) > 0
    }
    
    func ttl(_ key: String) async throws -> Int {
        logger.info("get ttl key: \(key)")
        guard let client = try await getClient() else { return -2 }
        
        return try await client.ttl(key: key)
    }
    
    func objectEncoding(_ key: String) async throws -> String {
        logger.info("get object encoding, key: \(key)")
        guard let client = try await getClient() else { return "" }
        
        // Valkey might not have a direct helper for OBJECT ENCODING, use generic command
        let res = try await client.command("OBJECT", args: ["ENCODING", key])
        return String(fromValkeyValue: res) ?? ""
    }
    
    func getTypes(_ keys: [String]) async throws -> [String: String] {
        return try await withThrowingTaskGroup(of: (String, String).self) { group in
            var typeDict = [String: String]()
            
            for key in keys {
                group.addTask {
                    let type = try await self.type(key)
                    return (key, type)
                }
            }
            
            for try await type in group {
                typeDict[type.0] = type.1
            }
            
            return typeDict
        }
    }
    
    private func type(_ key: String) async throws -> String {
        guard let client = try await getClient() else { return RedisKeyTypeEnum.NONE.rawValue }
        let type = try await client.type(key: key)
        return type.description
    }
    
    func rename(_ oldKey: String, newKey: String) async throws -> Bool {
        logger.info("rename key, old key:\(oldKey), new key: \(newKey)")
        guard let client = try await getClient() else { return false }
        
        let r = try await client.renamenx(key: oldKey, newKey: newKey)
        if !r {
            Task { @MainActor in Messages.show("rename key error, new key: \(newKey) already exists.") }
        }
        
        return r
    }
}
