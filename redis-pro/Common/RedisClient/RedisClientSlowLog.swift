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
        let res: String? = try await self.send("SLOWLOG", args: ["RESET"])
        return res == "OK"
    }
    
    func slowLogLen() async throws -> Int {
        logger.info("get slow log len ...")
        let res: Int? = try await self.send("SLOWLOG", args: ["LEN"])
        return res ?? 0
    }
    
    func getSlowLog(_ size: Int) async throws -> [SlowLogModel] {
        logger.info("get slow log list ...")
        
        let res: RESPToken? = try await self.send("SLOWLOG", args: ["GET", String(size)])
        guard let tokenArray = try? res?.decode(as: RESPToken.Array.self) else { return [] }
        
        var slowLogs = [SlowLogModel]()
        for item in tokenArray {
            guard let itemTokenArray = try? item.decode(as: RESPToken.Array.self) else { continue }
            let itemArray = Swift.Array(itemTokenArray)
            guard itemArray.count >= 4 else { continue }
            
            let id = String(fromValkeyValue: itemArray[0])
            let timestamp = Int(fromValkeyValue: itemArray[1])
            let execTime = String(fromValkeyValue: itemArray[2])
            
            var cmd = ""
            if let cmdArgsTokenArray = try? itemArray[3].decode(as: RESPToken.Array.self) {
                let cmdArgs = Swift.Array(cmdArgsTokenArray)
                cmd = cmdArgs.map { String(fromValkeyValue: $0) }.joined(separator: " ")
            }
            
            let clientAddr = itemArray.count > 4 ? String(fromValkeyValue: itemArray[4]) : nil
            let clientName = itemArray.count > 5 ? String(fromValkeyValue: itemArray[5]) : nil
            
            slowLogs.append(SlowLogModel(id: id, timestamp: timestamp, execTime: execTime, cmd: cmd, client: clientAddr, clientName: clientName))
        }
        return slowLogs
    }
}
