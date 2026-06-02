//
//  Login.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/1/25.
//  Migrated to MVVM (Swift 6)
//

import SwiftUI
import Logging

struct LoginView: View {
    private static let logger = Logger(label: "login-view")

    @State var viewModel: AppViewModel
    @State private var showEditSheet = false

    private var favoriteViewModel: FavoriteViewModel {
        viewModel.favorite
    }

    init(viewModel: AppViewModel) {
        Self.logger.info("login view init...")
        self.viewModel = viewModel
    }

    var body: some View {
        HSplitView {
            sidebarPanel
            connectionListPanel
        }
        .sheet(isPresented: $showEditSheet) {
            editSheet
        }
    }

    // MARK: - Edit Sheet

    private var editSheet: some View {
        ZStack(alignment: .topTrailing) {
            LoginForm(viewModel: favoriteViewModel.login)

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
                favoriteViewModel.login.redisModel = RedisModel()
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
            if favoriteViewModel.table.datasource.isEmpty {
                emptyState
            } else {
                let selection = Binding<Int>(
                    get: { favoriteViewModel.table.selectIndex },
                    set: { index in
                        favoriteViewModel.table.selectionChange(index: index, indexes: index >= 0 ? [index] : [])
                    }
                )

                ConnectionTableView(
                    datasource: favoriteViewModel.table.datasource,
                    selectIndex: selection,
                    onConnect: { index in
                        favoriteViewModel.connect(index)
                    },
                    onEdit: { index in
                        favoriteViewModel.table.selectionChange(index: index, indexes: [index])
                        showEditSheet = true
                    },
                    onDuplicate: { index in
                        let model = favoriteViewModel.table.datasource[index]
                        var copy = model
                        copy.id = UUID().uuidString
                        copy.name = (model.name.isEmpty ? "New Connection" : model.name) + " Copy"
                        favoriteViewModel.save(copy)
                    },
                    onDelete: { index in
                        favoriteViewModel.deleteConfirm(index)
                    }
                )
            }
        }
        .frame(minWidth: 380, maxWidth: .infinity, maxHeight: .infinity)
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
        favoriteViewModel.getAll()
        favoriteViewModel.initDefaultSelection()
        let idx = favoriteViewModel.table.defaultSelectIndex
        if idx >= 0, idx < favoriteViewModel.table.datasource.count {
            favoriteViewModel.table.selectionChange(index: idx, indexes: [idx])
        }
    }
}

// MARK: - Connection Row

private struct ConnectionRow: View {
    let model: RedisModel

