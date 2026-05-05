//
//  LuaView.swift
//  redis-pro
//
//  Created by chengpan on 2022/7/17.
//  Migrated to MVVM (Swift 6)
//

import SwiftUI
import Logging

struct LuaView: View {
    @State var viewModel: LuaViewModel
    let logger = Logger(label: "lua-view")

    var body: some View {
        VStack(alignment: .leading, spacing: MTheme.V_SPACING) {

            // header
            HStack(alignment: .center, spacing: MTheme.H_SPACING) {
                Text("Eval Lua Script")
                Spacer()
                MButton(text: "Script Flush", action: { viewModel.scriptFlush() })
            }

            VSplitView {
                VStack(alignment: .leading, spacing: MTheme.V_SPACING) {
                    // text editor
                    MTextEditor(text: Binding(get: { viewModel.lua }, set: { viewModel.lua = $0 }))

                    // btns
                    HStack(alignment: .center, spacing: MTheme.H_SPACING) {
                        Spacer()
                        MButton(text: "Eval", action: { viewModel.eval() }, keyEquivalent: .return)
                    }
                    .padding(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))
                }

                MTextEditor(text: Binding(get: { viewModel.evalResult }, set: { viewModel.evalResult = $0 }))
            }
        }
    }
}
