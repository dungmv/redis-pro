//
//  SlowLogModel.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/7/14.
//

import Foundation

struct SlowLogModel: Identifiable, Sendable, Hashable {
    var id: String = ""
    var timestamp: Int = -1
    var execTime: String = ""
    var cmd: String = ""
    var client: String = ""
    var clientName: String = ""

    var timestampFormat: String {
        timestamp == -1 ? MTheme.NULL_STRING : DateHelper.formatDateTime(timestamp: self.timestamp)
    }

    init() {}

    init(id: String?, timestamp: Int?, execTime: String?, cmd: String?, client: String?, clientName: String?) {
        self.id = id ?? MTheme.NULL_STRING
        self.timestamp = timestamp ?? -1
        self.execTime = execTime ?? MTheme.NULL_STRING
        self.cmd = cmd ?? MTheme.NULL_STRING
        self.client = client ?? MTheme.NULL_STRING
        self.clientName = clientName ?? MTheme.NULL_STRING
    }
}
