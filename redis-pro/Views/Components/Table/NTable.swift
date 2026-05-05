//
//  NTable.swift
//  redis-pro
//
//  Created by chengpan on 2021/12/17.
//  Migrated to MVVM (Swift 6) — removed TCA, uses @Observable TableViewModel
//

import SwiftUI
import Logging
import Cocoa
import Combine

// MARK: - NTableView (NSViewControllerRepresentable)

struct NTableView: NSViewControllerRepresentable {

    let viewModel: TableViewModel
    let logger = Logger(label: "ntable")

    func makeCoordinator() -> Coordinator {
        logger.debug("init ntable coordinator...")
        return Coordinator(self)
    }

    func makeNSViewController(context: Context) -> NSViewController {
        let controller = NTableController(viewModel)
        logger.debug("ntable make nsview controller....")
        return controller
    }

    func updateNSViewController(_ nsViewController: NSViewController, context: Context) {
        logger.debug("ntable update nsview controller")
        if let controller = nsViewController as? NTableController {
            controller.updateViewModel(self.viewModel)
        }
    }

    class Coordinator: NSObject, NSTableViewDelegate, NSTableViewDataSource {
        var table: NTableView
        let logger = Logger(label: "table-coordinator")

        init(_ table: NTableView) {
            self.table = table
        }
    }
}

// MARK: - NTableController (NSViewController)

class NTableController: NSViewController {

    @objc dynamic var datasource: [AnyHashable] = []
    var arrayController = NSArrayController()
    var initialized = false
    let scrollView = NSScrollView()
    let tableView = NSTableView()

    // drag
    let pasteboardType = NSPasteboard.PasteboardType.string

    var viewModel: TableViewModel
    var cancellables: Set<AnyCancellable> = []
    var observationTask: Task<Void, Never>?

    let logger = Logger(label: "table-view-controller")

    init(_ viewModel: TableViewModel) {
        logger.info("table controller init...")
        self.viewModel = viewModel
        self.datasource = viewModel.datasource
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        self.view = NSView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if initialized { return }
        initialized = true

        tableView.allowsEmptySelection = false

        if self.viewModel.dragable {
            tableView.registerForDraggedTypes([pasteboardType])
        }
        if self.viewModel.multiSelect {
            tableView.allowsMultipleSelection = true
        }

        // bind datasource
        arrayController.bind(.contentArray, to: self, withKeyPath: "datasource", options: nil)
        tableView.bind(.content, to: arrayController, withKeyPath: "arrangedObjects", options: nil)
        tableView.bind(.selectionIndexes, to: arrayController, withKeyPath: "selectionIndexes", options: nil)

        setupView()
        setupTableView()
        startObserving()
    }

    func updateViewModel(_ newVM: TableViewModel) {
        if self.viewModel === newVM { return }
        logger.info("table controller update viewModel...")
        self.viewModel = newVM
        observationTask?.cancel()
        startObserving()
    }

