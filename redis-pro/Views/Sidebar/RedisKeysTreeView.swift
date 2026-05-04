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
                    .listRowInsets(EdgeInsets(top: 0, leading: 1, bottom: 0, trailing: 4))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .tag(node.id as String?)
            }
            .listStyle(.plain) // Use plain style for tighter control over spacing
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
                .font(.system(.body))
                .foregroundStyle(isSelected ? Color.accentColor : .secondary.opacity(0.7))
                .symbolRenderingMode(.hierarchical)
            
            Text(node.name)
                .font(.system(.body))
                .foregroundStyle(isSelected ? .primary : Color.primary.opacity(0.9))
                .lineLimit(1)

            Spacer(minLength: 4)

            Text("\(node.keyCount)")
                .font(.system(.caption))
                .foregroundStyle(.secondary.opacity(0.8))
                .padding(.horizontal, 4)
                .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 3))
        }
        .frame(height: 20)
        .padding(.horizontal, 4)
    }

    // MARK: Key Content
    
    private var keyContent: some View {
        HStack(spacing: 6) {
            TypeBadge(type: node.type?.uppercased() ?? "")
            
            Text(node.name)
                .font(.system(.body)) // Medium weight for better visibility
                .lineLimit(1)
                .foregroundStyle(isSelected ? .primary : Color.primary.opacity(0.9))

            Spacer(minLength: 0)
        }
        .frame(height: 22) // Slightly increased for breathing room
        .padding(.horizontal, 2)
    }
}

// MARK: - Compact Type Badge

private struct TypeBadge: View {
    let type: String

    var body: some View {
        Text(type.isEmpty ? "–" : String(type.prefix(1)))
            .font(.system(.subheadline))
            .foregroundStyle(.white)
            .frame(width: 14, height: 14) // Balanced with 12pt text
            .background(
                RoundedRectangle(cornerRadius: 3)
                    .fill(LiquidGlass.typeColor(for: type))
            )
            .shadow(color: LiquidGlass.typeColor(for: type).opacity(0.25), radius: 1, x: 0, y: 0.5)
    }
}
