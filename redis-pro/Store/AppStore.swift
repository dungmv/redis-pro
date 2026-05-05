//
//  AppStore.swift
//  redis-pro
//
//  Created by chengpan on 2022/4/30.
//  Migrated to MVVM (Swift 6)
//

import Logging
import Foundation
import Observation

private let logger = Logger(label: "app-store")


@MainActor
@Observable
final class AppViewModel: Identifiable {
    nonisolated let id: String
    var title: String = ""
    var isConnect: Bool = false

    let appContext: AppContext
    let settings: SettingsViewModel
    let favorite: FavoriteViewModel
    let redisKeys: RedisKeysViewModel

    private let redisInstance: RedisInstanceModel

    init(id: String = UUID().uuidString, redisInstance: RedisInstanceModel, appContext: AppContext) {
        self.id = id
        self.redisInstance = redisInstance
        self.appContext = appContext
        self.settings = SettingsViewModel()
        self.favorite = FavoriteViewModel(redisInstance: redisInstance)
        self.redisKeys = RedisKeysViewModel(redisInstance: redisInstance)
        setupCallbacks()
        logger.info("AppViewModel init, id: \(id)")
    }

    private func setupCallbacks() {
        favorite.onConnectSuccess = { [weak self] redisModel in
            guard let self else { return }
            logger.info("connect success, name: \(redisModel.name)")
            self.title = redisModel.name
            self.isConnect = true
            self.redisKeys.database_.initial()
            self.redisKeys.initial()
        }
    }

    func initial() {
        logger.info("app initial...")
        redisKeys.initial()
    }

    func onStart() {
        logger.info("app on start...")
    }

    func onClose() {
        logger.info("app on close...")
        redisInstance.close()
        isConnect = false
    }

    func onConnect() {
        logger.info("app on connect...")
        isConnect = true
    }

    func onDisconnect() {
        logger.info("app on disconnect...")
        isConnect = false
    }
}

@MainActor
@Observable
final class AppRootViewModel {
    var windows: [AppViewModel] = []
    var title: String = "Redis Pro"

    private let appContext = AppContext()

    func addWindow(_ id: String) {
        logger.info("add new window: \(id)")
        let redisInstance = RedisInstanceModel(redisModel: RedisModel())
        let vm = AppViewModel(id: id, redisInstance: redisInstance, appContext: appContext)
        windows.append(vm)
    }

    func close() {
        logger.info("close window")
        windows.removeLast()
    }

    func window(id: String) -> AppViewModel? {
        windows.first(where: { $0.id == id })
    }
}


