//
//  RedisClientHash.swift
//  redis-pro
//
//  Created by chengpan on 2022/3/6.
//

import Foundation
import Valkey

// MARK: - hash function
extension RediStackClient {
    
    func pageHash(_ key: String, page: Page) async throws -> [RedisHashEntryModel] {
        logger.info("redis hash field page scan, key: \(key), page: \(page)")
        
        begin()
        defer { complete() }
        
        do {
            try await assertExist(key)
            let isScan = isScan(page.keywords)
            var r: [RedisHashEntryModel] = []
            
            if isScan {
                let match = page.keywords.isEmpty ? nil : page.keywords
                let pageData: [(String, String)] = try await _hashPageScan(key, page: page)
                r = pageData.map { RedisHashEntryModel(field: $0.0, value: $0.1) }
                
                let total = try await _hashCountScan(key, keywords: match)
                page.total = total
            } else {
                let value = try await _hget(key, field: page.keywords)
                if let value = value, !value.isEmpty {
                    r.append(RedisHashEntryModel(field: page.keywords, value: value))
                    page.total = 1
                }
            }
            return r
        } catch {
            handleError(error)
        }
        return []
    }
    
    func hset(key: String, field: String, value: String) async throws -> Int {
        let client = try await getClient()
        return try await client?.hset(ValkeyKey(key), data: [HSET<String, String>.Data(field: field, value: value)]) ?? 0
    }
    
    func hdel(key: String, fields: [String]) async throws -> Int {
        let client = try await getClient()
        return try await client?.hdel(ValkeyKey(key), fields: fields) ?? 0
    }
    
    private func _hashCountScan(_ key: String, keywords: String?) async throws -> Int {
        if isMatchAll(keywords ?? "") {
            logger.info("keywords is match all, use hlen...")
            return try await hlen(key: key)
        }
        
        var cursor: Int = 0
        var count: Int = 0
        
        while true {
            let res = try await hscan(key: key, cursor: cursor, pattern: keywords, count: dataCountScanCount)
            logger.info("loop scan page, current cursor: \(res.0), total count: \(count)")
            cursor = res.0
            count = count + res.1.count
            
            if cursor == 0 {
                break
            }
        }
        return count
    }
    
    private func _hashPageScan(_ key: String, page: Page) async throws -> [(String, String)] {
        let keywords = page.keywords.isEmpty ? nil : page.keywords
        var end: Int = page.end
        var cursor: Int = 0
        var entries: [(String, String)] = []
        
        while true {
            let res = try await hscan(key: key, cursor: cursor, pattern: keywords, count: dataScanCount)
            logger.info("hash loop scan page, current cursor: \(res.0), total count: \(entries.count)")
            cursor = res.0
            entries = entries + res.1
            
            if cursor == 0 || entries.count >= end {
                break
            }
        }
        
        let start = page.start
        if start >= entries.count {
            return []
        }
        
        end = min(end, entries.count)
        return Array(entries[start..<end])
    }
    
    private func hlen(key: String) async throws -> Int {
        let client = try await getClient()
        return try await client?.hlen(ValkeyKey(key)) ?? 0
    }
    
    private    func hscan(key: String, cursor: Int, pattern: String?, count: Int?) async throws -> (Int, [(String, String)]) {
        let client = try await getClient()
        let result = try await client?.hscan(ValkeyKey(key), cursor: cursor, pattern: pattern, count: count)
        
        guard let res = result else { return (0, []) }
        
        let elements = (try? res.members.withValues().map { (String($0.field), String($0.value)) }) ?? []
        return (res.cursor, elements)
    }
    
    private func _hget(_ key: String, field: String) async throws -> String? {
        let client = try await getClient()
        let val = try await client?.hget(ValkeyKey(key), field: field)
        return val.map { String($0) }
    }
}
