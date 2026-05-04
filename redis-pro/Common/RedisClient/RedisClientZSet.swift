//
//  RedisClientZSet.swift
//  redis-pro
//
//  Created by chengpan on 2022/3/6.
//

import Foundation
import Valkey

// MARK: - zset function
extension RedisClient {
    
    func pageZSet(_ key: String, page: Page) async throws -> [RedisZSetItemModel] {
        logger.info("redis zset page, key: \(key), page: \(page)")
        begin()
        defer { complete() }
        
        do {
            try await assertExist(key)
            let isScan = isScan(page.keywords)
            var r: [(String, String)] = []
            
            if isMatchAll(page.keywords) {
                r = try await _zrange(key, page: page)
                page.total = try await _zcard(key)
            }
            else if isScan {
                let match = page.keywords.isEmpty ? nil : page.keywords
                let pageData = try await zsetPageScan(key, page: page)
                r = r + pageData
                
                let total = try await zsetCountScan(key, keywords: match)
                page.total = total
            } else {
                let score = try await _zscore(key, ele: page.keywords)
                if let score = score {
                    r = [(page.keywords, "\(score)")]
                    page.total = 1
                }
            }
            return r.map { RedisZSetItemModel(value: $0.0, score: $0.1) }
        } catch {
            handleError(error)
        }
        return []
    }
    
    private func zsetCountScan(_ key: String, keywords: String?) async throws -> Int {
        if isMatchAll(keywords ?? "") {
            logger.info("keywords is match all, use zcard...")
            return try await _zcard(key)
        }
        
        var cursor: Int = 0
        var count: Int = 0
        
        while true {
            let res = try await zscan(key, keywords: keywords, cursor: cursor, count: dataCountScanCount)
            logger.info("set loop scan count, current cursor: \(cursor), total count: \(count)")
            cursor = res.cursor
            count = count + res.elements.count
            
            if cursor == 0 {
                break
            }
        }
        return count
    }
    
    private func zsetPageScan(_ key: String, page: Page) async throws -> [(String, String)] {
        let keywords = page.keywords.isEmpty ? nil : page.keywords
        var end: Int = page.end
        var cursor: Int = 0
        var elements: [(String, Double)] = []
        
        while true {
            let res = try await zscan(key, keywords: keywords, cursor: cursor, count: dataScanCount)
            logger.info("set loop scan page, current cursor: \(cursor), total count: \(elements.count)")
            cursor = res.cursor
            elements = elements + res.elements
            
            if cursor == 0 || elements.count >= end {
                break
            }
        }
        
        let start = page.start
        if start >= elements.count {
            return []
        }
        
        end = min(end, elements.count)
        return Array(elements[start..<end]).map { ($0.0, "\($0.1)") }
    }
    
    private func zscan(_ key: String, keywords: String?, cursor: Int, count: Int? = 1) async throws -> (cursor: Int, elements: [(String, Double)]) {
        logger.debug("redis zset scan, key: \(key) cursor: \(cursor), keywords: \(String(describing: keywords)), count:\(String(describing: count))")
        let client = try await getClient()
        
        let res = try await client?.zscan(ValkeyKey(key), cursor: cursor, pattern: keywords, count: count)
        
        var elements: [(String, Double)] = []
        if let members = try? res?.members.withScores() {
            elements = members.map { (String($0.value), $0.score) }
        }
        
        return (res?.cursor ?? 0, elements)
    }
    
    func zupdate(_ key: String, from: String, to: String, score: Double) async throws -> Bool {
        logger.info("update zset element key: \(key), from:\(from), to:\(to), score:\(score)")
        begin()
        defer { complete() }
 
        do {
            let r = try await _zrem(key, ele: from)
            try Assert.isTrue(r > 0, message: "set zset element: `\(from)` is not exist!")
            return try await _zadd(key, score: score, ele: to)
        } catch {
            handleError(error)
        }
        return false
    }
    
    func zadd(_ key: String, score: Double, ele: String) async throws -> Bool {
        begin()
        defer { complete() }
        return try await _zadd(key, score: score, ele: ele)
    }
    
    private func _zadd(_ key: String, score: Double, ele: String) async throws -> Bool {
        let client = try await getClient()
        let res = try await client?.zadd(ValkeyKey(key), data: [ZADD<String>.Data(score: score, member: ele)])
        // ZADD returns RESPToken? which can be Int or Null
        return res != nil
    }
    
    private func _zcard(_ key: String) async throws -> Int {
        let client = try await getClient()
        return try await client?.zcard(ValkeyKey(key)) ?? 0
    }
    
    func zrem(_ key: String, ele: String) async throws -> Int {
        begin()
        defer { complete() }
        do {
            return try await _zrem(key, ele: ele)
        } catch {
            handleError(error)
        }
        return 0
    }
    
    private func _zrem(_ key: String, ele: String) async throws -> Int {
        let client = try await getClient()
        return try await client?.zrem(ValkeyKey(key), members: [ele]) ?? 0
    }
    
    private func _zscore(_ key: String, ele: String) async throws -> Double? {
        let client = try await getClient()
        return try await client?.zscore(ValkeyKey(key), member: ele)
    }
    
    private func _zrange(_ key: String, page: Page) async throws -> [(String, String)] {
        let client = try await getClient()
        
        // Use index-based range for pagination when match all
        // Redis ZRANGE stop is inclusive, so we use end - 1
        let res = try await client?.zrange(
            ValkeyKey(key),
            start: "\(page.start)",
            stop: "\(page.end - 1)",
            sortby: nil, // Default is by index
            rev: false,
            limit: nil,
            withscores: true
        )
        
        var result: [(String, String)] = []
        if let tokens = res {
            // Try to parse as nested arrays (paired result)
            for token in tokens {
                if case .array(let nested) = token.value {
                    let nestedArr = Swift.Array(nested)
                    if nestedArr.count >= 2 {
                        result.append((String(fromValkeyValue: nestedArr[0]), String(fromValkeyValue: nestedArr[1])))
                    }
                }
            }
            
            // If result is empty, fallback to flat array (RESP2 behavior)
            if result.isEmpty {
                let arr = Swift.Array(tokens)
                var iterator = arr.makeIterator()
                while let memberToken = iterator.next(), let scoreToken = iterator.next() {
                    result.append((String(fromValkeyValue: memberToken), String(fromValkeyValue: scoreToken)))
                }
            }
        }
        return result
    }
}
