//
//  RedisKeysStore.swift
//  redis-pro
//
//  Created by chengpanwang on 2022/5/6.
//  Migrated to MVVM (Swift 6)
//

import Logging
import Foundation
import SwiftUI
import Observation

private let logger = Logger(label: "redisKeys-store")

@MainActor
@Observable
final class RedisKeysViewModel {
    var database: Int = 0
    var dbsize: Int = 0
    var mainViewType: MainViewTypeEnum = .EDITOR
    var redisKeyNodes: [RedisKeyNode] = []
    var selectedKeyId: String? = nil

    let table: TableViewModel<RedisKeyModel>
    let redisSystem: RedisSystemViewModel
    let value: ValueViewModel
    let database_: DatabaseViewModel
    let page: PageViewModel
    let rename: RenameViewModel

    private let redisInstance: RedisInstanceModel

    // Debounce/cancel support
    private var searchTask: Task<Void, Never>?
    private var getKeysTask: Task<Void, Never>?
    private var countKeysTask: Task<Void, Never>?
    private var countLockId: Int = 0

    init(redisInstance: RedisInstanceModel) {
        self.redisInstance = redisInstance
        self.table = TableViewModel<RedisKeyModel>(
            columns: [
                .init(type: .KEY_TYPE, title: "Type", width: 40, color: { Color(nsColor: $0.textColor) }) { $0.type },
                .init(title: "Key", width: 50) { $0.key }
            ],
            datasource: [],
            contextMenus: [.COPY, .RENAME, .DELETE],
            multiSelect: true
        )
        self.redisSystem = RedisSystemViewModel(redisInstance: redisInstance)
        self.value = ValueViewModel(redisInstance: redisInstance)
        self.database_ = DatabaseViewModel(redisInstance: redisInstance)
        self.page = PageViewModel()
        self.rename = RenameViewModel(redisInstance: redisInstance)

        setupCallbacks()
        logger.info("RedisKeysViewModel init ...")
    }

    private func setupCallbacks() {
        // Table callbacks
        table.onSelectionChange = { [weak self] index, _ in
            guard let self else { return }
            self.onKeyChange(index)
        }
        table.onCopy = { [weak self] index in
            guard let self else { return }
            let item = self.table.datasource[index]
            PasteboardHelper.copy(item.key)
        }
        table.onContextMenu = { [weak self] title, index in
            guard let self else { return }
            if title == "Delete" { self.deleteConfirm([index]) }
            else if title == "Rename" {
                let redisKeyModel = self.table.datasource[self.table.selectIndex]
                self.rename.key = redisKeyModel.key
                self.rename.newKey = redisKeyModel.key
                self.rename.index = self.table.selectIndex
                self.rename.visible = true
            }
        }
        table.onDouble = { [weak self] _ in
            guard let self else { return }
            let redisKeyModel = self.table.datasource[self.table.selectIndex]
            self.rename.key = redisKeyModel.key
            self.rename.newKey = redisKeyModel.key
            self.rename.index = self.table.selectIndex
            self.rename.visible = true
        }
        table.onDelete = { [weak self] index in self?.deleteConfirm([index]) }

        // Database callbacks
        database_.onDBChange = { [weak self] db in
            guard let self else { return }
            // Reset selection and value state to prevent accessing old keys in new database
            self.table.selectIndex = -1
            self.table.selectIndexes = []
            self.table.datasource = []
            self.value.key.redisKeyModel = RedisKeyModel()
            self.mainViewType = .EDITOR
            self.page.total = 0
            self.page.current = 1
        }
        database_.onSelectDBSuccess = { [weak self] db in
            logger.info("database switch success, reload keys for database \(db)")
            self?.initial()
        }

        // Page callbacks
        page.onNextPage = { [weak self] in self?.getKeys() }
        page.onPrevPage = { [weak self] in self?.getKeys() }
        page.onUpdateSize = { [weak self] in self?.getKeys() }

        // Rename callback
        rename.onSetKey = { [weak self] index, newKey in
            guard let self else { return }
            var datasource = self.table.datasource
            let old = datasource[index]
            datasource[index] = RedisKeyModel(newKey, type: old.type)
            self.table.datasource = datasource
            self.selectedKeyId = newKey
            Task {
                let nodes = RedisKeyNode.buildTree(from: datasource)
                self.redisKeyNodes = nodes
            }
        }

        // Value submit success callback
        value.onSubmitSuccess = { [weak self] isNew in
            guard let self else { return }
            let redisKeyModel = self.value.key.redisKeyModel
            if isNew {
                self.table.datasource.insert(redisKeyModel, at: 0)
                let datasource = self.table.datasource
                self.selectedKeyId = redisKeyModel.key
                Task {
                    let nodes = RedisKeyNode.buildTree(from: datasource)
                    self.redisKeyNodes = nodes
                }
            }
        }

        // System view callback
        redisSystem.onSetSystemView = { [weak self] in
            self?.mainViewType = .SYSTEM
        }
    }

    // MARK: - Public API

    func initial() {
        logger.info("redis keys initial...")
        search(page.keywords)
        Task { await dbsize() }
    }

    func dbsize() async {
        do {
            let r = try await redisInstance.getClient().dbsize()
            dbsize = r
        } catch {
            Messages.show(error)
        }
    }

    func refresh() {
        initial()
    }

    func refreshCount() {
        Task { await dbsize() }
    }

    func search(_ keywords: String) {
        page.current = 1
        page.total = 0
        page.keywords = keywords
        table.datasource = []
        table.selectIndex = -1

        // Cancel running tasks
        getKeysTask?.cancel()
        countKeysTask?.cancel()

        getKeys()
        getCount()
    }

