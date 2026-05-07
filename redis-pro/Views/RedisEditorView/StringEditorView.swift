//
//  StringEditView.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/4/7.
//  Migrated to MVVM (Swift 6)
//

import SwiftUI
import Logging

struct StringEditorView: View {
    @State var viewModel: ValueViewModel
    @State private var showHighlightedPreview: Bool = false
    private let logger = Logger(label: "string-editor")

    var body: some View {
        let vm = viewModel.stringValue
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                if showHighlightedPreview {
                    ScrollView {
                        Text(JSONHighlighter.highlight(vm.text))
                            .font(.body.monospaced())
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
                    }
                    .background(Color(NSColor.textBackgroundColor))
                } else {
                    MTextEditor(text: Binding(get: { vm.text }, set: { vm.text = $0 }))
                }
            }
            .padding(.horizontal, 10)
            .padding(.top, 6)
            .background(Color(NSColor.textBackgroundColor))

            // footer
            HStack(alignment: .center, spacing: 6) {
                KeyObjectBar(viewModel: viewModel.keyObject)

                if vm.isIntactString {
                    HStack(spacing: 8) {
                        HStack(spacing: 4) {
                            Image(systemName: "text.alignleft")
                                .font(.system(size: 11, weight: .medium))
                            Text("Length")
                                .font(.subheadline.weight(.medium))
                        }
                        .foregroundColor(.secondary)
                        
                        Text("\(vm.length)")
                            .font(.callout.monospaced())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Color.primary.opacity(0.06))
                            )
                            .overlay(
                                Capsule()
                                    .strokeBorder(Color.primary.opacity(0.1), lineWidth: 0.5)
                            )
                            .foregroundColor(.primary)
                    }
                } else {
                    Text("Range: 0~\(vm.stringMaxLength + 1) / \(vm.length)")
                    MButton(text: "Show Intact", action: { vm.getIntactString() })
                }

                Spacer()
                Menu("Format", content: {
                    Button("Json Pretty", action: { vm.jsonPretty() })
                    Button("Json Minify", action: { vm.jsonMinify() })
                })
                .frame(width: 80)
                Toggle(isOn: $showHighlightedPreview) {
                    Image(systemName: "paintpalette")
                }
                .toggleStyle(.button)
                .help("Toggle JSON syntax highlighting preview")
                IconButton(icon: "arrow.clockwise", name: "Refresh", action: { vm.refresh() })
                IconButton(icon: "checkmark", name: "Submit", disabled: !vm.isIntactString, action: { vm.submit() })
                    .padding(.trailing, 8)
            }
            .frame(height: 30)
            .glassFooter()
        }
        .onAppear {
            logger.info("redis string value editor view appear ...")
        }
    }
}
