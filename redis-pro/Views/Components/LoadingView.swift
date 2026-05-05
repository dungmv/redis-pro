//
//  NLoading.swift
//  redis-pro
//
//  Created by chengpan on 2022/5/3.
//  Migrated to MVVM (Swift 6)
//

import Logging
import SwiftUI

struct LoadingView: View {
    private let logger = Logger(label: "loading-view")

    @State var viewModel: AppContext

    var body: some View {
        HStack {
            EmptyView()
        }
        .frame(height: 0)
        .overlay(MSpin(loading: viewModel.loading))
    }
}
