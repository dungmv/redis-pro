//
//  LoginStore.swift
//  redis-pro
//
//  Created by chengpan on 2022/5/1.
//  Migrated to MVVM (Swift 6)
//

import Logging
import Foundation
import Observation

private let logger = Logger(label: "login-store")

@MainActor
@Observable
final class LoginViewModel {
    var id: String = ""
    var name: String = ""
    var host: String = "127.0.0.1"
    var port: Int = 6379
    var database: Int = 0
    var username: String = ""
    var password: String = ""
    var connectionType: String = "tcp"

    // ssh
    var sshHost: String = ""
    var sshPort: Int = 22
    var sshUser: String = ""
    var sshPass: String = ""

    var pingR: String = ""
    var loading: Bool = false

    var height: CGFloat {
        connectionType == RedisConnectionTypeEnum.SSH.rawValue ? 500 : 380
    }

    // Callbacks replacing TCA action propagation
    var onConnect: (() -> Void)?
    var onSave: (() -> Void)?

    var redisModel: RedisModel {
        get {
            let m = RedisModel(name: name)
            m.id = id
            m.host = host
            m.port = port
            m.database = database
            m.username = username
            m.password = password
            m.connectionType = connectionType
            m.sshHost = sshHost
            m.sshPort = sshPort
            m.sshUser = sshUser
            m.sshPass = sshPass
            return m
        }
        set(n) {
            id = n.id
            name = n.name
            host = n.host
            port = n.port
            database = n.database
            username = n.username
            password = n.password
            connectionType = n.connectionType
            sshHost = n.sshHost
            sshPort = n.sshPort
            sshUser = n.sshUser
            sshPass = n.sshPass
        }
    }

    private let redisInstance: RedisInstanceModel

    init(redisInstance: RedisInstanceModel) {
        self.redisInstance = redisInstance
        logger.info("LoginViewModel init ...")
    }

    func add() {
        id = UUID().uuidString
        save()
    }

    func save() {
        onSave?()
    }

    func testConnect() {
        logger.info("test connect to redis server, name: \(name), host: \(host)")
        loading = true
        let model = redisModel
        Task {
            let r = await redisInstance.testConnect(model)
            pingR = r ? "Connect successed!" : "Connect fail! "
            loading = false
        }
    }

    func connect() {
        onConnect?()
    }
}
