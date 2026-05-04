//
//  RedisClientConn.swift
//  redis-pro
//
//  Created by chengpan on 2023/7/23.
//

import Foundation
import Valkey
import NIO

// MARK: - conn operator
extension RedisClient {
    
    /*
     * 初始化redis 连接
     */
    func initConnection() async throws -> Bool {
        begin()
        defer {
            complete()
        }
        
        do {
            let _ = try await getClient()
            return true
            
        } catch {
            handleError(error)
        }
        
        return false
    }
    
    /// test redis connection
    func testConn() async throws -> Bool {
        begin()
        defer {
            complete()
        }
        
        do {
            let client = try await initClient()
            let pong = try await client.ping()
            
            // For testing, we close the client immediately
            return String(fromValkeyValue: pong) == "PONG"
        } catch {
            Task { @MainActor in Messages.show(error) }
            return false
        }
    }
    
    func refreshConn() async {
        self.close()
        let _ = try? await self.getClient()
    }
    
    // Legacy support for getConn()
    func getConn() async throws -> ValkeyClient? {
        return try await getClient()
    }
}
