//
//  Const.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/5/6.
//

import Foundation
import SwiftUI

extension Color {
    static func redisTypeColor(for type: String) -> Color {
        switch type.uppercased() {
        case "STRING": return Color(red: 0.20, green: 0.74, blue: 0.40) // jade green
        case "HASH":   return Color(red: 0.94, green: 0.36, blue: 0.36) // coral red
        case "LIST":   return Color(red: 0.28, green: 0.56, blue: 0.95) // sky blue
        case "SET":    return Color(red: 0.98, green: 0.62, blue: 0.22) // amber
        case "ZSET":   return Color(red: 0.62, green: 0.38, blue: 0.96) // violet
        default:       return Color.secondary
        }
    }
}

struct Const {
    static let EMPTY_STRING = ""
    
    static let LIST_VALUE_DELETE_MARK = "__REDIS_LIST_VALUE_DELETE_BY_REDIS_PRO__"
    
    static let REPO_URL = "https://github.com/cmushroom/redis-pro"
    static let RELEASE_URL = "https://github.com/cmushroom/redis-pro/releases"
    
    // 最大字符串展示长度默认值
    static let DEFAULT_STRING_MAX_LENGTH = 10240
}
