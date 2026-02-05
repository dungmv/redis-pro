//
//  RedisKeysTreeView.swift
//  redis-pro
//
//  Created by chengpanwang on 2024/2/5.
//

import SwiftUI
import ComposableArchitecture

struct RedisKeysTreeView: View {
    let store: StoreOf<RedisKeysStore>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("KEYS (\(store.dbsize) SCANNED)")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(store.redisKeyNodes) { node in
                        TreeRenderNode(node: node, store: store, level: 0)
                    }
                }
                .padding(.horizontal, 8)
            }
        }
    }
}

struct TreeRenderNode: View {
    let node: RedisKeyNode
    let store: StoreOf<RedisKeysStore>
    let level: CGFloat
    @State private var isExpanded: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let children = node.children {
                // Folder node - Custom implementation for tight spacing
                folderRow
                    .padding(.leading, level * 12)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isExpanded.toggle()
                        }
                    }
                
                if isExpanded {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(children) { child in
                            TreeRenderNode(node: child, store: store, level: level + 1)
                        }
                    }
                }
            } else {
                // Key node
                keyRow
                    .padding(.leading, (level * 12) + 16)
            }
        }
    }
    
    private var folderRow: some View {
        HStack(spacing: 4) {
            Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.secondary)
                .frame(width: 10)
            
            Image(systemName: "folder")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            
            Text(node.name)
                .font(.system(size: 12, weight: .regular))
                .lineLimit(1)
            
            Spacer()
            
            Text("\(node.keyCount)")
                .font(.system(size: 10))
                .foregroundColor(.secondary)
                .padding(.trailing, 4)
        }
        .frame(height: 20)
        .contentShape(Rectangle())
    }

    private var keyRow: some View {
        HStack(spacing: 2) {
            nodeTypeBadge(node.type?.uppercased() ?? "")
            
            Text(node.name)
                .font(.system(size: 12))
                .lineLimit(1)
                .foregroundColor(store.selectedKeyId == node.id ? .white : .primary)
            
            Spacer()
        }
        .frame(height: 20)
        .padding(.horizontal, 4)
        .background(store.selectedKeyId == node.id ? Color.accentColor : Color.clear)
        .cornerRadius(4)
        .contentShape(Rectangle())
        .onTapGesture {
            store.send(.selectNode(node.id))
        }
    }
    
    @ViewBuilder
    private func nodeTypeBadge(_ type: String) -> some View {
        Text(type)
            .font(.system(size: 10, weight: .regular))
            .padding(.horizontal, 2)
            .padding(.vertical, 1)
            .frame(width: 48)
            .background(typeColor(type))
            .foregroundColor(.white)
            .cornerRadius(3)
    }
    
    private func typeColor(_ type: String) -> Color {
        switch type {
        case "STRING": return .green
        case "HASH": return .red
        case "LIST": return .blue
        case "SET": return .orange
        case "ZSET": return .purple
        default: return .gray
        }
    }
}
