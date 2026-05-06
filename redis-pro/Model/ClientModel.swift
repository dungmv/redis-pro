//
//  ClientModel.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/6/18.
//
//"id", "name", "addr", "laddr", "fd", "age", "idle", "flags", "db", "sub", "psub", "multi", "qbuf", "qbuf-free", "obl", "oll", "omem", "events", "cmd", "argv-mem", "tot-mem", "redir", "user"

import Foundation

struct ClientModel: Identifiable, Sendable, Hashable {
    var id: String = ""
    var name: String = ""
    var addr: String = ""
    var laddr: String = ""
    var fd: String = ""
    var age: String = ""
    var idle: String = ""
    var flags: String = ""
    var db: String = ""
    var sub: String = ""
    var psub: String = ""
    var multi: String = ""
    var qbuf: String = ""
    var qbuf_free: String = ""
    var obl: String = ""
    var oll: String = ""
    var omem: String = ""
    var events: String = ""
    var cmd: String = ""
    var argv_mem: String = ""
    var tot_mem: String = ""
    var redir: String = ""
    var user: String = ""

    init() {}

    init(line: String) {
        let kvStrArray = line.components(separatedBy: .whitespaces)
        var item: [String: String] = [:]
        kvStrArray.forEach { kvStr in
            if kvStr.contains("=") {
                let kv = kvStr.components(separatedBy: "=")
                if kv.count == 2 {
                    item[kv[0]] = kv[1]
                }
            }
        }
        self.id = item["id"] ?? ""
        self.name = item["name"] ?? ""
        self.addr = item["addr"] ?? ""
        self.laddr = item["laddr"] ?? ""
        self.fd = item["fd"] ?? ""
        self.age = item["age"] ?? ""
        self.idle = item["idle"] ?? ""
        self.flags = item["flags"] ?? ""
        self.db = item["db"] ?? ""
        self.sub = item["sub"] ?? ""
        self.psub = item["psub"] ?? ""
        self.multi = item["multi"] ?? ""
        self.qbuf = item["qbuf"] ?? ""
        self.qbuf_free = item["qbuf-free"] ?? ""
        self.obl = item["obl"] ?? ""
        self.oll = item["oll"] ?? ""
        self.omem = item["omem"] ?? ""
        self.events = item["events"] ?? ""
        self.cmd = item["cmd"] ?? ""
        self.argv_mem = item["argv-mem"] ?? ""
        self.tot_mem = item["tot-mem"] ?? ""
        self.redir = item["redir"] ?? ""
        self.user = item["user"] ?? ""
    }

    static func parse(_ text: String) -> [ClientModel] {
        return text.components(separatedBy: .newlines)
            .filter { !$0.isEmpty }
            .map { ClientModel(line: $0) }
    }
}
