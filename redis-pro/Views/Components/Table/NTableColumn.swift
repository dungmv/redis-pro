//
//  NTableColumn.swift
//  redis-pro
//
//  Created by chengpan on 2022/3/27.
//  Migrated to SwiftUI Table — uses closure-based content instead of KVC key
//

import Foundation
import SwiftUI

struct NTableColumn<Item>: Identifiable {
    let id = UUID()
    var type: TableColumnType = .DEFAULT
    var title: String
    var width: CGFloat?
    var icon: TableIconEnum?
    var color: ((Item) -> Color)?
    var content: (Item) -> String

    init(
        type: TableColumnType = .DEFAULT,
        title: String,
        width: CGFloat? = nil,
        icon: TableIconEnum? = nil,
        color: ((Item) -> Color)? = nil,
        content: @escaping (Item) -> String
    ) {
        self.type = type
        self.title = title
        self.width = width
        self.icon = icon
        self.color = color
        self.content = content
    }
}

enum TableIconEnum {
    case APP

    var swiftUIImage: Image {
        switch self {
        case .APP:
            Image("icon-redis")
        }
    }
}
