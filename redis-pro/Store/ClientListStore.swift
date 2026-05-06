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
    let table: TableViewModel<ClientModel>

    private let redisInstance: RedisInstanceModel

    init(redisInstance: RedisInstanceModel) {
        self.redisInstance = redisInstance
        self.table = TableViewModel<ClientModel>(
            columns: [
                .init(title: "id", width: 60) { $0.id },
                .init(title: "name", width: 60) { $0.name },
                .init(title: "addr", width: 140) { $0.addr },
                .init(title: "laddr", width: 140) { $0.laddr },
                .init(title: "fd", width: 60) { $0.fd },
                .init(title: "age", width: 60) { $0.age },
                .init(title: "idle", width: 60) { $0.idle },
                .init(title: "flags", width: 60) { $0.flags },
                .init(title: "db", width: 60) { $0.db },
                .init(title: "sub", width: 60) { $0.sub },
                .init(title: "psub", width: 60) { $0.psub },
                .init(title: "multi", width: 60) { $0.multi },
                .init(title: "qbuf", width: 60) { $0.qbuf },
                .init(title: "qbuf_free", width: 60) { $0.qbuf_free },
                .init(title: "obl", width: 60) { $0.obl },
                .init(title: "oll", width: 60) { $0.oll },
                .init(title: "omem", width: 60) { $0.omem },
                .init(title: "events", width: 60) { $0.events },
                .init(title: "cmd", width: 100) { $0.cmd },
                .init(title: "argv_mem", width: 60) { $0.argv_mem },
                .init(title: "tot_mem", width: 60) { $0.tot_mem },
                .init(title: "redir", width: 60) { $0.redir },
                .init(title: "user", width: 60) { $0.user },
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
        let item = table.datasource[index]
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
        let client = table.datasource[index]
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
