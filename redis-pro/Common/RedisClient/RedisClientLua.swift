//
//  RedisClientLua.swift
//  redis-pro
//
//  Created by chengpan on 2022/7/17.
//

import Foundation
import Valkey

// MARK: - lua script
extension RediStackClient {
    func eval(_ lua: String) async throws -> String {
        logger.info("lua script eval: \(lua)")
        guard lua.count > 3 else {
            return "lua script invalid!"
        }
        begin()
        defer { complete() }
        
        do {
            let trimmedLua = StringHelper.trim(StringHelper.removeStartIgnoreCase(lua, start: "eval"))
            if !StringHelper.startWith(trimmedLua, start: "'") && !StringHelper.startWith(trimmedLua, start: "\"") {
                throw BizError("lua script syntax error, demo: \"return {KEYS[1],KEYS[2],ARGV[1],ARGV[2]}\" 2 key1 key2 arg1 arg2")
            }
            
            let separator = trimmedLua[0]
            guard let scriptLastIndex = trimmedLua.lastIndexOf(separator) else {
                throw BizError("lua script syntax error: missing closing separator")
            }
            let start = trimmedLua.index(trimmedLua.startIndex, offsetBy: 1)
            let script = String(trimmedLua[start..<scriptLastIndex])
            
            let argStart = trimmedLua.index(scriptLastIndex, offsetBy: 1)
            let argsStr = StringHelper.trim(String(trimmedLua[argStart...]))
            let argArr = StringHelper.split(argsStr)
            
            logger.info("eval lua script, script: \(script), args: \(argArr)")
            
            guard let client = try await getClient() else { return "eval error" }
            
            // Map args to ValkeyValue
            let valkeyArgs = argArr.map { ValkeyValue.string($0) }
            
            // In EVAL command: EVAL script numkeys key [key ...] arg [arg ...]
            // The project seems to expect the user to provide the numkeys as part of the args.
            let res = try await client.command("EVAL", args: [ValkeyValue.string(script)] + valkeyArgs)
            return res.description
        } catch {
            handleError(error)
        }
        
        return "eval error"
    }
    
    func scriptKill() async throws -> String {
        logger.info("lua script kill")
        guard let client = try await getClient() else { return "script kill error" }
        
        let res = try await client.command("SCRIPT", args: ["KILL"])
        return res.description
    }
    
    func scriptFlush() async throws {
        logger.info("lua script flush")
        guard let client = try await getClient() else { return }
        _ = try await client.command("SCRIPT", args: ["FLUSH"])
    }
}
