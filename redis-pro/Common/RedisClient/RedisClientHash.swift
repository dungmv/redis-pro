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
    
    func hset(_ key: String, field: String, value: String) async throws -> Bool {
        logger.info("redis hash hset key:\(key), field:\(field), value:\(value)")
        guard let client = try await getClient() else { return false }
        
        // hset returns number of fields added. We map it to bool for success.
        let result = try await client.hset(key: key, field: field, value: value)
        return result >= 0
    }
    
    func hdel(_ key: String, field: String) async throws -> Int {
        logger.info("redis hash hdel key:\(key), field:\(field)")
        guard let client = try await getClient() else { return 0 }
        
        return try await client.hdel(key: key, fields: [field])
    }
    
    private func _hashCountScan(_ key: String, keywords: String?) async throws -> Int {
        if isMatchAll(keywords ?? "") {
            logger.info("keywords is match all, use hlen...")
            return try await _hlen(key)
        }
        
        var cursor: Int = 0
        var count: Int = 0
        
        while true {
            let res = try await _hscanCount(key, keywords: keywords, cursor: cursor, count: dataCountScanCount)
            logger.info("loop scan page, current cursor: \(cursor), total count: \(count)")
            cursor = res.cursor
            count = count + res.count
            
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
            let res = try await _hscan(key, keywords: keywords, cursor: cursor, count: dataScanCount)
            logger.info("hash loop scan page, current cursor: \(cursor), total count: \(entries.count)")
            cursor = res.cursor
            entries = entries + res.entries
            
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
    
    private func _hlen(_ key: String) async throws -> Int {
        guard let client = try await getClient() else { return -1 }
        return try await client.hlen(key: key)
    }
    
    private func _hscanCount(_ key: String, keywords: String?, cursor: Int, count: Int = 100) async throws -> (cursor: Int, count: Int) {
        let r = try await _hscan(key, keywords: keywords, cursor: cursor, count: count)
        return (r.cursor, r.entries.count)
    }
    
    private func _hscan(_ key: String, keywords: String?, cursor: Int, count: Int = 100) async throws -> (cursor: Int, entries: [(String, String)]) {
        guard let client = try await getClient() else { return (0, []) }
        
        let res = try await client.hscan(
            key: key,
            cursor: cursor,
            match: keywords,
            count: count
        )
        
        return (res.cursor, res.entries)
    }
    
    private func _hget(_ key: String, field: String) async throws -> String? {
        guard let client = try await getClient() else { return nil }
        let val = try await client.hget(key: key, field: field)
        return String(fromValkeyValue: val)
    }
}
