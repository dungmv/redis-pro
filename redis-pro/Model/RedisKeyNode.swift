//
//  RedisKeyNode.swift
//  redis-pro
//
//  Created by chengpanwang on 2024/2/5.
//

import Foundation
import SwiftUI

struct RedisKeyNode: Identifiable, Equatable {
    let id: String
    let name: String
    let fullName: String
    let type: String? // If nil, it's a folder
    var children: [RedisKeyNode]?
    var keyCount: Int
    
    var isFolder: Bool {
        return children != nil
    }
    
    static func == (lhs: RedisKeyNode, rhs: RedisKeyNode) -> Bool {
        return lhs.id == rhs.id && lhs.keyCount == rhs.keyCount && lhs.children == rhs.children
    }
}

extension RedisKeyNode {
    static func buildTree(from keys: [RedisKeyModel]) -> [RedisKeyNode] {
        var root = [String: RedisKeyNode]()
        
        // Use a recursive structure to build the tree
        class InternalNode {
            var name: String
            var fullName: String
            var type: String?
            var children = [String: InternalNode]()
            var keyCount: Int = 0
            
            init(name: String, fullName: String, type: String? = nil) {
                self.name = name
                self.fullName = fullName
                self.type = type
            }
            
            func toRedisKeyNode() -> RedisKeyNode {
                let sortedChildren = children.values.sorted { $0.name < $1.name }.map { $0.toRedisKeyNode() }
                return RedisKeyNode(
                    id: fullName,
                    name: name,
                    fullName: fullName,
                    type: type,
                    children: sortedChildren.isEmpty ? nil : sortedChildren,
                    keyCount: children.isEmpty ? 1 : children.values.reduce(0) { $0 + $1.keyCount }
                )
            }
        }
        
        let rootInternal = InternalNode(name: "", fullName: "")
        
        for key in keys {
            let components = key.key.components(separatedBy: ":")
            var current = rootInternal
            var currentFullName = ""
            
            for (index, component) in components.enumerated() {
                if !currentFullName.isEmpty {
                    currentFullName += ":"
                }
                currentFullName += component
                
                let isLast = index == components.count - 1
                
                if let existing = current.children[component] {
                    current = existing
                    if isLast {
                        current.type = key.type
                        current.keyCount = 1
                    }
                } else {
                    let newNode = InternalNode(name: component, fullName: currentFullName)
                    if isLast {
                        newNode.type = key.type
                        newNode.keyCount = 1
                    }
                    current.children[component] = newNode
                    current = newNode
                }
            }
        }
        
        // Update key counts recursively (folders should show count of all descendants)
        func updateCounts(node: InternalNode) -> Int {
            if node.children.isEmpty {
                return 1
            }
            let total = node.children.values.reduce(0) { $0 + updateCounts(node: $1) }
            node.keyCount = total
            return total
        }
        
        updateCounts(node: rootInternal)
        
        return rootInternal.children.values.sorted { $0.name < $1.name }.map { $0.toRedisKeyNode() }
    }
}
