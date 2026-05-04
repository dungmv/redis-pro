//
//  RedisClientSSH.swift
//  redis-pro
//
//  Created by chengpan on 2022/8/6.
//

import Foundation
import Valkey
import NIO
import NIOSSH
import Logging

// MARK: - ssh
extension RediStackClient {
    
    func initSSHClient() async throws -> ValkeyClient {
        let bindHost = "127.0.0.1"
        
        let sshTunnel = SSHTunnel(sshHost: self.redisModel.sshHost, sshPort: self.redisModel.sshPort, user: self.redisModel.sshUser, pass: self.redisModel.sshPass, targetHost: self.redisModel.host, targetPort: self.redisModel.port)
        let localChannel = try await sshTunnel.openSSHTunnel()
        
        let localBindPort: Int = localChannel.localAddress?.port ?? 0
        self.logger.info("init forwarding server success, local port: \(localBindPort)")
        self.sshLocalChannel = localChannel
        
        let auth = (redisModel.password.isEmpty && redisModel.username.isEmpty) ? nil : ValkeyClientConfiguration.Authentication(username: redisModel.username, password: redisModel.password)
        let config = ValkeyClientConfiguration(
            authentication: auth,
            databaseNumber: redisModel.database
        )
        
        let client = ValkeyClient(.hostname(bindHost, port: localBindPort), configuration: config, logger: self.logger)
        
        // Start background task
        self.backgroundTask?.cancel()
        self.backgroundTask = Task {
            await client.run()
        }
        
        self.valkeyClient = client
        return client
    }
    
    // Close SSH tunnel
    func closeSSH() {
        self.sshLocalChannel?.close(mode: .all).whenComplete { _ in
            self.logger.info("SSH local channel closed")
        }
        self.sshChannel?.close(mode: .all).whenComplete { _ in
            self.logger.info("SSH channel closed")
        }
    }
}
