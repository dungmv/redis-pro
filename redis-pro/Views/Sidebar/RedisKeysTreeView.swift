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
            List(selection: selection) {
                OutlineGroup(viewModel.redisKeyNodes, children: \.children) { node in
                    TreeRow(viewModel: viewModel, node: node, selectedId: viewModel.selectedKeyId)
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 4))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .tag(node.id as String?)
                }

                if !viewModel.table.datasource.isEmpty && (viewModel.hasMoreKeys || viewModel.isLoadingMore) {
                    LoadMoreRow(viewModel: viewModel)
                        .listRowInsets(EdgeInsets(top: 6, leading: 12, bottom: 8, trailing: 12))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .environment(\.defaultMinListRowHeight, 20)
        }
    }

    private var headerView: some View {
        HStack {
            Text("KEYS")
                .font(.system(.caption))
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

private struct LoadMoreRow: View {
    let viewModel: RedisKeysViewModel

    var body: some View {
        HStack {
            Spacer(minLength: 0)
            Button {
                viewModel.loadMoreKeysIfNeeded()
            } label: {
                MLoading(
                    text: "Load more",
                    loadingText: "Loading more keys...",
                    loading: viewModel.isLoadingMore
                )
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isLoadingMore)
            Spacer(minLength: 0)
        }
        .contentShape(Rectangle())
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
            Button("Copy Key Name") {
                PasteboardHelper.copy(node.fullName)
            }
            if !node.isFolder {
                Button {
                    viewModel.copyValue(node)
                } label: {
                    Label("Copy Value", systemImage: "doc.on.doc")
                }
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
        HStack {
            Image(systemName: "folder.fill")
                .font(.system(.body))
                .foregroundStyle(isSelected ? Color.primary : Color.secondary)
                .symbolRenderingMode(.hierarchical)

            Text(node.name)
                .font(.system(.body))
                .lineLimit(1)

            Spacer(minLength: 4)

            Text("\(node.keyCount)")
                .font(.system(.caption))
                .padding(.horizontal, 4)
                .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 3))
        }
    }

    // MARK: Key Content

    private var keyContent: some View {
        HStack {
            TypeBadge(type: node.type?.uppercased() ?? "")

            Text(node.name)
                .font(.system(.body))
                .lineLimit(1)

            Spacer(minLength: 0)
        }
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
