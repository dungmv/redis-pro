//
//  RedisKeysStore.swift
//  redis-pro
//
//  Created by chengpanwang on 2022/5/6.
//

import Logging
import Foundation
import SwiftUI
import ComposableArchitecture

private let logger = Logger(label: "redisKeys-store")

// MARK: - Cancel IDs
private enum CancelID {
    case countKeys
    case getKeys
    case search
}

@Reducer
struct RedisKeysStore {
    
    @ObservableState
    struct State: Equatable {
        var database:Int = 0
        var dbsize:Int = 0
        var keywords:String = ""
        // 查询批次
        var countLockId = 0
        
        var mainViewType: MainViewTypeEnum = .EDITOR
        var tableState: TableStore.State = TableStore.State(
            columns: [.init(type: .KEY_TYPE,title: "Type", key: "type", width: 40), .init(title: "Key", key: "key", width: 50)]
            , datasource: [], contextMenus: [.COPY, .RENAME, .DELETE]
            , selectIndex: -1
            ,multiSelect: true)
        var redisSystemState:RedisSystemStore.State = RedisSystemStore.State()
        var valueState: ValueStore.State = ValueStore.State()
        var databaseState: DatabaseStore.State = DatabaseStore.State()
        var pageState: PageStore.State = PageStore.State()
        var renameState: RenameStore.State = RenameStore.State()
        
        var redisKeyNodes: [RedisKeyNode] = []
        var selectedKeyId: String? = nil
        
        init() {
            logger.info("redisKeys state init ...")
        }
    }


    enum Action:Equatable {
        case initial
        case dbsize
        case refresh
        case refreshCount
        case search(String)
        case searchChange(String)
        case getKeys
        case getCount
        // 1. cursor, 2. searchGroup 查询批次
        case countKeys(Int, Int)
        case setKeys(Page, [RedisKeyModel])
        // 1. cursor, 2. count, 3. searchGroup 查询批次
        case setCount(Int, Int, Int)
        case setMainViewType(MainViewTypeEnum)
        case addNew
        
        case deleteConfirm([Int])
        case deleteKey([Int])
        case deleteSuccess([Int])
        
        case onKeyChange(Int)
        case setDBSize(Int)
        case flushDBConfirm
        case flushDB
        case tableAction(TableStore.Action)
        case redisSystemAction(RedisSystemStore.Action)
        case valueAction(ValueStore.Action)
        case databaseAction(DatabaseStore.Action)
        case pageAction(PageStore.Action)
        case renameAction(RenameStore.Action)
        case selectNode(String)
        case setRedisKeyNodes([RedisKeyNode])
        case none
    }

    @Dependency(\.redisInstance) var redisInstanceModel: RedisInstanceModel
    let mainQueue: AnySchedulerOf<DispatchQueue> = .main
    
