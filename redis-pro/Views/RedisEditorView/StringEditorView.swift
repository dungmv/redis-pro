//
//  StringEditView.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/4/7.
//  Migrated to MVVM (Swift 6)
//

import SwiftUI
import Logging

enum StringViewMode: String, CaseIterable {
    case plain = "Plain Text"
    case json = "JSON"
}

struct StringEditorView: View {
    @State var viewModel: ValueViewModel
    @State private var viewMode: StringViewMode = .plain
    private let logger = Logger(label: "string-editor")

    var body: some View {
        let vm = viewModel.stringValue
        VStack(alignment: .leading, spacing: 0) {
            HighlightTextEditor(text: Binding(get: { vm.text }, set: { vm.text = $0 }), isJSON: viewMode == .json)
                .background(Color(NSColor.textBackgroundColor))

            // footer
            HStack(alignment: .center, spacing: 6) {
                KeyObjectBar(viewModel: viewModel.keyObject)

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

                Spacer()
                
                Picker("", selection: $viewMode) {
                    ForEach(StringViewMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 150)
                .onChange(of: viewMode) { oldValue, newValue in
                    // View mode change now handled internally by HighlightTextEditor for display
                }

                IconButton(icon: "arrow.clockwise", name: "Refresh", action: { vm.refresh() })
                IconButton(icon: "checkmark", name: "Submit", action: { vm.submit() })
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

struct HighlightTextEditor: NSViewRepresentable {
    @Binding var text: String
    var isJSON: Bool
    
    func formatJSON(_ val: String) -> String {
        if val.count < 2 {
            return val
        }
        guard let data = val.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data),
              let prettyData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
              let prettyString = String(data: prettyData, encoding: .utf8) else {
            return val
        }
        return prettyString
    }
    
    func minifyJSON(_ val: String) -> String {
        if val.count < 2 {
            return val
        }
        guard let data = val.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data),
              let minData = try? JSONSerialization.data(withJSONObject: json, options: []),
              let minString = String(data: minData, encoding: .utf8) else {
            return val
        }
        return minString
    }
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        let textView = scrollView.documentView as! NSTextView
        textView.delegate = context.coordinator
        textView.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isRichText = false
        textView.allowsUndo = true
        textView.backgroundColor = .clear
        textView.drawsBackground = false
        textView.textColor = .labelColor
        textView.isEditable = true
        textView.isSelectable = true
        
        // Setup text container
        textView.textContainerInset = NSSize(width: 0, height: 0)
        
        return scrollView
    }
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        let textView = nsView.documentView as! NSTextView
        let coordinator = context.coordinator
        
        let modeChanged = coordinator.lastIsJSON != isJSON
        coordinator.lastIsJSON = isJSON
        
        let displayString = isJSON ? formatJSON(text) : text
        
        // Only update if the string has actually changed or the mode changed
        if textView.string != displayString || modeChanged {
            let selectedRange = textView.selectedRange()
            
            coordinator.isUpdatingFromParent = true
            if isJSON {
                let highlighted = JSONHighlighter.highlightToNS(displayString)
                textView.textStorage?.setAttributedString(highlighted)
            } else {
                textView.string = displayString
                textView.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
                textView.textColor = .labelColor
            }
            coordinator.isUpdatingFromParent = false
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: HighlightTextEditor
        var lastIsJSON: Bool?
        var isUpdatingFromParent = false
        
        init(_ parent: HighlightTextEditor) {
            self.parent = parent
        }
        
        func textDidChange(_ notification: Notification) {
            guard !isUpdatingFromParent,
                  let textView = notification.object as? NSTextView else { return }
            
            if self.parent.text != textView.string {
                self.parent.text = textView.string
            }
        }
    }
}
