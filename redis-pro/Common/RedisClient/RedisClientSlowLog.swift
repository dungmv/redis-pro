//
//  RedisClientSlowLog.swift
//  redis-pro
//
//  Created by chengpan on 2022/3/6.
//

import Foundation
import Valkey

// MARK: - slow log
extension RediStackClient {
    func slowLogReset() async throws -> Bool {
        logger.info("slow log reset ...")
        guard let client = try await getClient() else { return false }
        let res = try await client.command("SLOWLOG", args: ["RESET"])
        return String(fromValkeyValue: res) == "OK"
    }
    
    func slowLogLen() async throws -> Int {
        logger.info("get slow log len ...")
        guard let client = try await getClient() else { return 0 }
        let res = try await client.command("SLOWLOG", args: ["LEN"])
        return Int(fromValkeyValue: res) ?? 0
    }
    
    func getSlowLog(_ size: Int) async throws -> [SlowLogModel] {
        logger.info("get slow log list ...")
        guard let client = try await getClient() else { return [] }
        
        let res = try await client.command("SLOWLOG", args: ["GET", String(size)])
        guard case .array(let logs) = res else { return [] }
        
        var slowLogs = [SlowLogModel]()
        for item in logs {
            guard case .array(let itemArray) = item, itemArray.count >= 4 else { continue }
            
            let id = String(fromValkeyValue: itemArray[0])
            let timestamp = Int(fromValkeyValue: itemArray[1])
            let execTime = String(fromValkeyValue: itemArray[2])
            
            var cmd = ""
            if case .array(let cmdArgs) = itemArray[3] {
                cmd = cmdArgs.map { String(fromValkeyValue: $0) ?? "" }.joined(separator: " ")
            }
            
            let clientAddr = itemArray.count > 4 ? String(fromValkeyValue: itemArray[4]) : nil
            let clientName = itemArray.count > 5 ? String(fromValkeyValue: itemArray[5]) : nil
            
            slowLogs.append(SlowLogModel(id: id, timestamp: timestamp, execTime: execTime, cmd: cmd, client: clientAddr, clientName: clientName))
        }
        return slowLogs
    }
}