    var body: some View {
        HStack(spacing: 12) {
            // Type icon
            typeIcon

            // Labels
            VStack(alignment: .leading, spacing: 3) {
                Text(model.name.isEmpty ? "New Connection" : model.name)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)

                Text("\(model.host):\(model.port)")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
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

// MARK: - Connection Table View (NSTableView wrapper)

private struct ConnectionTableView: NSViewRepresentable {
    let datasource: [RedisModel]
    @Binding var selectIndex: Int
    let onConnect: (Int) -> Void
    let onEdit: (Int) -> Void
    let onDuplicate: (Int) -> Void
    let onDelete: (Int) -> Void

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = false
        scrollView.backgroundColor = .clear

        let tableView = NSTableView()
        tableView.headerView = nil
        tableView.backgroundColor = .clear
        tableView.style = .plain
        tableView.usesAlternatingRowBackgroundColors = false
        tableView.columnAutoresizingStyle = .firstColumnOnlyAutoresizingStyle
        
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("ConnectionColumn"))
        column.resizingMask = .autoresizingMask
        tableView.addTableColumn(column)

        tableView.delegate = context.coordinator
        tableView.dataSource = context.coordinator
        tableView.doubleAction = #selector(Coordinator.doubleClickRow(_:))
        tableView.target = context.coordinator

        // Context Menu
        let menu = NSMenu()
        
        let connectItem = NSMenuItem(title: "Connect", action: #selector(Coordinator.connectMenuAction(_:)), keyEquivalent: "")
        connectItem.target = context.coordinator
        menu.addItem(connectItem)
        
        let editItem = NSMenuItem(title: "Edit", action: #selector(Coordinator.editMenuAction(_:)), keyEquivalent: "")
        editItem.target = context.coordinator
        menu.addItem(editItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let duplicateItem = NSMenuItem(title: "Duplicate", action: #selector(Coordinator.duplicateMenuAction(_:)), keyEquivalent: "")
        duplicateItem.target = context.coordinator
        menu.addItem(duplicateItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let deleteItem = NSMenuItem(title: "Delete", action: #selector(Coordinator.deleteMenuAction(_:)), keyEquivalent: "")
        deleteItem.target = context.coordinator
        menu.addItem(deleteItem)
        
        tableView.menu = menu

        scrollView.documentView = tableView
        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let tableView = nsView.documentView as? NSTableView else { return }
        
        context.coordinator.parent = self
        context.coordinator.datasource = datasource
        
        tableView.reloadData()

        if selectIndex >= 0 && selectIndex < datasource.count {
            if tableView.selectedRow != selectIndex {
                tableView.selectRowIndexes(IndexSet(integer: selectIndex), byExtendingSelection: false)
            }
        } else {
            tableView.deselectAll(nil)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTableViewDelegate, NSTableViewDataSource, NSMenuItemValidation {
        var parent: ConnectionTableView
        var datasource: [RedisModel]
        weak var tableView: NSTableView?

        init(_ parent: ConnectionTableView) {
            self.parent = parent
            self.datasource = parent.datasource
        }

        func numberOfRows(in tableView: NSTableView) -> Int {
            datasource.count
        }

        func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
            self.tableView = tableView
            guard row >= 0 && row < datasource.count else { return nil }
            let model = datasource[row]
            
            let identifier = NSUserInterfaceItemIdentifier("ConnectionCell")
            var hostingView = tableView.makeView(withIdentifier: identifier, owner: self) as? NSHostingView<ConnectionRow>

            let cellView = ConnectionRow(model: model)

            if let hostingView = hostingView {
                hostingView.rootView = cellView
                return hostingView
            } else {
                let newHostingView = NSHostingView(rootView: cellView)
                newHostingView.identifier = identifier
                return newHostingView
            }
        }

        func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
            return 50
        }

        func tableViewSelectionDidChange(_ notification: Notification) {
            guard let tableView = notification.object as? NSTableView else { return }
            let selectedRow = tableView.selectedRow
            DispatchQueue.main.async {
                if self.parent.selectIndex != selectedRow {
                    self.parent.selectIndex = selectedRow
                }
            }
        }

        @objc func doubleClickRow(_ sender: AnyObject) {
            guard let tableView = sender as? NSTableView else { return }
            let clickedRow = tableView.clickedRow
            guard clickedRow >= 0 && clickedRow < datasource.count else { return }
            parent.onConnect(clickedRow)
        }

        @objc func connectMenuAction(_ sender: AnyObject) {
            guard let clickedRow = tableView?.clickedRow, clickedRow >= 0 && clickedRow < datasource.count else { return }
            parent.onConnect(clickedRow)
        }

        @objc func editMenuAction(_ sender: AnyObject) {
            guard let clickedRow = tableView?.clickedRow, clickedRow >= 0 && clickedRow < datasource.count else { return }
            parent.onEdit(clickedRow)
        }

        @objc func duplicateMenuAction(_ sender: AnyObject) {
            guard let clickedRow = tableView?.clickedRow, clickedRow >= 0 && clickedRow < datasource.count else { return }
            parent.onDuplicate(clickedRow)
        }

        @objc func deleteMenuAction(_ sender: AnyObject) {
            guard let clickedRow = tableView?.clickedRow, clickedRow >= 0 && clickedRow < datasource.count else { return }
            parent.onDelete(clickedRow)
        }

        func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
            guard let tableView = tableView else { return false }
            return tableView.clickedRow >= 0 && tableView.clickedRow < datasource.count
        }
    }
}
