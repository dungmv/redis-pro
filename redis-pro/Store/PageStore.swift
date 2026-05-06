//
//  PageStore.swift
//  redis-pro
//
//  Created by chengpanwang on 2022/5/6.
//  Migrated to MVVM (Swift 6)
//

import Logging
import Foundation
import Observation

private let logger = Logger(label: "page-store")

@MainActor
@Observable
final class PageViewModel {
    var showTotal: Bool = false
    var current: Int = 1
    var size: Int = 50
    var total: Int = 0
    var keywords: String = ""
    var fastPage: Bool = true
    var fastPageMax: Int = 99

    // Callbacks replacing TCA action propagation
    var onNextPage: (() -> Void)?
    var onPrevPage: (() -> Void)?
    var onUpdateSize: (() -> Void)?

    var totalPage: Int {
        total < 1 ? 1 : (total % size == 0 ? total / size : total / size + 1)
    }

    var totalPageText: String {
        if fastPage {
            return totalPage > fastPageMax ? "\(fastPageMax)+" : "\(totalPage)"
        }
        return "\(totalPage)"
    }

    var hasPrev: Bool { totalPage > 1 && current > 1 }
    var hasNext: Bool { totalPage > 1 && current < totalPage }

    var page: Page {
        get {
            var page = Page()
            page.current = current
            page.size = size
            page.total = total
            page.keywords = keywords
            return page
        }
        set(page) {
            current = page.current
            size = page.size
            total = page.total
        }
    }

    init() {
        logger.info("PageViewModel init ...")
    }

    func nextPage() {
        current += 1
        onNextPage?()
    }

    func prevPage() {
        current -= 1
        if current <= 1 { current = 1 }
        onPrevPage?()
    }

    func updateSize(_ newSize: Int) {
        current = 1
        size = newSize
        onUpdateSize?()
    }
}
