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
        
        let client = try await getClient()
        
        if ex == -1 {
            try await client?.set(ValkeyKey(key), value: value)
        } else {
            try await client?.setex(ValkeyKey(key), seconds: ex, value: value)
        }
    }
    
    func set(_ key: String, value: String) async throws {
        try await set(key, value: value, ex: -1)
    }
    
    func get(_ key: String) async throws -> String {
        logger.info("get value, key:\(key)")
        let client = try await getClient()
        
        let val = try await client?.get(ValkeyKey(key))
        return val.map { String($0) } ?? Const.EMPTY_STRING
    }
    
    func getRange(_ key: String, start: Int = 0, end: Int) async throws -> String {
        logger.info("get value range, key:\(key), start:\(start), end:\(end)")
        let client = try await getClient()
        
        let val = try await client?.getrange(ValkeyKey(key), start: start, end: end)
        return val.map { String($0) } ?? Const.EMPTY_STRING
    }
    
    func strLen(_ key: String) async throws -> Int {
        logger.info("get value length, key:\(key)")
        let client = try await getClient()
        
        return try await client?.strlen(ValkeyKey(key)) ?? 0
    }
    
    func del(_ key: String) async throws -> Int {
        return try await del([key])
    }
    
    func del(_ keys: [String]) async throws -> Int {
        self.logger.info("delete keys \(keys)")
        guard !keys.isEmpty else { return 0 }
        let client = try await getClient()
        
        return try await client?.del(keys: keys.map { ValkeyKey($0) }) ?? 0
    }
    
    func expire(_ key: String, seconds: Int = -1) async throws -> Bool {
        logger.info("set key expire key:\(key), seconds:\(seconds)")
        let client = try await getClient()
        
        if seconds < 0 {
            return try await client?.persist(ValkeyKey(key)) == 1
        } else {
            return try await client?.expire(ValkeyKey(key), seconds: seconds) == 1
        }
    }
    
    func exist(_ key: String) async throws -> Bool {
        logger.info("get key exist: \(key)")
        let client = try await getClient()
        
        return (try await client?.exists(keys: [ValkeyKey(key)]) ?? 0) > 0
    }
    
    func ttl(_ key: String) async throws -> Int {
        logger.info("get ttl key: \(key)")
        let client = try await getClient()
        
        return try await client?.ttl(ValkeyKey(key)) ?? -2
    }
    
    func objectEncoding(_ key: String) async throws -> String {
        logger.info("get object encoding, key: \(key)")
        let res: String? = try await self.send("OBJECT", args: ["ENCODING", ValkeyKey(key)])
        return res ?? ""
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
        let client = try await getClient()
        let type = try await client?.type(ValkeyKey(key))
        return type?.description ?? RedisKeyTypeEnum.NONE.rawValue
    }
    
    func rename(_ oldKey: String, newKey: String) async throws -> Bool {
        logger.info("rename key, old key:\(oldKey), new key: \(newKey)")
        let client = try await getClient()
        
        let r = try await client?.renamenx(ValkeyKey(oldKey), newkey: ValkeyKey(newKey)) == 1
        if !r {
            Task { @MainActor in Messages.show("rename key error, new key: \(newKey) already exists.") }
        }
        
        return r
    }
}
