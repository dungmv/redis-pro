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
        timestamp == -1 ? LiquidGlass.NULL_STRING : DateHelper.formatDateTime(timestamp: self.timestamp)
    }

    init() {}

    init(id: String?, timestamp: Int?, execTime: String?, cmd: String?, client: String?, clientName: String?) {
        self.id = id ?? LiquidGlass.NULL_STRING
        self.timestamp = timestamp ?? -1
        self.execTime = execTime ?? LiquidGlass.NULL_STRING
        self.cmd = cmd ?? LiquidGlass.NULL_STRING
        self.client = client ?? LiquidGlass.NULL_STRING
        self.clientName = clientName ?? LiquidGlass.NULL_STRING
    }
}
