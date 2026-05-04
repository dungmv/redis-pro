//
//  RedisInfoModel.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/6/10.
//
import Foundation

public class RedisInfoModel:NSObject, Identifiable {
    public var id = UUID()
    var section:String = ""
    var infos:[RedisInfoItemModel] = [RedisInfoItemModel]()
    
    override init() {
    }
    
    init(section:String) {
        self.section = section
    }
    
    static func parse(_ text: String) -> [RedisInfoModel] {
        var sections = [RedisInfoModel]()
        var currentSection: RedisInfoModel?
        
        text.components(separatedBy: .newlines).forEach { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { return }
            
            if trimmed.hasPrefix("#") {
                let sectionName = String(trimmed.dropFirst()).trimmingCharacters(in: .whitespaces)
                currentSection = RedisInfoModel(section: sectionName)
                sections.append(currentSection!)
            } else if let section = currentSection {
                let kv = trimmed.components(separatedBy: ":")
                if kv.count >= 2 {
                    let key = kv[0].trimmingCharacters(in: .whitespaces)
                    let value = kv.dropFirst().joined(separator: ":").trimmingCharacters(in: .whitespaces)
                    section.infos.append(RedisInfoItemModel(section: section.section, key: key, value: value))
                }
            }
        }
        return sections
    }
}
