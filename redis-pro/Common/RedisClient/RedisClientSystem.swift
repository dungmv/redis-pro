//
//  RedisClientSystem.swift
//  redis-pro
//
//  Created by chengpan on 2022/3/6.
//

import Foundation
import Valkey

// MARK: - system function
extension RediStackClient {
    
    func selectDB(_ database: Int) async throws -> Bool {
        self.logger.info("select db: \(database)")
        self.redisModel.database = database
        
        // In Valkey, it's better to re-initialize the client with the new DB
        // to ensure the connection pool is correctly pointed to the new DB.
        self.close()
        _ = try await getClient()
        return true
    }
    
    func databases() async throws -> Int {
        let client = try await getClient()
        
        // CONFIG GET returns RESPToken.Map
        let res = try await client?.configGet(parameters: ["databases"])
        if let databasesToken = res?["databases"] {
             return Int(fromValkeyValue: databasesToken) ?? 16
        }
        return 16 // Default
    }
    
    func dbsize() async throws -> Int {
        let client = try await getClient()
        return try await client?.dbsize() ?? 0
    }
    
    func flushDB() async throws -> Bool {
        let client = try await getClient()
        try await client?.flushdb()
        return true
    }
    
    func clientKill(_ clientModel: ClientModel) async throws -> Bool {
        let res: String? = try await self.send("CLIENT", args: ["KILL", clientModel.addr])
        return res == "OK"
    }
    
    func clientList() async throws -> [ClientModel] {
        let res: String? = try await self.send("CLIENT", args: ["LIST"])
        let listStr = res ?? ""
        return ClientModel.parse(listStr)
    }
    
    func info() async throws -> [RedisInfoModel] {
        let client = try await getClient()
        let res = try await client?.info() ?? ""
        return RedisInfoModel.parse(res)
    }
    
    func resetState() async throws -> Bool {
        logger.info("reset state...")
        // Valkey doesn't have a direct 'resetState' but we can re-init
        self.close()
        _ = try await getClient()
        return true
    }
    
    func ping() async throws -> Bool {
        let client = try await getClient()
        let res = try await client?.ping()
        // ping() returns PING.Response which is String or RESPBulkString
        return res == "PONG"
    }
}
