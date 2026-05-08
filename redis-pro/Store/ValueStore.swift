//
//  ValueStore.swift
//  redis-pro
//
//  Created by chengpanwang on 2022/5/6.
//  Migrated to MVVM (Swift 6)
//

import Logging
import Foundation
import Observation

private let logger = Logger(label: "value-store")

@MainActor
@Observable
final class ValueViewModel {
    let key: KeyViewModel
    let keyObject: KeyObjectViewModel
    let stringValue: StringValueViewModel
    let hashValue: HashValueViewModel
    let listValue: ListValueViewModel
    let setValue: SetValueViewModel
    let zsetValue: ZSetValueViewModel

    // Propagate submit success up to parent (RedisKeysViewModel)
    var onSubmitSuccess: ((Bool) -> Void)?

    init(redisInstance: RedisInstanceModel) {
        self.key = KeyViewModel(redisInstance: redisInstance)
        self.keyObject = KeyObjectViewModel(redisInstance: redisInstance)
        self.stringValue = StringValueViewModel(redisInstance: redisInstance)
        self.hashValue = HashValueViewModel(redisInstance: redisInstance)
        self.listValue = ListValueViewModel(redisInstance: redisInstance)
        self.setValue = SetValueViewModel(redisInstance: redisInstance)
        self.zsetValue = ZSetValueViewModel(redisInstance: redisInstance)

        setupCallbacks()
        logger.info("ValueViewModel init ...")
    }

    private func setupCallbacks() {
        let submitHandler: (Bool) -> Void = { [weak self] isNew in
            guard let self else { return }
            if isNew { self.key.isNew = false }
            self.key.refresh()
            self.onSubmitSuccess?(isNew)
        }
        let refreshHandler: () -> Void = { [weak self] in
            self?.key.refresh()
            self?.keyObject.refresh()
        }

        stringValue.onSubmitSuccess = submitHandler
        stringValue.onRefresh = refreshHandler
        hashValue.onSubmitSuccess = submitHandler
        hashValue.onRefresh = refreshHandler
        listValue.onSubmitSuccess = submitHandler
        listValue.onRefresh = refreshHandler
        setValue.onSubmitSuccess = submitHandler
        setValue.onRefresh = refreshHandler
        zsetValue.onSubmitSuccess = submitHandler
        zsetValue.onRefresh = refreshHandler
    }

    func refresh() {
        key.refresh()
        keyObject.refresh()
    }

    func keyChange(_ redisKeyModel: RedisKeyModel) {
        key.redisKeyModel = redisKeyModel
        keyObject.key = redisKeyModel.key

        // Route to the correct value VM
        if redisKeyModel.type == RedisKeyTypeEnum.STRING.rawValue {
            stringValue.redisKeyModel = redisKeyModel
            stringValue.initial()
        } else if redisKeyModel.type == RedisKeyTypeEnum.HASH.rawValue {
            hashValue.redisKeyModel = redisKeyModel
            hashValue.initial()
        } else if redisKeyModel.type == RedisKeyTypeEnum.LIST.rawValue {
            listValue.redisKeyModel = redisKeyModel
            listValue.initial()
        } else if redisKeyModel.type == RedisKeyTypeEnum.SET.rawValue {
            setValue.redisKeyModel = redisKeyModel
            setValue.initial()
        } else if redisKeyModel.type == RedisKeyTypeEnum.ZSET.rawValue {
            zsetValue.redisKeyModel = redisKeyModel
            zsetValue.initial()
        }

        key.refresh()
        keyObject.refresh()
    }

    func setKeyModel(_ redisKeyModel: RedisKeyModel) {
        key.redisKeyModel = redisKeyModel
        if redisKeyModel.type == RedisKeyTypeEnum.STRING.rawValue {
            stringValue.redisKeyModel = redisKeyModel
        } else if redisKeyModel.type == RedisKeyTypeEnum.HASH.rawValue {
            hashValue.redisKeyModel = redisKeyModel
        } else if redisKeyModel.type == RedisKeyTypeEnum.LIST.rawValue {
            listValue.redisKeyModel = redisKeyModel
        } else if redisKeyModel.type == RedisKeyTypeEnum.SET.rawValue {
            setValue.redisKeyModel = redisKeyModel
        } else if redisKeyModel.type == RedisKeyTypeEnum.ZSET.rawValue {
            zsetValue.redisKeyModel = redisKeyModel
        }
    }
}
