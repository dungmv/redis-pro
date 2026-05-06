//
//  RedisHashEntryModel.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/7/16.
//

import Foundation

struct RedisHashEntryModel: Identifiable, Sendable, Hashable {
    var field: String = ""
    var value: String = ""
    var isNew: Bool = false

    var id: String { field }

    init() {}

    init(field: String, value: String?) {
        self.field = field
        self.value = value ?? ""
    }
}
