//
//  RedisZSetItemModel.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/7/16.
//

import Foundation

struct RedisZSetItemModel: Identifiable, Sendable, Hashable {
    var value: String = ""
    var score: String = ""

    var id: String { value }

    init() {}

    init(value: String, score: String) {
        self.value = value
        self.score = score
    }
}
