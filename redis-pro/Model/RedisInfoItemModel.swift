//
//  RedisInfoItemModel.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/7/19.
//

import Foundation

struct RedisInfoItemModel: Identifiable, Sendable, Hashable {
    var id: String { "\(section)_\(key)" }
    var section: String = ""
    var key: String = ""
    var value: String = ""

    var desc: String {
        let tip = NSLocalizedString("REDIS_INFO_\(section)_\(key)".uppercased(), tableName: nil, bundle: Bundle.main, value: "", comment: "")
        return tip
    }

    init() {}

    init(section: String, key: String, value: String) {
        self.section = section
        self.key = key
        self.value = value
    }
}
