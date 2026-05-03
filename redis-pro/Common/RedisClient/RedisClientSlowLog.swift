//
//  RedisClientSlowLog.swift
//  redis-pro
//
//  Created by chengpan on 2022/3/6.
//

import Foundation
import RediStack

// MARK: -slow log
extension RediStackClient {
    func slowLogReset() async throws -> Bool {
        logger.info("slow log reset ...")
        let command: RedisCommand<Bool> = .slowlogReset()
        return try await send(command, false)
        
    }
    
    func slowLogLen() async throws -> Int {
        logger.info("get slow log len ...")
        let command: RedisCommand<Int> = .slowlogLen()
        return try await send(command, 0)
    }
    
    func getSlowLog(_ size:Int) async throws -> [SlowLogModel] {
        logger.info("get slow log list ...")
        let command: RedisCommand<[SlowLogModel]> = .slowlogList(size)
        return try await send(command, [])
    }
}

