//
//  DatabaseStore.swift
//  redis-pro
//
//  Created by chengpanwang on 2022/5/6.
//

import Logging
import Foundation
import ComposableArchitecture

private let logger = Logger(label: "database-store")

@Reducer
struct DatabaseStore {
    
    @ObservableState
    struct State: Equatable {
        var database: Int = 0
        var databases:Int = 16

        init() {
            logger.info("database state init ...")
        }
    }


    enum Action:BindableAction, Equatable {
        case initial
        case getDatabases
        case setDB(Int)
        case selectDB(Int)
        case onDBChange(Int)
        case selectDBSuccess(Int)
        case none
        case binding(BindingAction<State>)
    }
    
    @Dependency(\.redisInstance) var redisInstanceModel:RedisInstanceModel
    var mainQueue: AnySchedulerOf<DispatchQueue> = .main
    
    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            // 初始化已设置的值
            case .initial:
                logger.info("database store initial...")
                state.database = redisInstanceModel.redisModel.database
                return .run { send in
                    await send(.getDatabases)
                }
            case .getDatabases:
                return .run { send in
                    do {
                        let r = try await redisInstanceModel.getClient().databases()
                        await send(.setDB(r))
                    } catch {
                        Task { @MainActor in Messages.show(error) }
                    }
                }
            case let .setDB(databases):
                state.databases = databases
                return .none
            case let .selectDB(database):
                logger.info("selectDB: switching to database \(database)")
                state.database = database
                
                return .run { send in
                    // 1. Send onDBChange immediately to clear UI
                    await send(.onDBChange(database))
                    
                    do {
                        // 2. Perform the actual database switch
                        let r = try await redisInstanceModel.getClient().selectDB(database)
                        if r {
                            // 3. Notify success to trigger reload in other stores
                            await send(.selectDBSuccess(database))
                        }
                    } catch {
                        logger.error("Failed to switch to database \(database): \(error)")
                        Task { @MainActor in Messages.show(error) }
                    }
                }
                
            case .onDBChange:
                return .none
            case .selectDBSuccess:
                return .none
            case .none:
                return .none
            case .binding:
                return .none
            }
        }
    }
    

}

