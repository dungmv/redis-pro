//
//  AppStore.swift
//  redis-pro
//
//  Created by chengpan on 2022/4/30.
//


import Logging
import Foundation
import ComposableArchitecture

private let logger = Logger(label: "app-store")

@Reducer
struct AppStore {
    
    @ObservableState
    struct State: Equatable, Identifiable {
        var id: String = UUID().uuidString
        var title: String = ""
        var isConnect: Bool = false
        @Shared(.inMemory("appContext")) var appContext = AppContextStore.State()
        var loadingState = LoadingStore.State()
        var favoriteState = FavoriteStore.State()
        var settingsState = SettingsStore.State()
        var redisKeysState = RedisKeysStore.State()

        init(id: String = UUID().uuidString) {
            self.id = id
            logger.info("app state init ...")
        }
    }

    enum Action: Equatable {
        case initial
        case onStart
        case onClose
        case onConnect
        case onDisconnect
        case appContextAction(AppContextStore.Action)
        case loadingAction(LoadingStore.Action)
        case favoriteAction(FavoriteStore.Action)
        case settingsAction(SettingsStore.Action)
        case redisKeysAction(RedisKeysStore.Action)
    }

    @Dependency(\.redisInstance) var redisInstanceModel: RedisInstanceModel
    
    var body: some Reducer<State, Action> {
        Scope(state: \.appContext, action: \.appContextAction) {
            AppContextStore()
        }
        Scope(state: \.loadingState, action: \.loadingAction) {
            LoadingStore()
        }
        Scope(state: \.settingsState, action: \.settingsAction) {
            SettingsStore()
        }
        Scope(state: \.favoriteState, action: \.favoriteAction) {
            FavoriteStore()
        }
        Scope(state: \.redisKeysState, action: \.redisKeysAction) {
            RedisKeysStore()
        }
        
        Reduce { state, action in
            switch action {
            case .initial:
                logger.info("init app context complete...")
                return .send(.redisKeysAction(.initial))
            case .onStart:
                logger.info("app store on start...")
                return .none
            case .onClose:
                logger.info("app store on close...")
                redisInstanceModel.close()
                state.isConnect = false
                return .none
            case .onConnect:
                logger.info("app store on connect...")
                state.isConnect = true
                return .none
            case .onDisconnect:
                logger.info("app store on disconnect...")
                state.isConnect = false
                return .none
            case .loadingAction:
                return .none
            case let .favoriteAction(.connectSuccess(redisModel)):
                state.title = redisModel.name
                return .run { send in
                    await send(.onConnect)
                }
            case .favoriteAction:
                return .none
            case .settingsAction:
                return .none
            case .redisKeysAction:
                return .none
            case .appContextAction:
                return .none
            }
        }
    }
}

@Reducer
struct AppRootStore {
    @ObservableState
    struct State {
        var windows: IdentifiedArrayOf<AppStore.State> = []
        var title: String = "Redis Pro"
    }
    
    enum Action {
        case windows(IdentifiedActionOf<AppStore>)
        case addWindow(String)
        case close
    }
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .addWindow(id):
                logger.info("add new window: \(id)")
                    
                state.windows.append(AppStore.State(id: id))
                return .none
            case .close:
                logger.info("close window")
                state.windows.removeLast()
                return .none
            case .windows(_):
                return .none
            }
        }
        .forEach(\.windows, action: \.windows) {
            AppStore()
        }
    }
}
