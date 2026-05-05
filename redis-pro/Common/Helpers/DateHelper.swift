//
//  DateHelper.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/7/15.
//  Fixed for Swift 6 — nonisolated global mutable state
//

import Foundation
import Logging

final class DateHelper: @unchecked Sendable {

    static let logger = Logger(label: "number-helper")

    // Fix Swift 6: nonisolated global mutable state → use nonisolated(unsafe) or a computed var
    nonisolated(unsafe) private static var dateTimeFormatter: DateFormatter = initDateTimeFormater()

    private static func initDateTimeFormater() -> DateFormatter {
        logger.info("初始化 datetime formatter...")
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(abbreviation: "GMT+8")
        dateFormatter.locale = NSLocale.current
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return dateFormatter
    }

    static func formatDateTime(timestamp: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        return dateTimeFormatter.string(from: date)
    }
}
