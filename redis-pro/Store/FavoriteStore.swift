//
//  FavoriteStore.swift
//  redis-pro
//
//  Created by chengpan on 2022/4/30.
//  Migrated to MVVM (Swift 6)
//

import Logging
import Foundation
import Observation

private let logger = Logger(label: "favorite-store")

@MainActor
@Observable
final class FavoriteViewModel {
    let table: TableViewModel<RedisModel>
    let login: LoginViewModel

    // Callback to AppViewModel when connection succeeds
    var onConnectSuccess: ((RedisModel) -> Void)?

    private let redisInstance: RedisInstanceModel

    init(redisInstance: RedisInstanceModel) {
        self.redisInstance = redisInstance
        self.table = TableViewModel<RedisModel>(
            columns: [.init(title: "FAVORITES", width: 50, icon: .APP) { $0.name }],
            datasource: [],
            dragable: true
        )
        self.login = LoginViewModel(redisInstance: redisInstance)
        setupTableCallbacks()
        setupLoginCallbacks()
        logger.info("FavoriteViewModel init ...")
    }

    private func setupTableCallbacks() {
        table.onSelectionChange = { [weak self] index, _ in
            guard let self, index > -1 else { return }
            logger.info("favorite selection change, index: \(index)")
            let redisModel = self.table.datasource[index]
            self.login.redisModel = redisModel
        }
        table.onDouble = { [weak self] index in self?.connect(index) }
        table.onDelete = { [weak self] index in self?.deleteConfirm(index) }
        table.onCopy = { [weak self] index in
            guard let self else { return }
            let redisModel = self.table.datasource[index]
            PasteboardHelper.copy(redisModel.name)
        }
        table.onDragComplete = { [weak self] _, _ in
            guard let self else { return }
            let _ = RedisDefaults.save(self.table.datasource)
        }
    }

    private func setupLoginCallbacks() {
        login.onConnect = { [weak self] in
            guard let self else { return }
            let index = self.table.selectIndex
            self.connect(index)
        }
        login.onSave = { [weak self] in
            guard let self else { return }
            let model = self.login.redisModel
            self.save(model)
        }
    }

    func getAll() {
        table.datasource = RedisDefaults.getAll()
    }

    func initDefaultSelection() {
        var selectId: String?
        let defaultFavorite = RedisDefaults.defaultSelectType()
        if defaultFavorite == "last" {
            selectId = RedisDefaults.getLastId()
        } else {
            selectId = defaultFavorite
        }

        guard let selectId else {
            table.defaultSelectIndex = table.datasource.count > 0 ? 0 : -1
            return
        }

        if let index = table.datasource.firstIndex(where: { $0.id == selectId }) {
            table.defaultSelectIndex = index
        } else {
            table.defaultSelectIndex = table.datasource.count > 0 ? 0 : -1
        }
    }

    func addNew() {
        save(RedisModel())
    }

    func save(_ redisModel: RedisModel) {
        logger.info("save redis favorite: \(redisModel)")
        let index = RedisDefaults.save(redisModel)
        table.selectIndex = index
        getAll()
    }

    func deleteConfirm(_ index: Int) {
        if table.datasource.count <= index { return }
        let redisModel = table.datasource[index]
        Task {
            let r = await Messages.confirmAsync(
                String(format: NSLocalizedString("CONFIRM_FAVORITE_REDIS_TITLE'%@'", comment: ""), redisModel.name),
                message: String(format: NSLocalizedString("CONFIRM_FAVORITE_REDIS_MESSAGE'%@'", comment: ""), redisModel.name),
                primaryButton: "Delete"
            )
            if r { self.delete(index) }
        }
    }

    func delete(_ index: Int) {
        let r = RedisDefaults.delete(index)
        if r {
            table.datasource.remove(at: index)
            if table.datasource.count - 1 < table.selectIndex {
                table.selectIndex = table.datasource.count - 1
            }
        }
        logger.info("delete redis favorite")
    }

    func connect(_ index: Int) {
        guard index >= 0, index < table.datasource.count else { return }
        let redisModel = table.datasource[index]
        logger.info("connect to redis server, name: \(redisModel.name), host: \(redisModel.host)")
        Task {
            let r = await redisInstance.connect(redisModel)
            logger.info("on connect to redis server: \(redisModel), result: \(r)")
            RedisDefaults.saveLastUse(redisModel)
            if r {
                self.onConnectSuccess?(redisModel)
            }
        }
    }
}
