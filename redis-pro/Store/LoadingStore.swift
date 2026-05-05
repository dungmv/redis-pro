//
//  LoadingStore.swift
//  redis-pro
//
//  Created by chengpan on 2022/5/3.
//  Migrated to MVVM (Swift 6)
//

import Logging
import Foundation
import Observation

private let logger = Logger(label: "loading-store")

@MainActor
@Observable
final class LoadingViewModel {
    var loading: Bool = false

    init() {
        logger.info("LoadingViewModel init ...")
    }

    func show() {
        loading = true
    }

    func hide() {
        loading = false
    }
}
