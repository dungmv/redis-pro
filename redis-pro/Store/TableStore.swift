//
//  TableStore.swift
//  redis-pro
//
//  Created by chengpan on 2022/4/30.
//  Migrated to MVVM (Swift 6)
//

import Logging
import Foundation
import Observation
import SwiftUI

private let logger = Logger(label: "table-store")

@MainActor
@Observable
final class TableViewModel<Item: Identifiable & Sendable> {
    var columns: [NTableColumn<Item>]
    var datasource: [Item]
    var selectIndex: Int
    var selectIndexes: [Int]
    var defaultSelectIndex: Int
    var dragable: Bool
    var multiSelect: Bool

    var isEmpty: Bool { datasource.isEmpty }
    var isSelect: Bool { selectIndex > -1 }

    var onSelectionChange: ((Int, [Int]) -> Void)?
    var onDouble: ((Int) -> Void)?
    var onDelete: ((Int) -> Void)?
    var onCopy: ((Int) -> Void)?
    var onDragComplete: ((Int, Int) -> Void)?

    init(
        columns: [NTableColumn<Item>] = [],
        datasource: [Item] = [],
        selectIndex: Int = -1,
        defaultSelectIndex: Int = -1,
        dragable: Bool = false,
        multiSelect: Bool = false
    ) {
        self.columns = columns
        self.datasource = datasource
        self.selectIndex = selectIndex
        self.selectIndexes = []
        self.defaultSelectIndex = defaultSelectIndex
        self.dragable = dragable
        self.multiSelect = multiSelect
        logger.info("TableViewModel init")
    }

    func setDatasource(_ newDatasource: [Item]) {
        datasource = newDatasource
        selectIndex = min(selectIndex, datasource.count - 1)
    }
    
    func setSelectIndex(_ index: Int) {
        selectIndex = min(index, datasource.count - 1)
    }
    
    func reset() {
        selectIndex = -1
        selectIndexes = []
        datasource = []
    }
    
    func selectionChange(index: Int, indexes: [Int]) {
        logger.info("table selection change, index: \(index)")
        selectIndex = index
        selectIndexes = indexes
        onSelectionChange?(index, indexes)
    }

    func doubleClick(index: Int) {
        logger.info("table double click, index: \(index)")
        onDouble?(index)
    }

    func delete(index: Int) {
        logger.info("table delete, index: \(index)")
        onDelete?(index)
    }

    func copy(index: Int) {
        logger.info("table copy, index: \(index)")
        onCopy?(index)
    }

    func dragComplete(from: Int, to: Int) {
        let f = datasource[from]
        datasource.remove(at: from)
        if from > to {
            datasource.insert(f, at: to)
            selectIndex = to
        } else {
            datasource.insert(f, at: to - 1)
            selectIndex = to - 1
        }
        onDragComplete?(from, to)
    }
}