    func searchChange(_ keywords: String) {
        searchTask?.cancel()
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 400_000_000) // 400ms debounce
            guard !Task.isCancelled else { return }
            search(keywords)
        }
    }

    func getKeys() {
        let current = self.page.current
        let size = self.page.size
        let keywords = self.page.keywords
        getKeysTask?.cancel()
        getKeysTask = Task {
            do {
                var page = Page()
                page.current = current
                page.size = size
                page.keywords = keywords
                let keysPage = try await redisInstance.getClient().pageKeys(page)
                guard !Task.isCancelled else { return }
                let nodes = RedisKeyNode.buildTree(from: keysPage)
                self.redisKeyNodes = nodes
                self.table.datasource = keysPage
            } catch {
                guard !Task.isCancelled else { return }
                Messages.show(error)
            }
        }
    }

    func getCount() {
        countLockId += 1
        let lockId = countLockId
        countKeysTask?.cancel()
        countKeysTask = Task {
            await countKeys(cursor: 0, lockId: lockId)
        }
    }

    private func countKeys(cursor: Int, lockId: Int) async {
        guard lockId >= countLockId else {
            logger.info("New search started — aborting stale count task")
            return
        }
        guard !Task.isCancelled else { return }
        let current = self.page.current
        let size = self.page.size
        let keywords = self.page.keywords
        
        do {
            var page = Page()
            page.current = current
            page.size = size
            page.keywords = keywords
            let r = try await redisInstance.getClient().countKey(page, cursor: cursor)
            guard !Task.isCancelled, lockId >= countLockId else { return }
            self.page.total = self.page.total + r.1
            if r.0 != 0 {
                await countKeys(cursor: r.0, lockId: lockId)
            }
        } catch {
            guard !Task.isCancelled else { return }
            Messages.show(error)
        }
    }

    func setMainViewType(_ type: MainViewTypeEnum) {
        mainViewType = type
    }

    func addNew() {
        var newKey = RedisKeyModel()
        newKey.initNew()
        value.keyChange(newKey)
    }

    func selectNode(_ keyId: String?) {
        selectedKeyId = keyId
        if let keyId,
           let index = table.datasource.firstIndex(where: { $0.key == keyId }) {
            table.selectIndex = index
            table.selectIndexes = [index]
            let redisKeyModel = table.datasource[index]
            value.keyChange(redisKeyModel)
        } else {
            table.selectIndex = -1
            table.selectIndexes = []
        }
    }

    func onKeyChange(_ index: Int) {
        guard index > -1, index < table.datasource.count else {
            logger.info("onKeyChange: invalid index \(index)")
            return
        }
        mainViewType = .EDITOR
        let redisKeyModel = table.datasource[index]
        value.keyChange(redisKeyModel)
    }

    func deleteConfirm(_ indexes: [Int]) {
        guard !indexes.isEmpty && !table.isEmpty else { return }
        let redisKeys = indexes.map { table.datasource[$0] }
        let msg = (redisKeys.count > 3
            ? [redisKeys[0].key, "...", redisKeys[redisKeys.count - 1].key]
            : redisKeys.map { $0.key }
        ).joined(separator: "\n")

        Task {
            let r = await Messages.confirmAsync(
                String(format: NSLocalizedString("REDIS_KEY_DELETE_CONFIRM_TITLE'%@'", comment: ""), "\(redisKeys.count)"),
                message: String(format: NSLocalizedString("REDIS_KEY_DELETE_CONFIRM_MESSAGE'%@'", comment: ""), msg),
                primaryButton: "Delete"
            )
            if r { self.deleteKey(indexes) }
        }
    }

    func deleteNodeConfirm(_ node: RedisKeyNode) {
        let indexes: [Int]
        if node.isFolder {
            let prefix = node.fullName + ":"
            indexes = table.datasource.enumerated()
                .filter { $0.element.key == node.fullName || $0.element.key.hasPrefix(prefix) }
                .map { $0.offset }
        } else {
            if let index = table.datasource.firstIndex(where: { $0.key == node.fullName }) {
                indexes = [index]
            } else {
                indexes = []
            }
        }

        guard !indexes.isEmpty else { return }
        deleteConfirm(indexes)
    }

    func deleteKey(_ indexes: [Int]) {
        let redisKeys = indexes.map { table.datasource[$0] }
        logger.info("delete key: \(indexes)")
        Task {
            do {
                let r = try await redisInstance.getClient().del(redisKeys.map { $0.key })
                logger.info("on delete redis key: \(indexes), r:\(r)")
                if r > 0 {
                    self.deleteSuccess(indexes)
                }
            } catch {
                Messages.show(error)
            }
        }
    }

    func deleteSuccess(_ indexes: [Int]) {
        indexes.sorted(by: >).forEach { table.datasource.remove(at: $0) }
        let datasource = table.datasource
        table.selectIndex = -1
        table.selectIndexes = []
        selectedKeyId = nil
        Task {
            let nodes = RedisKeyNode.buildTree(from: datasource)
            self.redisKeyNodes = nodes
            await self.dbsize()
        }
    }

    func flushDBConfirm() {
        Task {
            let r = await Messages.confirmAsync(
                "Flush DB ?",
                message: "Are you sure you want to flush db? This operation cannot be undone.",
                primaryButton: "Ok"
            )
            if r { self.flushDB() }
        }
    }

    func flushDB() {
        Task {
            do {
                let r = try await redisInstance.getClient().flushDB()
                if r { self.initial() }
            } catch {
                Messages.show(error)
            }
        }
    }
}
