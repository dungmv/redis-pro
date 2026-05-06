//
//  PuppyLogger.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/6/17.
//  Migrated from Puppy to swift-log native handlers.
//

import Foundation
import Logging

// MARK: - Shared Log Formatting

/// Helper to format log messages consistently across handlers.
enum LogFormatter {
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    static func format(
        level: Logger.Level,
        message: Logger.Message,
        file: String,
        function: String,
        line: UInt
    ) -> String {
        let date = dateFormatter.string(from: Date())
        let fileName = (file as NSString).lastPathComponent
        return "\(date) [\(level.emoji) \(level)] \(fileName)#L.\(line) \(function) \(message)"
    }
}

// MARK: - Console Log Handler

/// A LogHandler that writes formatted log entries to standard output.
public struct ConsoleLogHandler: LogHandler {
    private let label: String

    public var logLevel: Logger.Level = .info
    public var metadata: Logger.Metadata = [:]

    public subscript(metadataKey key: String) -> Logger.Metadata.Value? {
        get { metadata[key] }
        set { metadata[key] = newValue }
    }

    public init(label: String) {
        self.label = label
    }

    public func log(
        level: Logger.Level,
        message: Logger.Message,
        metadata: Logger.Metadata?,
        source: String,
        file: String,
        function: String,
        line: UInt
    ) {
        let formatted = LogFormatter.format(
            level: level,
            message: message,
            file: file,
            function: function,
            line: line
        )
        print(formatted)
    }
}

// MARK: - File Log Handler

/// A LogHandler that writes formatted log entries to a file with rotation support.
public struct FileLogHandler: LogHandler {
    private let fileURL: URL
    private let maxFileSize: Int64
    private let maxArchivedFilesCount: Int
    private let label: String
    private let fileHandleWrapper: FileHandleWrapper

    public var logLevel: Logger.Level = .info
    public var metadata: Logger.Metadata = [:]

    public subscript(metadataKey key: String) -> Logger.Metadata.Value? {
        get { metadata[key] }
        set { metadata[key] = newValue }
    }

    public init(
        label: String,
        fileURL: URL,
        maxFileSize: Int64 = 10 * 1024 * 1024,
        maxArchivedFilesCount: Int = 5
    ) {
        self.label = label
        self.fileURL = fileURL
        self.maxFileSize = maxFileSize
        self.maxArchivedFilesCount = maxArchivedFilesCount

        // Ensure the directory exists
        let directory = fileURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        // Create file if it doesn't exist
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            FileManager.default.createFile(atPath: fileURL.path, contents: nil)
        }

        self.fileHandleWrapper = FileHandleWrapper()
        self.fileHandleWrapper.open(fileURL: fileURL)
    }

    public func log(
        level: Logger.Level,
        message: Logger.Message,
        metadata: Logger.Metadata?,
        source: String,
        file: String,
        function: String,
        line: UInt
    ) {
        let formatted = LogFormatter.format(
            level: level,
            message: message,
            file: file,
            function: function,
            line: line
        )

        guard let data = (formatted + "\n").data(using: .utf8) else { return }

        do {
            try fileHandleWrapper.write(data: data)
            try rotateIfNeeded()
        } catch {
            // On failure, try to reopen the file and retry once
            fileHandleWrapper.reopen(fileURL: fileURL)
            try? fileHandleWrapper.write(data: data)
        }
    }

    private func rotateIfNeeded() throws {
        let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
        let fileSize = (attributes[.size] as? Int64) ?? 0

        guard fileSize >= maxFileSize else { return }

        // Rotate files: redis-pro.log -> redis-pro.1.log, redis-pro.1.log -> redis-pro.2.log, ...
        fileHandleWrapper.close()

        for i in stride(from: maxArchivedFilesCount - 1, through: 0, by: -1) {
            let sourceURL: URL
            if i == 0 {
                sourceURL = fileURL
            } else {
                sourceURL = archivedFileURL(index: i)
            }
            let destURL = archivedFileURL(index: i + 1)

            if FileManager.default.fileExists(atPath: sourceURL.path) {
                if FileManager.default.fileExists(atPath: destURL.path) {
                    try FileManager.default.removeItem(at: destURL)
                }
                try FileManager.default.moveItem(at: sourceURL, to: destURL)
            }
        }

        // Create a new empty log file
        FileManager.default.createFile(atPath: fileURL.path, contents: nil)
        fileHandleWrapper.reopen(fileURL: fileURL)

        print("File rotated: \(fileURL.path)")
    }

    private func archivedFileURL(index: Int) -> URL {
        let ext = fileURL.pathExtension
        let name = fileURL.deletingPathExtension().lastPathComponent
        let dir = fileURL.deletingLastPathComponent()
        return dir.appendingPathComponent("\(name).\(index).\(ext)")
    }
}

// MARK: - FileHandleWrapper

/// Internal class to manage FileHandle lifecycle safely since LogHandler is a struct.
private final class FileHandleWrapper {
    private var fileHandle: FileHandle?

    func open(fileURL: URL) {
        fileHandle = try? FileHandle(forWritingTo: fileURL)
        fileHandle?.seekToEndOfFile()
    }

    func write(data: Data) throws {
        try fileHandle?.write(contentsOf: data)
    }

    func close() {
        fileHandle?.closeFile()
        fileHandle = nil
    }

    func reopen(fileURL: URL) {
        close()
        open(fileURL: fileURL)
    }

    deinit {
        close()
    }
}

// MARK: - Emoji Extension

extension Logger.Level {
    var emoji: String {
        switch self {
        case .trace: return "👣"
        case .debug: return "🐛"
        case .info: return "ℹ️"
        case .notice: return "📢"
        case .warning: return "⚠️"
        case .error: return "❌"
        case .critical: return "💥"
        }
    }
}
