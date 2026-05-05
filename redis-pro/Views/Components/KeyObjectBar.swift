//
//  KeyObjectBar.swift
//  redis-pro
//
//  Created by chengpan on 2023/7/30.
//  Migrated to MVVM (Swift 6)
//

import SwiftUI
import Logging

struct KeyObjectBar: View {
    @State var viewModel: KeyObjectViewModel
    let logger = Logger(label: "key-object-bar")

    var body: some View {
        FormText(label: "Object Encoding:", value: viewModel.encoding)
            .padding(EdgeInsets(top: 0, leading: MTheme.H_SPACING, bottom: 0, trailing: MTheme.H_SPACING))
    }
}
