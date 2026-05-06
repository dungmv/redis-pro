//
//  RedisConfigItemModel.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/7/21.
//

import Foundation

struct RedisConfigItemModel: Identifiable, Sendable, Hashable {
    var id: String { key }
    var key: String = ""
    var value: String = ""

    init() {}

    init(key: String?, value: String?) {
        self.key = key ?? ""
        self.value = value ?? ""
    }
}
