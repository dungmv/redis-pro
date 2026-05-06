//
//  StringValueStore.swift
//  redis-pro
//
//  Created by chengpanwang on 2022/5/6.
//  Migrated to MVVM (Swift 6)
//

import Logging
import Foundation

import Observation

private let logger = Logger(label: "string-value-store")

@MainActor
@Observable
final class StringValueViewModel {
    var redisKeyModel: RedisKeyModel?
    var isIntactString: Bool = true
    var stringMaxLength: Int = -1
    var length: Int = -1
    var text: String = ""

    // Callback for submit success
    var onSubmitSuccess: ((Bool) -> Void)?
    var onRefresh: (() -> Void)?

    private let redisInstance: RedisInstanceModel

    init(redisInstance: RedisInstanceModel) {
        self.redisInstance = redisInstance
        logger.info("StringValueViewModel init ...")
    }

    func initial() {
        logger.info("string value initial...")
        Task { await getLength() }
    }

    func getLength() async {
        guard let redisKeyModel = redisKeyModel else { return }
        if redisKeyModel.isNew {
            text = ""
            return
        }
        let key = redisKeyModel.key
        do {
            let r = try await redisInstance.getClient().strLen(key)
            await updateLength(r)
        } catch {
            Messages.show(error)
        }
    }

    func getValue() async {
        guard let redisKeyModel = redisKeyModel else { return }
        if redisKeyModel.isNew {
            text = ""
            return
        }
        let key = redisKeyModel.key
        do {
            let r = isIntactString
                ? try await redisInstance.getClient().get(key)
                : try await redisInstance.getClient().getRange(key, end: stringMaxLength)
            text = r
        } catch {
            Messages.show(error)
        }
    }

    func getIntactString() {
        isIntactString = true
        Task { await getValue() }
    }

    func submit() {
        guard let redisKeyModel = redisKeyModel else { return }
        let key = redisKeyModel.key
        let isNew = redisKeyModel.isNew
        let text = self.text
        Task {
            do {
                try await redisInstance.getClient().set(key, value: text)
                onSubmitSuccess?(isNew)
            } catch {
                Messages.show(error)
            }
        }
    }

    func updateLength(_ length: Int) async {
        self.length = length
        let stringMaxLength = RedisDefaults.getStringMaxLength()
        self.stringMaxLength = stringMaxLength
        isIntactString = stringMaxLength == -1 || length <= stringMaxLength
        await getValue()
    }

    func jsonPretty() {
        if text.count < 2 {
            Messages.show(BizError("Invalid json format!"))
            return
        }
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data),
              let prettyData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
              let prettyString = String(data: prettyData, encoding: .utf8) else {
            Messages.show(BizError("Invalid json format!"))
            return
        }
        text = prettyString
    }

    func jsonMinify() {
        if text.count < 2 {
            Messages.show(BizError("Invalid json format!"))
            return
        }
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data),
              let minData = try? JSONSerialization.data(withJSONObject: json, options: []),
              let minString = String(data: minData, encoding: .utf8) else {
            Messages.show(BizError("Invalid json format!"))
            return
        }
        text = minString
    }

    func refresh() {
        Task { await getLength() }
        onRefresh?()
    }
}
