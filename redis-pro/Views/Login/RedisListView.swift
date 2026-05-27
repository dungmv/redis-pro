//
//  RedisListView.swift
//  redis-pro
//
//  Medis-inspired home screen: slim branding sidebar + connection list.
//  Form opens as a sheet modal; no embedded form panel.
//  Migrated to MVVM (Swift 6)
//

import SwiftUI
import Logging

struct RedisListView: View {

    private static let logger = Logger(label: "redis-list-view")

    @State var viewModel: FavoriteViewModel
    @State private var showEditSheet = false

    // MARK: - Body

    var body: some View {
        HSplitView {
            sidebarPanel
            connectionListPanel
        }
        .glassWindowSurface()
        .sheet(isPresented: $showEditSheet) {
            editSheet
        }
    }

    // MARK: - Edit Sheet

    private var editSheet: some View {
        ZStack(alignment: .topTrailing) {
            LoginForm(viewModel: viewModel.login)

            Button {
                showEditSheet = false
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .padding(14)
            .help("Close")
        }
    }

    // MARK: - Left Sidebar

    private var sidebarPanel: some View {
        VStack(spacing: 0) {
            Spacer()

            brandingSection

            Spacer()

            actionButtons
                .padding(.bottom, 20)
        }
        .frame(minWidth: 170, idealWidth: 180, maxWidth: 200)
        .background(.thinMaterial)
        .layoutPriority(0)
        .onAppear { onLoad() }
    }

    // MARK: - Branding

    private var brandingSection: some View {
        VStack(spacing: 10) {
            // App icon
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.96, green: 0.30, blue: 0.22),
                                Color(red: 0.78, green: 0.13, blue: 0.10)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 72, height: 72)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.18), lineWidth: 0.8)
                    )
                    .shadow(
                        color: Color(red: 0.96, green: 0.30, blue: 0.22).opacity(0.40),
                        radius: 14, x: 0, y: 6
                    )

                Image(systemName: "server.rack")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(.white)
                    .symbolRenderingMode(.hierarchical)
            }

            VStack(spacing: 4) {
                Text("Redis Pro")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.primary)

                Text("Version \(appVersion)")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 8) {
            Button("New Server…") {
                // Blank model in form; save after user fills details
                viewModel.login.redisModel = RedisModel()
                showEditSheet = true
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
        .padding(.horizontal, 14)
    }

    // MARK: - Connection List Panel

    private var connectionListPanel: some View {
        Group {
            if viewModel.table.datasource.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(
                            Array(viewModel.table.datasource.enumerated()),
                            id: \.offset
                        ) { index, model in
                            ConnectionRow(
                                model: model,
                                isSelected: viewModel.table.selectIndex == index,
                                onConnect: {
                                    viewModel.connect(index)
                                },
                                onEdit: {
                                    viewModel.table.selectionChange(index: index, indexes: [index])
                                    showEditSheet = true
                                },
                                onDuplicate: {
                                    var copy = model
                                    copy.id = UUID().uuidString
                                    copy.name = (model.name.isEmpty ? "New Connection" : model.name) + " Copy"
                                    viewModel.save(copy)
                                },
                                onDelete: {
                                    viewModel.deleteConfirm(index)
                                }
                            )

                            if index < viewModel.table.datasource.count - 1 {
                                Divider()
                                    .padding(.leading, 60)
                            }
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
        }
        .frame(minWidth: 380, maxWidth: .infinity, maxHeight: .infinity)
        .background(.regularMaterial)
        .layoutPriority(1)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "server.rack")
                .font(.system(size: 40))
                .foregroundStyle(.tertiary)

            VStack(spacing: 6) {
                Text("No connections")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)

                Text("Click \"New Server\" in the sidebar to add your first Redis connection.")
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 260)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helpers

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private func onLoad() {
        viewModel.getAll()
        viewModel.initDefaultSelection()
        let idx = viewModel.table.defaultSelectIndex
        if idx >= 0, idx < viewModel.table.datasource.count {
            viewModel.table.selectionChange(index: idx, indexes: [idx])
        }
    }
}

// MARK: - Connection Row

private struct ConnectionRow: View {
    let model: RedisModel
    let isSelected: Bool
    let onConnect: () -> Void
    let onEdit: () -> Void
    let onDuplicate: () -> Void
    let onDelete: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 12) {
            // Type icon
            typeIcon

            // Labels
            VStack(alignment: .leading, spacing: 3) {
                Text(model.name.isEmpty ? "New Connection" : model.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text("\(model.host):\(model.port)")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            // Action buttons (visible on hover or when selected)
            if isHovered || isSelected {
                HStack(spacing: 6) {
                    Button("Edit") { onEdit() }
                        .buttonStyle(.bordered)
                        .controlSize(.small)

                    Button("Connect") { onConnect() }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(rowBackground)
        .contentShape(Rectangle())
        .onHover { inside in
            withAnimation(.easeOut(duration: 0.12)) {
                isHovered = inside
            }
        }
        .onTapGesture(count: 2) { onConnect() }
        .onTapGesture(count: 1) { onEdit() }
        .contextMenu {
            Button {
                onConnect()
            } label: {
                Label("Connect", systemImage: "bolt.fill")
            }

            Button {
                onEdit()
            } label: {
                Label("Edit", systemImage: "pencil")
            }

            Divider()

            Button {
                onDuplicate()
            } label: {
                Label("Duplicate", systemImage: "doc.on.doc")
            }

            Divider()

            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    @ViewBuilder
    private var typeIcon: some View {
        ZStack {
            Circle()
                .fill(typeColor.opacity(0.14))
                .frame(width: 36, height: 36)

            Image(systemName: typeIconName)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(typeColor)
        }
    }

    @ViewBuilder
    private var rowBackground: some View {
        if isSelected {
            Color.accentColor.opacity(0.08)
        } else if isHovered {
            Color.primary.opacity(0.04)
        } else {
            Color.clear
        }
    }

    private var typeIconName: String {
        model.connectionType == RedisConnectionTypeEnum.SSH.rawValue
            ? "bolt.horizontal"
            : "network"
    }

    private var typeColor: Color {
        model.connectionType == RedisConnectionTypeEnum.SSH.rawValue
            ? Color(red: 0.98, green: 0.62, blue: 0.22)
            : Color(red: 0.20, green: 0.74, blue: 0.40)
    }
}


