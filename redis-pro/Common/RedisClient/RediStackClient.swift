//
//  RediStackClient.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/4/13.
//

import Foundation
import NIO
import Valkey
import Logging
import NIOSSH
import ComposableArchitecture
import Cocoa

class RediStackClient {
    let logger = Logger(label: "redis-client")
    var redisModel: RedisModel
    var appContextStore: StoreOf<AppContextStore>? = nil
    
    // Valkey Client
    var valkeyClient: ValkeyClient?
    private var backgroundTask: Task<Void, Never>?
    
    // ssh
    var sshChannel: Channel?
    var sshLocalChannel: Channel?
    var sshServer: PortForwardingServer?
    
    // 递归查询每页大小
    let dataScanCount: Int = 2000
    var dataCountScanCount: Int = 2000
    var recursionSize: Int = 2000
    var recursionCountSize: Int = 5000
    
    private var observers = [NSObjectProtocol]()
    private var networkMonitor = NetworkMonitor()
    
    init(_ redisModel: RedisModel) {
        self.logger.info("init redis client, param: \(redisModel)")
        self.redisModel = redisModel
       
        // 监听app退出
        observers.append(
            NotificationCenter.default.addObserver(forName: NSApplication.willTerminateNotification, object: nil, queue: .main) { [self] _ in
                logger.info("redis pro will exit...")
                shutdown()
            }
        )
    }
    
    deinit {
        observers.forEach(NotificationCenter.default.removeObserver)
        networkMonitor.stopMonitoring()
        backgroundTask?.cancel()
    }
    
    func loading(_ bool: Bool) {
        DispatchQueue.main.async {
            self.appContextStore?.send(bool ? .show : .hide)
        }
    }
    
    func begin() {
        loading(true)
    }
    
    func complete() {
        loading(false)
    }
    
    func handleError(_ error: Error) {
        logger.info("system error \(error)")
        loading(false)
        Task { @MainActor in Messages.show(error) }
    }
    
    func assertExist(_ key: String) async throws {
        let exist = try await exist(key)
        if !exist {
            throw BizError("key: \(key) is not exist!")
        }
    }
    
    // MARK: - Core Send Method
    // This is a bridge for the old _send method. ValkeyClient handles connection pooling internally.
    func _send<R>(_ command: @escaping (ValkeyClient) async throws -> R) async throws -> R {
        guard let client = try await getClient() else {
            throw BizError("Valkey client not initialized")
        }
        return try await command(client)
    }
    
    // MARK: - Client Management
    func getClient() async throws -> ValkeyClient? {
        if let client = valkeyClient {
            return client
        }
        return try await initClient()
    }
    
    private func initClient() async throws -> ValkeyClient {
        if self.redisModel.connectionType == RedisConnectionTypeEnum.SSH.rawValue {
            return try await initSSHClient()
        } else {
            return try await initDirectClient()
        }
    }
    
    func initDirectClient() async throws -> ValkeyClient {
        let config = ValkeyClientConfiguration(
            endpoint: .hostname(redisModel.host, port: redisModel.port),
            username: redisModel.username.isEmpty ? nil : redisModel.username,
            password: redisModel.password.isEmpty ? nil : redisModel.password,
            database: redisModel.database,
            logger: self.logger
        )
        
        let client = ValkeyClient(configuration: config)
        
        // Start background task for the client
        self.backgroundTask?.cancel()
        self.backgroundTask = Task {
            do {
                try await client.run()
            } catch {
                self.logger.error("Valkey client background task error: \(error)")
            }
        }
        
        self.valkeyClient = client
        return client
    }

    // MARK: - Helper for legacy extensions
    // RediStack used RedisCommand objects. Valkey uses direct method calls.
    // We'll update the extensions to use direct calls, but this helper might be useful during transition.
    func send<R>(_ command: String, _ args: [ValkeyValue] = []) async throws -> R? where R: ValkeyValueConvertible {
        begin()
        defer { complete() }
        
        let client = try await getClient()
        let result = try await client?.command(command, args: args)
        return R(fromValkeyValue: result ?? .null)
    }

    // MARK: - Lifecycle
    func close() {
        self.valkeyClient = nil
        self.backgroundTask?.cancel()
        self.backgroundTask = nil
        self.logger.info("redis client- connection closed")
        self.closeSSH()
    }
    
    func shutdown() {
        close()
    }
}
