//
//  ClientListStore.swift
//  redis-pro
//
//  Created by chengpan on 2022/6/5.
//  Migrated to MVVM (Swift 6)
//

import Logging
import Foundation
import Observation

private let logger = Logger(label: "client-list-store")

@MainActor
@Observable
final class ClientListViewModel {
    let table: TableViewModel

    private let redisInstance: RedisInstanceModel

    init(redisInstance: RedisInstanceModel) {
        self.redisInstance = redisInstance
        self.table = TableViewModel(
            columns: [
                .init(title: "id", key: "id", width: 60),
                .init(title: "name", key: "name", width: 60),
                .init(title: "addr", key: "addr", width: 140),
                .init(title: "laddr", key: "laddr", width: 140),
                .init(title: "fd", key: "fd", width: 60),
                .init(title: "age", key: "age", width: 60),
                .init(title: "idle", key: "idle", width: 60),
                .init(title: "flags", key: "flags", width: 60),
                .init(title: "db", key: "db", width: 60),
                .init(title: "sub", key: "sub", width: 60),
                .init(title: "psub", key: "psub", width: 60),
                .init(title: "multi", key: "multi", width: 60),
                .init(title: "qbuf", key: "qbuf", width: 60),
                .init(title: "qbuf_free", key: "qbuf_free", width: 60),
                .init(title: "obl", key: "obl", width: 60),
                .init(title: "oll", key: "oll", width: 60),
                .init(title: "omem", key: "omem", width: 60),
                .init(title: "events", key: "events", width: 60),
                .init(title: "cmd", key: "cmd", width: 100),
                .init(title: "argv_mem", key: "argv_mem", width: 60),
                .init(title: "tot_mem", key: "tot_mem", width: 60),
                .init(title: "redir", key: "redir", width: 60),
                .init(title: "user", key: "user", width: 60),
            ],
            datasource: [],
            contextMenus: [.KILL]
        )
        setupTableCallbacks()
        logger.info("ClientListViewModel init ...")
    }

    private func setupTableCallbacks() {
        table.onContextMenu = { [weak self] title, index in
            guard let self else { return }
            if title == "Kill" { self.killConfirm(index) }
        }
    }

    func initial() {
        logger.info("client list initial...")
        getValue()
    }

    func refresh() {
        getValue()
    }

    func getValue() {
        Task {
            do {
                let r = try await redisInstance.getClient().clientList()
                table.datasource = r
            } catch {
                Messages.show(error)
            }
        }
    }

    func killConfirm(_ index: Int) {
        let item = table.datasource[index] as! ClientModel
        Task {
            let r = await Messages.confirmAsync(
                "Kill Client?",
                message: "Are you sure you want to kill client:\(item.addr)? This operation cannot be undone.",
                primaryButton: "Kill"
            )
            if r { self.kill(index) }
        }
    }

    func kill(_ index: Int) {
        let client = table.datasource[index] as! ClientModel
        logger.info("kill client, addr: \(client.addr)")
        Task {
            do {
                let r = try await redisInstance.getClient().clientKill(client)
                logger.info("do kill client, addr: \(client.addr), r:\(r)")
                refresh()
            } catch {
                Messages.show(error)
            }
        }
    }
}
