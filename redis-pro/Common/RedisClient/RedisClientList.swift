//
//  RedisClientList.swift
//  redis-pro
//
//  Created by chengpan on 2022/3/6.
//

import Foundation
import Valkey

// MARK: - list function
extension RediStackClient {

    func pageList(_ key: String, page: Page) async throws -> [RedisListItemModel] {
        logger.info("redis list page, key: \(key), page: \(page)")
        begin()
        defer { complete() }
        
        do {
            let start: Int = (page.current - 1) * page.size
            let r1 = try await llen(key)
            let r2 = try await _lrange(key, start: start, stop: start + page.size - 1)
            let total = r1
            page.total = total
            
            var result: [RedisListItemModel] = []
            for (index, value) in r2.enumerated() {
                result.append(RedisListItemModel(start + index, value ?? ""))
            }
     
            return result
        } catch {
            handleError(error)
        }
        return []
    }
    
    private func _lrange(_ key: String, start: Int, stop: Int) async throws -> [String?] {
        logger.debug("redis list range, key: \(key)")
        guard let client = try await getClient() else { return [] }
        
        let res = try await client.lrange(ValkeyKey(key), start: start, stop: stop)
        return res.map { String(fromValkeyValue: $0) }
    }
    
    func ldel(_ key: String, index: Int, value: String) async throws -> Int {
        logger.debug("redis list delete, key: \(key), index:\(index)")
        begin()
        defer { complete() }
        
        do {
            let existValue = try await _lindex(key, index: index)
            guard existValue == value else {
                throw BizError("list value: \(value), index: \(index) have changed, please check!")
            }
            
            try await _lset(key, index: index, value: Const.LIST_VALUE_DELETE_MARK)
            return try await _lrem(key, value: Const.LIST_VALUE_DELETE_MARK)
        } catch {
            handleError(error)
        }
        return 0
    }
    
    private func _lrem(_ key: String, value: String) async throws -> Int {
        guard let client = try await getClient() else { return 0 }
        return try await client.lrem(ValkeyKey(key), count: 0, element: value)
    }
    
    func lset(_ key: String, index: Int, value: String) async throws {
        begin()
        defer { complete() }
        try await _lset(key, index: index, value: value)
    }
    
    private func _lset(_ key: String, index: Int, value: String) async throws {
        guard let client = try await getClient() else { return }
        _ = try await client.lset(ValkeyKey(key), index: index, element: value)
    }
    
    func lpush(_ key: String, value: String) async throws -> Int {
        guard let client = try await getClient() else { return 0 }
        return try await client.lpush(ValkeyKey(key), elements: [value])
    }
    
    func rpush(_ key: String, value: String) async throws -> Int {
        guard let client = try await getClient() else { return 0 }
        return try await client.rpush(ValkeyKey(key), elements: [value])
    }
    
    private func _lindex(_ key: String, index: Int) async throws -> String? {
        guard let client = try await getClient() else { return nil }
        let val = try await client.lindex(ValkeyKey(key), index: index)
        return val.map { String($0) }
    }
    
    private func llen(_ key: String) async throws -> Int {
        logger.debug("redis list length, key: \(key)")
        guard let client = try await getClient() else { return 0 }
        return try await client.llen(ValkeyKey(key))
    }
}
