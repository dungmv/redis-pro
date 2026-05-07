//
//  RedisKeysTreeView.swift
//  redis-pro
//
//  Liquid Glass sidebar tree view.
//  Optimized with native virtualization, high density, and keyboard navigation.
//  Migrated to MVVM (Swift 6)
//

import SwiftUI

// MARK: - Root tree view

struct RedisKeysTreeView: View {
    @State var viewModel: RedisKeysViewModel

    var body: some View {
        let selection = Binding<String?>(
            get: { viewModel.selectedKeyId },
            set: { id in viewModel.selectNode(id) }
        )

        VStack(alignment: .leading, spacing: 0) {
            // Section header
            headerView

            // Native hierarchical list for virtualization and performance
            List(viewModel.redisKeyNodes, children: \.children, selection: selection) { node in
                TreeRow(viewModel: viewModel, node: node, selectedId: viewModel.selectedKeyId)
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 4))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .tag(node.id as String?)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .environment(\.defaultMinListRowHeight, 20)
        }
    }

    private var headerView: some View {
        HStack {
            Text("KEYS")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.secondary)
                .kerning(0.8)
            Spacer()
            Text("\(viewModel.dbsize)")
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
    let viewModel: RedisKeysViewModel
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
            Divider()
            Button(role: .destructive) {
                viewModel.deleteNodeConfirm(node)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    // MARK: Folder Content

    private var folderContent: some View {
        HStack(spacing: 5) {
            Image(systemName: "folder.fill")
                .font(.system(.body))
                .foregroundStyle(isSelected ? Color.primary : Color.secondary.opacity(0.8))
                .symbolRenderingMode(.hierarchical)

            Text(node.name)
                .font(.system(.body))
                .foregroundStyle(isSelected ? Color.primary : Color.primary.opacity(0.9))
                .lineLimit(1)

            Spacer(minLength: 4)

            Text("\(node.keyCount)")
                .font(.system(.caption))
                .foregroundStyle(.secondary.opacity(0.8))
                .padding(.horizontal, 4)
                .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 3))
        }
        .frame(height: 20)
    }

    // MARK: Key Content

    private var keyContent: some View {
        HStack(spacing: 6) {
            TypeBadge(type: node.type?.uppercased() ?? "")

            Text(node.name)
                .font(.system(.body))
                .lineLimit(1)
                .foregroundStyle(isSelected ? Color.primary : Color.primary.opacity(0.9))

            Spacer(minLength: 0)
        }
        .frame(height: 22)
        .padding(.leading, -2)
        .padding(.trailing, 2)
    }
}

// MARK: - Compact Type Badge

private struct TypeBadge: View {
    let type: String

    var body: some View {
        Text(type.isEmpty ? "–" : String(type.prefix(1)))
            .font(.system(.subheadline))
            .foregroundStyle(.white)
            .frame(width: 14, height: 14)
            .background(
                RoundedRectangle(cornerRadius: 3)
                    .fill(LiquidGlass.typeColor(for: type))
            )
            .shadow(color: LiquidGlass.typeColor(for: type).opacity(0.25), radius: 1, x: 0, y: 0.5)
    }
}
