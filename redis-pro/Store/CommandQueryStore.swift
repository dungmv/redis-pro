//
//  CommandQueryStore.swift
//  redis-pro
//
//  Created by Antigravity on 2026-06-02.
//

import Foundation
import Observation
import Logging
import Valkey

private let logger = Logger(label: "command-query-store")

@MainActor
@Observable
final class CommandQueryViewModel {
    var queryText: String = ""
    var selectedCommand: String = ""
    var outputText: String = ""
    var isExecuting: Bool = false
    
    private let redisInstance: RedisInstanceModel
    
    init(redisInstance: RedisInstanceModel) {
        self.redisInstance = redisInstance
        self.queryText = RedisDefaults.getCommandQueryText()
    }
    
    func executeCommand(_ commandString: String) {
        let trimmed = commandString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        guard let parsed = RedisCommandParser.parse(trimmed) else {
            self.outputText += "\n> \(trimmed)\nError: Could not parse command. Make sure quotes are balanced.\n"
            return
        }
        
        isExecuting = true
        
        // Save the full editor content to defaults
        RedisDefaults.saveCommandQueryText(queryText)
        
        Task {
            do {
                let client = try await redisInstance.getClient()
                
                // execute using raw command
                let responseToken: RESPToken? = try await client.send(parsed.command, args: parsed.args)
                
                if let responseToken = responseToken {
                    let formatted = formatToken(responseToken)
                    self.outputText += "\n> \(trimmed)\n\(formatted)\n"
                } else {
                    self.outputText += "\n> \(trimmed)\n(nil)\n"
                }
            } catch {
                self.outputText += "\n> \(trimmed)\nError: \(error.localizedDescription)\n"
            }
            isExecuting = false
        }
    }
    
    func clearOutput() {
        self.outputText = ""
    }
    
    private func formatToken(_ token: RESPToken) -> String {
        switch token.value {
        case .simpleString(let buffer), .bulkString(let buffer):
            return String(buffer: buffer)
        case .number(let i):
            return String(i)
        case .double(let d):
            return String(d)
        case .boolean(let b):
            return b ? "true" : "false"
        case .null:
            return "(nil)"
        default:
            // Check for array response
            if let tokenArray = try? token.decode(as: RESPToken.Array.self) {
                let arr = Array(tokenArray)
                if arr.isEmpty {
                    return "(empty array)"
                }
                return arr.enumerated().map { index, item in
                    let formattedItem = formatToken(item)
                    let indented = formattedItem.components(separatedBy: .newlines).map { "  " + $0 }.joined(separator: "\n")
                    return "\(index + 1))\n\(indented)"
                }.joined(separator: "\n")
            }
            
            // Check for map response
            if let tokenMap = try? token.decode(as: RESPToken.Map.self) {
                let entries = Array(tokenMap)
                if entries.isEmpty {
                    return "(empty map)"
                }
                return entries.map { entry in
                    let keyStr = formatToken(entry.key)
                    let valStr = formatToken(entry.value)
                    return "\(keyStr) => \(valStr)"
                }.joined(separator: "\n")
            }
            
            return "\(token)"
        }
    }
}

struct RedisCommandParser {
    static func parse(_ commandLine: String) -> (command: String, args: [String])? {
        let trimmed = commandLine.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        
        var args: [String] = []
        var currentToken = ""
        var inDoubleQuotes = false
        var inSingleQuotes = false
        var isEscaped = false
        
        for char in trimmed {
            if isEscaped {
                currentToken.append(char)
                isEscaped = false
                continue
            }
            
            if char == "\\" {
                isEscaped = true
                continue
            }
            
            if char == "\"" && !inSingleQuotes {
                inDoubleQuotes.toggle()
                continue
            }
            
            if char == "'" && !inDoubleQuotes {
                inSingleQuotes.toggle()
                continue
            }
            
            if char.isWhitespace && !inDoubleQuotes && !inSingleQuotes {
                if !currentToken.isEmpty {
                    args.append(currentToken)
                    currentToken = ""
                }
            } else {
                currentToken.append(char)
            }
        }
        
        if !currentToken.isEmpty {
            args.append(currentToken)
        }
        
        guard !args.isEmpty else { return nil }
        let cmd = args.removeFirst()
        return (cmd, args)
    }
}
