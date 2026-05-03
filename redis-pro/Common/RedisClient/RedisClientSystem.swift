//
//  RedisClientSystem.swift
//  redis-pro
//
//  Created by chengpan on 2022/3/6.
//

import Foundation
import RediStack

// MARK: - system function
// system
extension RediStackClient {
    
    func selectDB(_ database: Int) async throws -> Bool {
        self.logger.info("select db: \(database)")
        self.redisModel.database = database
        
        self.connPool?.close()
        self.connPool = nil
        
        let command: RedisCommand<Void> = .select(database: database)
        let _ = try await send(command)
        return true
    }
    
    func databases() async throws -> Int {
    
        let command: RedisCommand<Int> = .databases()
        return try await send(command, 0)
    }
    
    func dbsize() async throws -> Int {
        
        let command: RedisCommand<Int> = .dbsize()
        return try await send(command, 0)
    }
    
    func flushDB() async throws -> Bool {
        let command: RedisCommand<Bool> = .flushDB()
        return try await send(command, false)
    }
    
    func clientKill(_ clientModel:ClientModel) async throws -> Bool {
        
        let command: RedisCommand<Bool> = .clientKill(clientModel.addr)
        return try await send(command, false)
    }
    
    func clientList() async throws -> [ClientModel] {
        
        let command: RedisCommand<[ClientModel]> = .clientList()
        return try await send(command, [])
    }
    
    func info() async throws -> [RedisInfoModel] {
        let command: RedisCommand<[RedisInfoModel]> = .info()
        return try await send(command, [])
    }
    
    func resetState() async throws -> Bool {
        logger.info("reset state...")
        let command: RedisCommand<Bool> = .resetState()
        return try await send(command, false)
    }
    
    func ping() async throws -> Bool {
        let command: RedisCommand<String> = .ping()
        return try await send(command) == "PONG"
    }
    
}
