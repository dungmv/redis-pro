//
//  RedisProCommands.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/5/21.
//  Migrated to MVVM (Swift 6)
//

import SwiftUI
import Cocoa
import Logging

struct RedisProCommands: Commands {

    let logger = Logger(label: "commands")

    var body: some Commands {
        SidebarCommands()

        CommandGroup(replacing: CommandGroupPlacement.help) {
            CheckUpdateCommands()
            HomeCommands()
            AboutCommands()
        }
    }
}
