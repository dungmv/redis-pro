//
//  RedisModel.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/1/29.
//

import Foundation
import SwiftUI

struct RedisModel: Identifiable, Sendable, Hashable {
    var id: String = UUID().uuidString
    var name: String = "New Favorite"
    var host: String = "127.0.0.1"
    var port: Int = 6379
    var database: Int = 0
    var username: String = ""
    var password: String = ""
    var isFavorite: Bool = false
    var ping: Bool = false
    var connectionType: String = "tcp"
    
    // ssh
    var sshHost: String = ""
    var sshPort: Int = 22
    var sshUser: String = ""
    var sshPass: String = ""
    
    var image: Image = Image("icon-redis")
    
    var dictionary: [String: Any] {
        return ["id": id,
                "name": name,
                "host": host,
                "port": port,
                "database": database,
                "username": username,
                "password": password,
                "connectionType": connectionType,
                "sshHost": sshHost,
                "sshPort": sshPort,
                "sshUser": sshUser,
                "sshPass": sshPass,
        ]
    }
    
    // MARK: - Initializers
    
    init() {}
    
    init(name: String) {
        self.init()
        self.name = name
    }
    
    init(password: String) {
        self.init()
        self.password = password
    }
    
    init(host: String = "localhost", port: Int = 6379, username: String? = nil, password: String? = nil) {
        self.init()
        self.host = host
        self.port = port
        self.username = username ?? ""
        self.password = password ?? ""
    }
    
    init(dictionary: [String: Any]) {
        self.init()
        
        self.id = dictionary["id"] as! String
        self.name = dictionary["name"] as! String
        self.host = dictionary["host"] as! String
        self.port = dictionary["port"] as! Int
        self.database = dictionary["database"] as! Int
        self.username = (dictionary["username"] ?? "") as! String
        self.password = dictionary["password"] as! String
        // ssh
        let connectionType: String = dictionary["connectionType"] as? String ?? RedisConnectionTypeEnum.TCP.rawValue
        self.connectionType = connectionType
        
        if connectionType == RedisConnectionTypeEnum.SSH.rawValue {
            self.sshHost = dictionary["sshHost"] as? String ?? ""
            self.sshPort = dictionary["sshPort"] as? Int ?? 22
            self.sshUser = dictionary["sshUser"] as? String ?? ""
            self.sshPass = dictionary["sshPass"] as? String ?? ""
        }
    }
    
    // MARK: - Equatable
    
    static func == (lhs: RedisModel, rhs: RedisModel) -> Bool {
        return lhs.id == rhs.id
    }
    
    // MARK: - Hashable
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
        hasher.combine(host)
        hasher.combine(port)
        hasher.combine(database)
        hasher.combine(username)
        hasher.combine(password)
        hasher.combine(isFavorite)
        hasher.combine(ping)
        hasher.combine(connectionType)
        hasher.combine(sshHost)
        hasher.combine(sshPort)
        hasher.combine(sshUser)
        hasher.combine(sshPass)
        // image excluded from hash
    }
}