    // MARK: - Observe @Observable TableViewModel using withObservationTracking
    func startObserving() {
        observationTask?.cancel()
        observationTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                // Capture current values
                let datasource = self.viewModel.datasource
                let selectIndex = self.viewModel.selectIndex
                let defaultSelectIndex = self.viewModel.defaultSelectIndex

                // Apply changes to NSTableView
                self.updateTableView(datasource: datasource, selectIndex: selectIndex, defaultSelectIndex: defaultSelectIndex)

                // Wait for next change using withObservationTracking continuation
                await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                    _ = withObservationTracking {
                        _ = self.viewModel.datasource
                        _ = self.viewModel.selectIndex
                        _ = self.viewModel.defaultSelectIndex
                    } onChange: {
                        continuation.resume()
                    }
                }
            }
        }
    }

    private func updateTableView(datasource: [AnyHashable], selectIndex: Int, defaultSelectIndex: Int) {
        self.setValue(datasource, forKey: "datasource")
        self.tableView.reloadData()

        // Handle default selection
        if defaultSelectIndex >= 0 && defaultSelectIndex < datasource.count {
            self.arrayController.setSelectionIndex(defaultSelectIndex)
        } else if selectIndex >= 0 && selectIndex < datasource.count {
            self.arrayController.setSelectionIndex(selectIndex)
        } else {
            self.arrayController.setSelectionIndex(NSNotFound)
        }
    }

    func setupView() {
        self.view.translatesAutoresizingMaskIntoConstraints = false
    }

    func setupTableView() {
        self.view.addSubview(scrollView)
        self.scrollView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addConstraint(NSLayoutConstraint(item: self.scrollView, attribute: .left, relatedBy: .equal, toItem: self.view, attribute: .left, multiplier: 1.0, constant: 0))
        self.view.addConstraint(NSLayoutConstraint(item: self.scrollView, attribute: .top, relatedBy: .equal, toItem: self.view, attribute: .top, multiplier: 1.0, constant: 0))
        self.view.addConstraint(NSLayoutConstraint(item: self.scrollView, attribute: .right, relatedBy: .equal, toItem: self.view, attribute: .right, multiplier: 1.0, constant: 0))
        self.view.addConstraint(NSLayoutConstraint(item: self.scrollView, attribute: .bottom, relatedBy: .equal, toItem: self.view, attribute: .bottom, multiplier: 1.0, constant: 0))
        tableView.frame = scrollView.bounds
        tableView.delegate = self
        tableView.dataSource = self

        tableView.usesAlternatingRowBackgroundColors = true
        scrollView.backgroundColor = NSColor.clear
        scrollView.drawsBackground = false
        scrollView.autohidesScrollers = true
        scrollView.contentInsets = NSEdgeInsets(top: 0, left: -40, bottom: 0, right: 0)
        scrollView.scrollerInsets = NSEdgeInsets(top: 0, left: -40, bottom: 0, right: 0)

        tableView.style = .fullWidth
        tableView.backgroundColor = NSColor.clear
        tableView.columnAutoresizingStyle = .lastColumnOnlyAutoresizingStyle
        tableView.doubleAction = #selector(onDoubleAction(_:))

        for column in viewModel.columns {
            let col = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(rawValue: column.key))
            col.width = column.width ?? column.type.width
            col.title = column.title
            tableView.addTableColumn(col)
        }

        tableView.sizeLastColumnToFit()
        scrollView.documentView = tableView
        scrollView.hasHorizontalScroller = false
        scrollView.hasVerticalScroller = true

        // init context menu
        if !viewModel.contextMenus.isEmpty {
            let menu = NSMenu()
            viewModel.contextMenus.forEach { item in
                let menuItem = NSMenuItem(title: item.rawValue, action: #selector(contextMenuAction(_:)), keyEquivalent: item.ext.keyEquivalent)
                menu.addItem(menuItem)
            }
            tableView.menu = menu
        }
    }

    // MARK: - Key Events

    override func keyDown(with event: NSEvent) {
        let selectIndex = tableView.selectedRow
        if event.specialKey == NSEvent.SpecialKey.delete {
            logger.info("on delete key down, delete index: \(selectIndex)")
            if selectIndex > -1 {
                viewModel.delete(index: selectIndex)
            }
        } else if event.modifierFlags.intersection(.deviceIndependentFlagsMask) == .command {
            if event.charactersIgnoringModifiers == "c" {
                logger.info("on table keyboard event: copy, index: \(selectIndex)")
                if selectIndex > -1 {
                    viewModel.copy(index: selectIndex)
                }
            } else if event.charactersIgnoringModifiers == "e" {
                logger.info("on table keyboard event: edit, index: \(selectIndex)")
                if selectIndex > -1 {
                    viewModel.doubleClick(index: selectIndex)
                }
            }
        }
    }

    // MARK: - Double Click

    @objc private func onDoubleAction(_ sender: AnyObject) {
        logger.info("table view on double click action, row: \(tableView.clickedRow)")
        let selectIndex = tableView.clickedRow
        guard selectIndex > -1 && selectIndex < self.datasource.count else { return }
        viewModel.doubleClick(index: selectIndex)
    }

    // MARK: - Context Menu

    @objc private func contextMenuAction(_ sender: AnyObject) {
        guard let menuItem = sender as? NSMenuItem else { return }
        let index = tableView.clickedRow
        if index < 0 { return }
        logger.info("context menu action, menu: \(menuItem.title), index: \(index)")
        if menuItem.title == "Copy" {
            viewModel.copy(index: index)
        } else {
            viewModel.contextMenu(title: menuItem.title, index: index)
        }
    }
}

// MARK: - NSTableViewDelegate

extension NTableController: NSTableViewDelegate {

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let tableColumn = tableColumn else { return nil }
        guard let column = self.viewModel.columns.filter({ $0.key == tableColumn.identifier.rawValue }).first else { return nil }

        var tableCellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(column.key), owner: self) as? TableCellView
        if tableCellView == nil {
            tableCellView = TableCellView(tableView, tableColumn: tableColumn, column: column, row: row)
        }
        return tableCellView
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        guard let tableView = notification.object as? NSTableView else { return }
        let selectIndex = tableView.selectedRow
        let selectIndexes: [Int] = Array(tableView.selectedRowIndexes)
        self.logger.info("table selection did change, select index: \(selectIndex), indexes: \(selectIndexes)")
        DispatchQueue.main.async {
            self.viewModel.selectionChange(index: selectIndex, indexes: selectIndexes)
        }
    }
}

// MARK: - NSTableViewDataSource (Drag)

extension NTableController: NSTableViewDataSource {

    func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
        let rowAnyObj = self.viewModel.datasource[row]
        let value = "\(rowAnyObj.hashValue)"
        let pasteboardItem = NSPasteboardItem()
        pasteboardItem.setString(value, forType: pasteboardType)
        return pasteboardItem
    }

    func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
        return dropOperation == .above ? .move : []
    }

    func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
        guard
            let that = info.draggingPasteboard.pasteboardItems?.first,
            let theString = that.string(forType: pasteboardType),
            let originalRow = self.viewModel.datasource.firstIndex(where: { item in
                return "\(item.hashValue)" == theString
            })
        else { return false }

        if originalRow == row { return false }

        viewModel.dragComplete(from: originalRow, to: row)
        logger.info("drag complete, at: \(originalRow), to: \(row)")
        return true
    }
}
