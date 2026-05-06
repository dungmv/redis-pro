//
//  RedisKeyModel.swift
//  redis-pro
//
//  Created by chengpan on 2021/4/4.
//

import Foundation
import Cocoa

struct RedisKeyModel: Identifiable, Sendable, Hashable {
    var key: String = ""
    var type: String = RedisKeyTypeEnum.STRING.rawValue
    var ttl: Int = -1
    var isNew: Bool = false

    private var _id: String = ""
    var id: String {
        if isNew { return _id }
        return key
    }

    init() {}

    init(_ key: String, type: String) {
        self.key = key
        self.type = type
    }

    mutating func copyValue(_ redisKeyModel: RedisKeyModel) {
        self.isNew = redisKeyModel.isNew
        self.key = redisKeyModel.key
        self.type = redisKeyModel.type
    }

    mutating func initNew() {
        self.isNew = true
        self.key = generateKey()
        self._id = self.key
        self.type = RedisKeyTypeEnum.STRING.rawValue
    }

    private func generateKey() -> String {
        return "NEW_KEY_\(Date().millis)"
    }
}

extension RedisKeyModel {
    var textColor: NSColor {
        switch type {
        case RedisKeyTypeEnum.STRING.rawValue:
            return NSColor.systemBlue
        case RedisKeyTypeEnum.HASH.rawValue:
            return NSColor.systemPink
        case RedisKeyTypeEnum.LIST.rawValue:
            return NSColor.systemOrange
        case RedisKeyTypeEnum.SET.rawValue:
            return NSColor.systemGreen
        case RedisKeyTypeEnum.ZSET.rawValue:
            return NSColor.systemTeal
        default:
            return NSColor.systemBrown
        }
    }
}
