//
//  LoggerFactory.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/6/17.
//

import Foundation
import Logging

class LoggerFactory {

    init() {
        // Setup is deferred to setUp()
    }

    func setUp() {
        LoggingSystem.bootstrap { label in
            var handlers: [any LogHandler] = []

            // Console handler
            var consoleHandler = ConsoleLogHandler(label: label)
            consoleHandler.logLevel = .info
            handlers.append(consoleHandler)

            // File handler with rotation
            let fileURL = URL(fileURLWithPath: "./redis-pro.log").absoluteURL
            var fileHandler = FileLogHandler(
                label: label,
                fileURL: fileURL,
                maxFileSize: 10 * 1024 * 1024,
                maxArchivedFilesCount: 5
            )
            fileHandler.logLevel = .info
            handlers.append(fileHandler)

            return MultiplexLogHandler(handlers)
        }

        let logger = Logger(label: "com.cmushroom.redis-pro")
        logger.info("init logger complete...")
    }
}
