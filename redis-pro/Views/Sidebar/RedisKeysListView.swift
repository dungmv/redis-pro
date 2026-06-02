//
//  RedisKeysListView.swift
//  redis-pro
//
//  Liquid Glass main split view (sidebar + content).
//  Migrated to MVVM (Swift 6)
//

import SwiftUI
import Logging

struct RedisKeysListView: View {

    @State var viewModel: RedisKeysViewModel

    private static let logger = Logger(label: "redis-key-list-view")

    var body: some View {
        HSplitView {
            // Sidebar
            sidebarPanel
                .frame(minWidth: 260, idealWidth: 320, maxWidth: 440)
                .layoutPriority(0)

            // Content
            contentPanel
                .frame(minWidth: 560, maxWidth: .infinity, minHeight: 400, maxHeight: .infinity)
                .layoutPriority(1)
        }
    }

    // MARK: - Sidebar

    private var sidebarPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            sidebarHeader
            commandQueryButton
            Divider()
            RedisKeysTreeView(viewModel: viewModel)
            Divider()
            sidebarFooter
        }
    }

    private var commandQueryButton: some View {
        Button(action: {
            viewModel.selectCommandQuery()
        }) {
            HStack(spacing: 8) {
                Image(systemName: "terminal.fill")
                    .font(.system(size: 13, weight: .medium))
                Text("Command Query")
                    .font(.system(.body, weight: .medium))
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(viewModel.mainViewType == .QUERY ? Color.accentColor : Color.clear)
            )
            .foregroundStyle(viewModel.mainViewType == .QUERY ? .white : .primary)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }

    private var sidebarHeader: some View {
        SearchBar(
            placeholder: "Search keys...",
            onCommit: { viewModel.search($0) },
            onChange: { viewModel.searchChange($0) }
        )
        .padding(.horizontal, 8)
        .padding(.top, 8)
        .padding(.bottom, 6)
        .background(.thinMaterial)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color(NSColor.separatorColor))
                .frame(height: 0.5)
        }
    }

    private var sidebarFooter: some View {
        HStack(alignment: .center, spacing: 6) {
            Menu {
                Button("Keys Del")     { viewModel.redisSystem.setSystemView(.KEYS_DEL) }
                Button("Redis Info")   { viewModel.redisSystem.setSystemView(.REDIS_INFO) }
                Button("Redis Config") { viewModel.redisSystem.setSystemView(.REDIS_CONFIG) }
                Button("Clients")      { viewModel.redisSystem.setSystemView(.CLIENT_LIST) }
                Button("Slow Log")     { viewModel.redisSystem.setSystemView(.SLOW_LOG) }
                Button("Lua")          { viewModel.redisSystem.setSystemView(.LUA) }
                Divider()
                Button("Flush DB", role: .destructive) { viewModel.flushDBConfirm() }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .menuStyle(.borderlessButton)
            .frame(width: 24)
            .padding(.leading, 10)

            MIcon(icon: "arrow.clockwise", fontSize: 12) { viewModel.refresh() }
                .help("Refresh keys")

            MIcon(icon: "plus") { viewModel.addNew() }

            Spacer(minLength: 0)

            DatabasePicker(viewModel: viewModel.database_)
        }
        .frame(height: 30)
        .background(.thinMaterial)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color(NSColor.separatorColor))
                .frame(height: 0.5)
        }
    }

    // MARK: - Content

    private var contentPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            switch viewModel.mainViewType {
            case .EDITOR:
                RedisValueView(viewModel: viewModel.value)
            case .SYSTEM:
                RedisSystemView(viewModel: viewModel.redisSystem)
            case .QUERY:
                CommandQueryView(viewModel: viewModel.commandQuery)
            case .NONE:
                EmptyView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
