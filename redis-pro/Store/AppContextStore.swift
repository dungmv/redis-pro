//
//  AppContextStore.swift
//  redis-pro
//
//  Created by chengpan on 2022/6/2.
//  Migrated to MVVM (Swift 6) — replaces TCA AppContextStore
//

import Logging
import Foundation
import Observation

private let logger = Logger(label: "app-context-store")

@MainActor
@Observable
final class AppContext {
    var loading: Bool = false
    var loadingCount: Int = 0

    private var hideTask: Task<Void, Never>?

    init() {
        logger.info("AppContext init ...")
    }

    func show() {
        if loadingCount <= 0 {
            loading = true
        }
        loadingCount += 1
    }

    func hide() {
        if loadingCount <= 0 {
            loading = false
            return
        }
        hideTask?.cancel()
        hideTask = Task {
            try? await Task.sleep(nanoseconds: 100_000_000)
            guard !Task.isCancelled else { return }
            _hide()
        }
    }

    private func _hide() {
        loadingCount -= 1
        if loadingCount <= 0 {
            loading = false
            loadingCount = 0
        }
    }
}
