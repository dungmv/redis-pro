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
        List {
            Section(header: Text("KEYS (\(store.dbsize) SCANNED)")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.secondary)
                .padding(.bottom, 4)
            ) {
                OutlineGroup(store.redisKeyNodes, id: \.id, children: \.children) { node in
                    nodeRow(node)
                }
            }
        }
        .listStyle(SidebarListStyle())
        .padding(.top, 4)
    }
    
    @ViewBuilder
    private func nodeRow(_ node: RedisKeyNode) -> some View {
        HStack(spacing: 6) {
            if let type = node.type {
                // Key item
                nodeTypeBadge(type)
                
                Text(node.name) // Use short name for nested display
                    .font(.system(size: 12))
                    .lineLimit(1)
                    .foregroundColor(store.selectedKeyId == node.id ? .white : .primary)
            } else {
                // Folder item
                Image(systemName: "folder")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                
                Text(node.name)
                    .font(.system(size: 12, weight: .medium))
                
                Spacer()
                
                Text("\(node.keyCount)")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 20, alignment: .leading)
        .padding(.vertical, 1)
        .padding(.horizontal, 4)
        .background(store.selectedKeyId == node.id ? Color.accentColor : Color.clear)
        .cornerRadius(4)
        .contentShape(Rectangle())
        .onTapGesture {
            if node.type != nil {
                store.send(.selectNode(node.id))
            }
        }
    }
    
    @ViewBuilder
    private func nodeTypeBadge(_ type: String) -> some View {
        Text(type.uppercased())
            .font(.system(size: 8, weight: .bold))
            .padding(.horizontal, 4)
            .padding(.vertical, 1)
            .frame(width: 40)
            .background(typeColor(type))
            .foregroundColor(.white)
            .cornerRadius(3)
    }
    
    private func typeColor(_ type: String) -> Color {
        switch type.uppercased() {
        case "STRING": return .green
        case "HASH": return .red
        case "LIST": return .blue
        case "SET": return .orange
        case "ZSET": return .purple
        default: return .gray
        }
    }
}
