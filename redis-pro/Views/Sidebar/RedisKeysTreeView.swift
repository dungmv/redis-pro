//
//  RedisKeysTreeView.swift
//  redis-pro
//
//  Liquid Glass sidebar tree view.
//

import SwiftUI
import ComposableArchitecture

// MARK: - Root tree view

struct RedisKeysTreeView: View {
    let store: StoreOf<RedisKeysStore>

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section header
            HStack {
                Text("KEYS")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.secondary)
                    .kerning(0.8)
                Spacer()
                Text("\(store.dbsize)")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.ultraThinMaterial, in: Capsule())
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 1) {
                    ForEach(store.redisKeyNodes) { node in
                        TreeRenderNode(node: node, store: store, level: 0)
                    }
                }
                .padding(.horizontal, 6)
                .padding(.bottom, 8)
            }
        }
    }
}

// MARK: - Tree node renderer

struct TreeRenderNode: View {
    let node: RedisKeyNode
    let store: StoreOf<RedisKeysStore>
    let level: CGFloat
    @State private var isExpanded: Bool = true
    @State private var isHovered: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            if node.isFolder {
                folderRow
                    .padding(.leading, level * 14)

                if isExpanded, let children = node.children {
                    VStack(alignment: .leading, spacing: 1) {
                        ForEach(children) { child in
                            TreeRenderNode(node: child, store: store, level: level + 1)
                        }
                    }
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity.combined(with: .move(edge: .top))
                    ))
                }
            } else {
                keyRow
                    .padding(.leading, level * 14 + 16)
            }
        }
    }

    // MARK: Folder row

    private var folderRow: some View {
        HStack(spacing: 5) {
            Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.tertiary)
                .frame(width: 10)
                .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isExpanded)

            Image(systemName: isExpanded ? "folder.open" : "folder")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
                .symbolRenderingMode(.hierarchical)

            Text(node.name)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.primary)
                .lineLimit(1)

            Spacer(minLength: 4)

            // Key count badge
            Text("\(node.keyCount)")
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 5)
                .padding(.vertical, 1)
                .background(.quaternary, in: Capsule())
        }
        .frame(height: 22)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: LiquidGlass.radiusXS)
                .fill(isHovered ? AnyShapeStyle(.thinMaterial) : AnyShapeStyle(Color.clear))
        )
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
        .onTapGesture {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                isExpanded.toggle()
            }
        }
    }

    // MARK: Key row

    private var keyRow: some View {
        let isSelected = store.selectedKeyId == node.id

        return HStack(spacing: 4) {
            TypeBadge(type: node.type?.uppercased() ?? "")

            Text(node.name)
                .font(.system(size: 12, design: .monospaced))
                .lineLimit(1)
                .foregroundStyle(isSelected ? Color.primary : Color.primary)

            Spacer(minLength: 0)
        }
        .frame(height: 22)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: LiquidGlass.radiusXS)
                .fill(
                    isSelected
                    ? AnyShapeStyle(.regularMaterial)
                    : (isHovered ? AnyShapeStyle(.thinMaterial) : AnyShapeStyle(Color.clear))
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: LiquidGlass.radiusXS)
                .strokeBorder(
                    isSelected
                    ? Color.accentColor.opacity(0.45)
                    : (isHovered ? LiquidGlass.glassBorder : Color.clear),
                    lineWidth: isSelected ? 1 : 0.5
                )
        )
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
        .onTapGesture { store.send(.selectNode(node.id)) }
        .contextMenu {
            Button("Copy Key") {
                PasteboardHelper.copy(node.id)
            }
        }
    }
}

// MARK: - Type Badge

private struct TypeBadge: View {
    let type: String

    var body: some View {
        Text(type.isEmpty ? "–" : type)
            .font(.system(size: 9, weight: .semibold, design: .monospaced))
            .tracking(0.3)
            .foregroundStyle(.white)
            .frame(width: 42, height: 14)
            .background(
                RoundedRectangle(cornerRadius: 3)
                    .fill(LiquidGlass.typeColor(for: type).opacity(0.85))
            )
    }
}
