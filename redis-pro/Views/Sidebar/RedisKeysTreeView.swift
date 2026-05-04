//
//  RedisKeysTreeView.swift
//  redis-pro
//
//  Liquid Glass sidebar tree view.
//  Optimized with native virtualization, high density, and keyboard navigation.
//

import SwiftUI
import ComposableArchitecture

// MARK: - Root tree view

struct RedisKeysTreeView: View {
    let store: StoreOf<RedisKeysStore>

    var body: some View {
        let selection = Binding<String?>(
            get: { store.selectedKeyId },
            set: { id in
                if let id = id {
                    store.send(.selectNode(id))
                }
            }
        )

        VStack(alignment: .leading, spacing: 0) {
            // Section header
            headerView
            
            // Native hierarchical list for virtualization and performance
            List(store.redisKeyNodes, children: \.children, selection: selection) { node in
                TreeRow(node: node, selectedId: store.selectedKeyId)
                    .listRowInsets(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 4))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .tag(node.id as String?) // Explicit cast to match selection type
            }
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden)
            .environment(\.defaultMinListRowHeight, 20) // High density
        }
    }

    private var headerView: some View {
        HStack {
            Text("KEYS")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.secondary)
                .kerning(0.8)
            Spacer()
            Text("\(store.dbsize)")
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .foregroundStyle(.tertiary)
                .padding(.horizontal, 5)
                .padding(.vertical, 1)
                .background(.ultraThinMaterial, in: Capsule())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }
}

// MARK: - Optimized Tree Row

struct TreeRow: View {
    let node: RedisKeyNode
    let selectedId: String?
    
    @State private var isHovered: Bool = false
    
    private var isSelected: Bool {
        selectedId == node.id
    }

    var body: some View {
        HStack(spacing: 0) {
            if node.isFolder {
                folderContent
            } else {
                keyContent
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
        .contextMenu {
            Button("Copy Full Name") {
                PasteboardHelper.copy(node.fullName)
            }
            if !node.isFolder {
                Button("Delete Key", role: .destructive) {
                    // Action handled via store normally
                }
            }
        }
    }

    // MARK: Folder Content
    
    private var folderContent: some View {
        HStack(spacing: 5) {
            Image(systemName: "folder.fill")
                .font(.system(size: 10))
                .foregroundStyle(isSelected ? Color.accentColor : .secondary.opacity(0.7))
                .symbolRenderingMode(.hierarchical)
            
            Text(node.name)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(isSelected ? .primary : Color.primary.opacity(0.9))
                .lineLimit(1)

            Spacer(minLength: 4)

            Text("\(node.keyCount)")
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundStyle(.secondary.opacity(0.8))
                .padding(.horizontal, 4)
                .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 3))
        }
        .frame(height: 20)
        .padding(.horizontal, 4)
    }

    // MARK: Key Content
    
    private var keyContent: some View {
        HStack(spacing: 5) {
            TypeBadge(type: node.type?.uppercased() ?? "")
            
            Text(node.name)
                .font(.system(size: 11, design: .monospaced))
                .lineLimit(1)
                .foregroundStyle(isSelected ? .primary : Color.primary.opacity(0.85))

            Spacer(minLength: 0)
        }
        .frame(height: 20)
        .padding(.horizontal, 4)
    }
}

// MARK: - Compact Type Badge

private struct TypeBadge: View {
    let type: String

    var body: some View {
        Text(type.isEmpty ? "–" : String(type.prefix(1)))
            .font(.system(size: 7.5, weight: .black, design: .monospaced))
            .foregroundStyle(.white)
            .frame(width: 12, height: 12)
            .background(
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(LiquidGlass.typeColor(for: type))
            )
            .shadow(color: LiquidGlass.typeColor(for: type).opacity(0.2), radius: 1, x: 0, y: 0.5)
    }
}