    var body: some Reducer<State, Action> {
        Scope(state: \.tableState, action: \.tableAction) {
            TableStore()
        }
        Scope(state: \.pageState, action: \.pageAction) {
            PageStore()
        }
        Scope(state: \.redisSystemState, action: \.redisSystemAction) {
            RedisSystemStore()
        }
        Scope(state: \.valueState, action: \.valueAction) {
            ValueStore()
        }
        Scope(state: \.databaseState, action: \.databaseAction) {
            DatabaseStore()
        }
        Scope(state: \.renameState, action: \.renameAction) {
            RenameStore()
        }
        
        Reduce { state, action in
            switch action {
                // 初始化已设置的值
            case .initial:
                logger.info("redis keys store initial...")
                
                return .merge(
                    .send(.search(state.pageState.keywords)),
                    .send(.dbsize)
                )
                
                // 只刷新数量，比如删除时不刷新列表数据， 只刷新数量
            case .refreshCount:
                return .run { send in
                    await send(.dbsize)
                }
                
                // 全部刷新
            case .refresh:
                return .send(.initial)
                
                // 搜索
            case let .search(keywords):
                state.pageState.current = 1
                state.pageState.total = 0
                state.pageState.keywords = keywords
                state.tableState.datasource = []
                state.tableState.selectIndex = -1

                return .merge(
                    .cancel(id: CancelID.getKeys),     // cancel any running keys fetch
                    .cancel(id: CancelID.countKeys),   // cancel any running count scan
                    .send(.getKeys),
                    .send(.getCount)
                )
                
            case let .searchChange(keywords):
                return .send(.search(keywords))
                    .debounce(id: CancelID.search, for: .milliseconds(400), scheduler: mainQueue)
                
                // dbsize
            case .dbsize:
                return .run { send in
                    do {
                        let r = try await redisInstanceModel.getClient().dbsize()
                        await send(.setDBSize(r))
                    } catch {
                        Task { @MainActor in Messages.show(error) }
                    }
                }
                
                // 分页查询 key
            case .getKeys:
                let page = state.pageState.page
                return .run { send in
                    do {
                        let keysPage = try await redisInstanceModel.getClient().pageKeys(page)
                        await send(.setKeys(page, keysPage))
                    } catch {
                        Task { @MainActor in Messages.show(error) }
                    }
                }
                .cancellable(id: CancelID.getKeys, cancelInFlight: true)
                
            case .getCount:
                state.countLockId += 1
                let countLockId = state.countLockId

                return .run { send in
                    await send(.countKeys(0, countLockId))
                }
                .cancellable(id: CancelID.countKeys, cancelInFlight: true)

            // Async key count loop — cancelled by .search via CancelID.countKeys
            case let .countKeys(cursor, currentLockId):
                let page = state.pageState.page
                guard currentLockId >= state.countLockId else {
                    logger.info("New search started — aborting stale count task")
                    return .none
                }

                return .run { send in
                    do {
                        let r = try await redisInstanceModel.getClient().countKey(page, cursor: cursor)
                        await send(.setCount(r.0, r.1, currentLockId))
                    } catch {
                        Task { @MainActor in Messages.show(error) }
                    }
                }
                .cancellable(id: CancelID.countKeys)
                
                
            case let .setKeys(_, redisKeys):
                return .run { send in
                    let nodes = RedisKeyNode.buildTree(from: redisKeys)
                    await send(.setRedisKeyNodes(nodes))
                    await send(.tableAction(.setDatasource(redisKeys)))
                }
            
            case let .setRedisKeyNodes(nodes):
                state.redisKeyNodes = nodes
                return .none
            
            case let .selectNode(keyId):
                state.selectedKeyId = keyId
                // Find matching key model in datasource and update selection for delete button
                if let index = state.tableState.datasource.firstIndex(where: { ($0 as? RedisKeyModel)?.key == keyId }) {
                    state.tableState.selectIndex = index
                    state.tableState.selectIndexes = [index]
                    
                    let redisKeyModel = state.tableState.datasource[index] as! RedisKeyModel
                    return .send(.valueAction(.keyChange(redisKeyModel)))
                } else {
                    // If no key matched (e.g. folder selected), clear table selection
                    state.tableState.selectIndex = -1
                    state.tableState.selectIndexes = []
                }
                return .none
            
            case let .setCount(cursor, count, searchGroup):
                if searchGroup < state.countLockId {
                    return .none
                }
                
                state.pageState.total = state.pageState.total + count
                
                return cursor == 0 ? .none : .run { send in await send(.countKeys(cursor, searchGroup)) }
                
            case let .setMainViewType(mainViewType):
                state.mainViewType = mainViewType
                return .none
                
            case let .setDBSize(dbsize):
                state.dbsize = dbsize
                return .none
                
            case .addNew:
                let newKey = RedisKeyModel()
                newKey.initNew()
                return .run{ send in
                    await send(.valueAction(.keyChange(newKey)))
                }
                
            case let .deleteConfirm(indexes):
                guard !indexes.isEmpty && !state.tableState.isEmpty else {
                    return .none
                }
                
                let redisKeys = indexes.map({state.tableState.datasource[$0] as! RedisKeyModel})
                let msg = (redisKeys.count > 3 ? [redisKeys[0].key, "...", redisKeys[redisKeys.count - 1].key] : redisKeys.map({$0.key})).joined(separator: "\n")
                
                
                return .run { send in
                    let r = await Messages.confirmAsync(
                        String(format: NSLocalizedString("REDIS_KEY_DELETE_CONFIRM_TITLE'%@'", comment: ""), "\(redisKeys.count)")
                        , message: String(format: NSLocalizedString("REDIS_KEY_DELETE_CONFIRM_MESSAGE'%@'", comment: ""), msg)
                        , primaryButton: "Delete")
                    
                    await send(r ? .deleteKey(indexes) : .none)
                }
                
            case let .deleteKey(indexes):
                let redisKeys = indexes.map({state.tableState.datasource[$0] as! RedisKeyModel})
                logger.info("delete key: \(indexes)")
                
                return .run { send in

                    do {
                        let r = try await redisInstanceModel.getClient().del(redisKeys.map({$0.key}))
                        logger.info("on delete redis key: \(indexes), r:\(r)")
                        if r > 0 {
                            await send(.deleteSuccess(indexes))
                        }
                    } catch {
                        Task { @MainActor in Messages.show(error) }
                    }
                    await send(.none)
                }
                
            case let .deleteSuccess(indexes):
                // 降序排序后逐个删除， 必须先从最后的开始删除
                indexes.sorted(by: >).forEach({state.tableState.datasource.remove(at: $0)})
                let datasource = state.tableState.datasource.compactMap({ $0 as? RedisKeyModel })
                state.tableState.selectIndex = -1 // Reset selection after deletion
                state.selectedKeyId = nil // Reset selected key ID
                
                return .run { send in
                    let nodes = RedisKeyNode.buildTree(from: datasource)
                    await send(.setRedisKeyNodes(nodes))
                    await send(.refreshCount)
                }
                
            case let .onKeyChange(index):
                guard index > -1, index < state.tableState.datasource.count else { 
                    logger.info("onKeyChange: invalid index \(index) or empty datasource")
                    return .none 
                }
                
                state.mainViewType = .EDITOR
                let redisKeyModel = state.tableState.datasource[index] as! RedisKeyModel
                return .run { send in
                    await send(.valueAction(.keyChange(redisKeyModel)))
                }
                
            case .flushDBConfirm:
                return .run { send in
                    let r = await Messages.confirmAsync("Flush DB ?"
                                     , message: "Are you sure you want to flush db? This operation cannot be undone."
                                     , primaryButton: "Ok")
                    await send(r ? .flushDB : .none)
                }
                
            case .flushDB:
                return .run { send in
                    do {
                        let r = try await redisInstanceModel.getClient().flushDB()
                        if r {
                            await send(.initial)
                        }
                    } catch {
                        Task { @MainActor in Messages.show(error) }
                    }
                    await send(.none)
                }
                
                // redis 系统信息
            case .redisSystemAction(.setSystemView):
                state.mainViewType = .SYSTEM
                return .none
                
            case .redisSystemAction:
                return .none
                
                // submit 成功后， 如果是新增key，添加到列表
            case let .valueAction(.submitSuccess(isNew)):
                let redisKeyModel = state.valueState.keyState.redisKeyModel
                
                if isNew {
                    // 此处直接设置 selectIndex， 不会触 selectionChange, 会在设置datasource 时一起设置
                    state.tableState.datasource.insert(redisKeyModel, at: 0)
                    let datasource = state.tableState.datasource.compactMap({ $0 as? RedisKeyModel })
                    state.selectedKeyId = redisKeyModel.key
                    return .run { send in
                        let nodes = RedisKeyNode.buildTree(from: datasource)
                        await send(.setRedisKeyNodes(nodes))
                    }
                }
                return .none
                
            case .valueAction:
                return .none
                
                //MARK: --------------------------- table action ---------------------------
            case let .tableAction(.copy(index)):
                let item = state.tableState.datasource[index] as! RedisKeyModel
                PasteboardHelper.copy(item.key)
                return .none
                
            case let .tableAction(.selectionChange(index, _)):
                return .run { send in
                    await send(.onKeyChange(index))
                }
                
                // delete key
            case let .tableAction(.contextMenu(title, index)):
                if title == "Delete" {
                    return .run { send in
                        await send(.deleteConfirm([index]))
                    }
                }
                
                else  if title == "Rename" {
                    let redisKeyModel = state.tableState.datasource[state.tableState.selectIndex] as! RedisKeyModel
                    state.renameState.key = redisKeyModel.key
                    state.renameState.newKey = redisKeyModel.key
                    state.renameState.index = state.tableState.selectIndex
                    state.renameState.visible = true
                    
                }
                return .none
                
            case .tableAction(.double(_)):
                let redisKeyModel = state.tableState.datasource[state.tableState.selectIndex] as! RedisKeyModel
                state.renameState.key = redisKeyModel.key
                state.renameState.newKey = redisKeyModel.key
                state.renameState.index = state.tableState.selectIndex
                state.renameState.visible = true
                
                return .none
                
            case let .tableAction(.delete(index)):
                return .run { send in
                    await send(.deleteConfirm([index]))
                }
                
            case .tableAction:
                return .none
                
            //MARK:  --------------------------- database action ---------------------------
            case let .databaseAction(.onDBChange(database)):
                logger.info("change database, \(database)")
                // Reset selection and value state to prevent accessing old keys in new database
                state.tableState.selectIndex = -1
                state.tableState.selectIndexes = []
                state.tableState.datasource = []
                state.valueState = ValueStore.State()
                state.mainViewType = .EDITOR
                state.pageState.total = 0
                state.pageState.current = 1
                return .none
                
            case let .databaseAction(.selectDBSuccess(database)):
                logger.info("database switch success, reload keys for database \(database)")
                return .run { send in
                    await send(.initial)
                }
                
            case .databaseAction:
                return .none
                
            //MARK:  --------------------------- page action ---------------------------
            case .pageAction(.updateSize):
                return .run { send in
                    await send(.getKeys)
                }
            case .pageAction(.nextPage):
                return .run { send in
                    await send(.getKeys)
                }
            case .pageAction(.prevPage):
                return .run { send in
                    await send(.getKeys)
                }
            case .pageAction:
                return .none
                
            case let .renameAction(.setKey(index, newKey)):
                var datasource:[RedisKeyModel] = state.tableState.datasource as! [RedisKeyModel]
                let old = datasource[index]
                datasource[index] = RedisKeyModel(newKey, type: old.type)
                state.tableState.datasource = datasource
                let updatedDatasource = datasource
                state.selectedKeyId = newKey
                return .run { send in
                    let nodes = RedisKeyNode.buildTree(from: updatedDatasource)
                    await send(.setRedisKeyNodes(nodes))
                }
                
            case .renameAction:
                return .none
                
            case .none:
                return .none
            }
        }
    }
    
}
