//
//  DatabasePicker.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/5/10.
//  Migrated to MVVM (Swift 6)
//

import SwiftUI

struct DatabasePicker: View {

    @State var viewModel: DatabaseViewModel

    var body: some View {
        Menu(content: {
            ForEach(0 ..< viewModel.databases, id: \.self) { item in
                Button("DB\(item)", action: { viewModel.selectDB(item) })
                    .font(.system(size: 10.0))
                    .foregroundColor(.primary)
            }
        }, label: {
            MLabel(name: "DB\(viewModel.database)", icon: "cylinder.split.1x2").font(.system(size: 8))
        })
        .scaleEffect(0.9)
        .frame(width: 56)
        .menuStyle(BorderlessButtonMenuStyle())
        .onAppear {
            viewModel.initial()
        }
    }
}
