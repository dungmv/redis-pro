//
//  RedisInfoModel.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/6/10.
//
import Foundation

struct RedisInfoModel: Identifiable, Sendable, Hashable {
    var id = UUID()
    var section: String = ""
    var infos: [RedisInfoItemModel] = []

    init() {}

    init(section: String) {
        self.section = section
    }

    static func parse(_ text: String) -> [RedisInfoModel] {
        var sections = [RedisInfoModel]()

        text.components(separatedBy: .newlines).forEach { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { return }

            if trimmed.hasPrefix("#") {
                let sectionName = String(trimmed.dropFirst()).trimmingCharacters(in: .whitespaces)
                sections.append(RedisInfoModel(section: sectionName))
            } else if !sections.isEmpty {
                let kv = trimmed.components(separatedBy: ":")
                if kv.count >= 2 {
                    let key = kv[0].trimmingCharacters(in: .whitespaces)
                    let value = kv.dropFirst().joined(separator: ":").trimmingCharacters(in: .whitespaces)
                    let lastIndex = sections.count - 1
                    sections[lastIndex].infos.append(RedisInfoItemModel(section: sections[lastIndex].section, key: key, value: value))
                }
            }
        }
        return sections
    }
}
