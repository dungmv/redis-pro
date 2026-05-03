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
        guard let client = try await getClient() else { return 0 }
        
        // Usually obtained via CONFIG GET databases
        let res = try await client.command("CONFIG", args: ["GET", "databases"])
        // CONFIG GET returns an array [key, value, key, value...]
        if case .array(let arr) = res, arr.count >= 2 {
            return Int(fromValkeyValue: arr[1]) ?? 16
        }
        return 16 // Default
    }
    
    func dbsize() async throws -> Int {
        guard let client = try await getClient() else { return 0 }
        return try await client.dbsize()
    }
    
    func flushDB() async throws -> Bool {
        guard let client = try await getClient() else { return false }
        try await client.flushdb()
        return true
    }
    
    func clientKill(_ clientModel: ClientModel) async throws -> Bool {
        guard let client = try await getClient() else { return false }
        let res = try await client.command("CLIENT", args: ["KILL", clientModel.addr])
        return String(fromValkeyValue: res) == "OK"
    }
    
    func clientList() async throws -> [ClientModel] {
        guard let client = try await getClient() else { return [] }
        let res = try await client.command("CLIENT", args: ["LIST"])
        let listStr = String(fromValkeyValue: res) ?? ""
        return ClientModel.parse(listStr)
    }
    
    func info() async throws -> [RedisInfoModel] {
        guard let client = try await getClient() else { return [] }
        let res = try await client.info()
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
        guard let client = try await getClient() else { return false }
        let res = try await client.ping()
        return res == "PONG"
    }
}
