//
//  RediStackClientKey.swift
//  redis-pro
//
//  Created by chengpan on 2022/8/21.
//

import Foundation
import RediStack

// MARK: - string operator
extension RediStackClient {

    /**
     set value expire(seconds)
     */
    func set(_ key:String, value:String, ex:Int = -1) async throws -> Void {
        logger.info("set value, key:\(key), value:\(value), ex:\(ex)")
        
        let command:RedisCommand<Void> = ex == -1 ? .set(RedisKey(key), to: value) : .setex(RedisKey(key), to: value, expirationInSeconds: ex)
        
        try await send(command)
    }
    
    func set(_ key:String, value:String) async throws -> Void {
        logger.info("set value, key:\(key), value:\(value)")
        
        try await set(key, value:value, ex: -1)
    }
    
    func get(_ key:String) async throws -> String {
        logger.info("get value, key:\(key)")
        
        let command:RedisCommand<RESPValue?> = .get(RedisKey(key))
        let r = try await send(command)
        return r??.description ?? Const.EMPTY_STRING
    }
    
    func getRange(_ key:String, start:Int = 0, end:Int) async throws -> String {
        logger.info("get value range, key:\(key), start:\(start), end:\(end)")
        
        let command:RedisCommand<String> = .getRange(key, start: start, end: end)
        let r = try await send(command)
        return r?.description ?? Const.EMPTY_STRING
    }
    
    func strLen(_ key:String) async throws -> Int {
        logger.info("get value length, key:\(key)")
        
        let command:RedisCommand<Int> = .strln(RedisKey(key))
        return try await send(command, 0)
    }
    
    func del(_ key:String) async throws -> Int {
        self.logger.info("delete key \(key)")
        
        let command:RedisCommand<Int> = .del([RedisKey(key)])
        return try await send(command, 0)
    }
    
    func del(_ keys:[String]) async throws -> Int {
        self.logger.info("delete key \(keys)")
        guard keys.count > 0 else {
            return 0
        }
        
        let command:RedisCommand<Int> = .del(keys.map({RedisKey($0)}))
        return try await send(command, 0)
    }
    
    func expire(_ key:String, seconds:Int = -1) async throws -> Bool {
        logger.info("set key expire key:\(key), seconds:\(seconds)")
        
        let maxSeconds:Int64 = INT64_MAX / (1000 * 1000 * 1000)
        try Assert.isTrue(seconds < maxSeconds, message: "过期时间最大值不能超过 \(maxSeconds) 秒")
        
        let command:RedisCommand<Bool> = seconds < 0 ?
            // PERSIST
            .init(keyword: "PERSIST", arguments: [.init(from: key)], mapValueToResult: {
                return $0.int == 1
            }) : .expire(RedisKey(key), after: .seconds(Int64(seconds)))
        return try await send(command, false)
    }
    
    func exist(_ key:String) async throws -> Bool {
        logger.info("get key exist: \(key)")
        let command:RedisCommand<Int> = .exists(RedisKey(key))
        return try await send(command) == 1
    }
    
    func ttl(_ key:String) async throws -> Int {
        logger.info("get ttl key: \(key)")
        let command:RedisCommand<RedisKey.Lifetime> = .ttl(RedisKey(key))
        return ttlSecond(try await _send(command, RedisKey.Lifetime.keyDoesNotExist))
    }
    
    func objectEncoding(_ key:String) async throws -> String {
        logger.info("get object encoding, key: \(key)")
        let command:RedisCommand<String> = .objectEncoding(key)
        return try await _send(command, "")
    }
    
    func getTypes(_ keys:[String]) async throws -> [String:String] {
        return try await withThrowingTaskGroup(of: (String, String).self) { group in
            var typeDict = [String:String]()
            
            // adding tasks to the group and fetching movies
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
    
    private func type(_ key:String) async throws -> String {
        let command:RedisCommand<String> = .type(key)
        return try await _send(command, RedisKeyTypeEnum.NONE.rawValue)
    }
    
    
    func rename(_ oldKey:String, newKey:String) async throws -> Bool {
        logger.info("rename key, old key:\(oldKey), new key: \(newKey)")
        
        let command:RedisCommand<Int> = .renamenx(oldKey, newKey: newKey)
        let r = try await send(command, 0)
        if r == 0 {
            Task { @MainActor in Messages.show("rename key error, new key: \(newKey) already exists.") }
        }
        
        return r > 0
    }
}
