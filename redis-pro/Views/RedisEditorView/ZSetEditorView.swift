//
//  ZSetEditorView.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/5/7.
//  Migrated to MVVM (Swift 6)
//

import SwiftUI
import Logging

struct ZSetEditorView: View {
    @State var viewModel: ValueViewModel
    let logger = Logger(label: "redis-zset-editor")

    var body: some View {
        let vm = viewModel.zsetValue
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 4) {
                IconButton(icon: "plus", name: "Add", action: { vm.addNew() })

                SearchBar(placeholder: "Search element...", onCommit: { vm.search($0) })
                PageBar(viewModel: vm.page)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)

            NTableView(viewModel: vm.table)

            // footer
            HStack(alignment: .center, spacing: 0) {
                KeyObjectBar(viewModel: viewModel.keyObject)
                Spacer()
                IconButton(icon: "arrow.clockwise", name: "Refresh", action: { vm.refresh() })
                    .padding(.trailing, 8)
            }
            .frame(height: 30)
            .glassFooter()
        }
        .sheet(isPresented: Binding(get: { vm.editModalVisible }, set: { vm.editModalVisible = $0 })) {
            ModalView("Edit zset element", action: { vm.submit() }) {
                VStack(alignment: .leading, spacing: 6) {
                    FormItemDouble(
                        label: "Score", placeholder: "score",
                        value: Binding(get: { vm.editScore }, set: { vm.editScore = $0 })
                    )
                    FormItemTextArea(
                        label: "Value", placeholder: "value",
                        value: Binding(get: { vm.editValue }, set: { vm.editValue = $0 })
                    )
                }
            }
        }
        .sheet(isPresented: Binding(get: { vm.geoModalVisible }, set: { vm.geoModalVisible = $0 })) {
            ModalView("Geo Position", width: 480, height: 320, action: {  }) {
                VStack(alignment: .leading, spacing: LiquidGlass.spacing20) {
                    // Metadata Group
                    VStack(alignment: .leading, spacing: LiquidGlass.spacing8) {
                        HStack(spacing: LiquidGlass.spacing8) {
                            Image(systemName: "key.fill")
                                .foregroundStyle(.secondary)
                                .font(.system(size: 10))
                            Text("Key")
                                .font(LiquidGlass.fontLabel)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(viewModel.keyObject.key)
                                .font(LiquidGlass.fontMono)
                                .textSelection(.enabled)
                        }
                        
                        HStack(spacing: LiquidGlass.spacing8) {
                            Image(systemName: "person.fill")
                                .foregroundStyle(.secondary)
                                .font(.system(size: 10))
                            Text("Member")
                                .font(LiquidGlass.fontLabel)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(vm.geoMember)
                                .font(LiquidGlass.fontMono)
                                .textSelection(.enabled)
                        }
                    }
                    .padding(LiquidGlass.spacing12)
                    .background(LiquidGlass.glassSurface, in: RoundedRectangle(cornerRadius: LiquidGlass.radiusMD))
                    .overlay(RoundedRectangle(cornerRadius: LiquidGlass.radiusMD).strokeBorder(LiquidGlass.glassBorder, lineWidth: 0.5))

                    // Coordinates Group
                    HStack(spacing: LiquidGlass.spacing12) {
                        CoordinateBox(label: "LATITUDE", value: vm.geoLat, icon: "scope")
                        CoordinateBox(label: "LONGITUDE", value: vm.geoLng, icon: "scope")
                    }
                }
                .padding(.vertical, LiquidGlass.spacing8)
            }
        }
    }
}

private struct CoordinateBox: View {
    let label: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: LiquidGlass.spacing6) {
            HStack {
                Text(label)
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1)
                    .foregroundStyle(.secondary.opacity(0.8))
                Spacer()
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundStyle(LiquidGlass.typeColor(for: "ZSET"))
            }
            
            Text(value)
                .font(.system(size: 16, weight: .semibold, design: .monospaced))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .textSelection(.enabled)
            
            Button(action: { PasteboardHelper.copy(value) }) {
                HStack(spacing: 4) {
                    Image(systemName: "doc.on.doc")
                    Text("Copy")
                }
                .font(.system(size: 10, weight: .medium))
            }
            .buttonStyle(.plain)
            .foregroundStyle(LiquidGlass.typeColor(for: "ZSET"))
            .hoverEffect()
        }
        .padding(LiquidGlass.spacing12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: LiquidGlass.radiusLG)
                .fill(LiquidGlass.typeColor(for: "ZSET").opacity(0.08))
        }
        .overlay {
            RoundedRectangle(cornerRadius: LiquidGlass.radiusLG)
                .strokeBorder(LiquidGlass.typeColor(for: "ZSET").opacity(0.15), lineWidth: 1)
        }
    }
}
