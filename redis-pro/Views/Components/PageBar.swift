//
//  PageBar.swift
//  redis-pro
//
//  Liquid Glass pagination controls.
//  Migrated to MVVM (Swift 6)
//

import SwiftUI

struct PageBar: View {
    @State var viewModel: PageViewModel

    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            if viewModel.showTotal {
                Text("Total: \(viewModel.total)")
                    .font(LiquidGlass.FONT_FOOTER)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Picker("", selection: Binding(
                get: { viewModel.size },
                set: { viewModel.updateSize($0) }
            )) {
                Text("10").tag(10)
                Text("50").tag(50)
                Text("100").tag(100)
                Text("200").tag(200)
            }
            .pickerStyle(.menu)
            .frame(width: 60)
            .labelsHidden()

            HStack(spacing: 6) {
                MIcon(icon: "chevron.left", fontSize: 10, disabled: !viewModel.hasPrev) {
                    viewModel.prevPage()
                }

                Text("\(viewModel.current)/\(viewModel.totalPageText)")
                    .font(LiquidGlass.FONT_FOOTER)
                    .foregroundStyle(.secondary)
                    .frame(minWidth: 36)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)

                MIcon(icon: "chevron.right", fontSize: 10, disabled: !viewModel.hasNext) {
                    viewModel.nextPage()
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .glassCard(cornerRadius: LiquidGlass.radiusLG)
    }
}
