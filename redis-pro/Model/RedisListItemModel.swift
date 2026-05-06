//
//  RedisListItemModel.swift
//  redis-pro
//
//  Created by chengpan on 2022/5/22.
//

import Foundation

struct RedisListItemModel: Identifiable, Sendable, Hashable {
    var id: Int { index }
    var index: Int = 0
    var value: String = ""

    init() {}

    init(_ index: Int, _ value: String) {
        self.index = index
        self.value = value
    }
}
