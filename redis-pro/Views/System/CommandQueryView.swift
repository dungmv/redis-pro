//
//  CommandQueryView.swift
//  redis-pro
//
//  Created by Antigravity on 2026-06-02.
//

import SwiftUI
import AppKit

// MARK: - Redis Syntax Highlighter
enum RedisHighlighter {
    private static let commandColor = NSColor(red: 0.15, green: 0.45, blue: 0.82, alpha: 1.0) // Bold blue
    private static let stringColor = NSColor(red: 0.13, green: 0.60, blue: 0.35, alpha: 1.0) // Green
    private static let numberColor = NSColor(red: 0.82, green: 0.45, blue: 0.13, alpha: 1.0) // Orange/Brown
    private static let commentColor = NSColor.secondaryLabelColor // Grey
    
    // Set of common Redis/Valkey commands for syntax highlighting and autocomplete
    static let redisCommands: Set<String> = [
        "ping", "echo", "set", "get", "del", "exists", "keys", "scan", "ttl", "expire",
        "incr", "decr", "incrby", "decrby", "hset", "hget", "hdel", "hgetall", "hkeys", "hvals",
        "lpush", "rpush", "lpop", "rpop", "lrange", "llen", "ltrim", "sadd", "sismember",
        "smembers", "srem", "sunion", "sinter", "sdiff", "zadd", "zrange", "zrevrange", "zrem",
        "zscore", "zcard", "zrangebyscore", "multi", "exec", "discard", "watch", "unwatch",
        "publish", "subscribe", "psubscribe", "config", "info", "client", "slowlog", "eval", "evalsha",
        "script", "flushdb", "flushall", "dbsize", "select", "auth", "quit"
    ]
    
    static func highlight(_ text: String) -> NSAttributedString {
        let nsAttr = NSMutableAttributedString(string: text)
        let fullRange = NSRange(location: 0, length: text.utf16.count)
        
        // Default style (monospace font and default label color)
        nsAttr.addAttribute(.font, value: NSFont.monospacedSystemFont(ofSize: 13, weight: .regular), range: fullRange)
        nsAttr.addAttribute(.foregroundColor, value: NSColor.labelColor, range: fullRange)
        
        let nsString = text as NSString
        
        // 1. Highlight Comments (# or //)
        let commentRegex = try! NSRegularExpression(pattern: "(?m)^\\s*(#|//).*$", options: [])
        commentRegex.enumerateMatches(in: text, options: [], range: fullRange) { match, _, _ in
            if let range = match?.range {
                nsAttr.addAttribute(.foregroundColor, value: commentColor, range: range)
            }
        }
        
        // 2. Highlight Strings (single or double quotes)
        let stringRegex = try! NSRegularExpression(pattern: "\"([^\"]*)\"|'([^']*)'", options: [])
        stringRegex.enumerateMatches(in: text, options: [], range: fullRange) { match, _, _ in
            if let range = match?.range {
                nsAttr.addAttribute(.foregroundColor, value: stringColor, range: range)
            }
        }
        
        // 3. Highlight Numbers
        let numberRegex = try! NSRegularExpression(pattern: "\\b\\d+(\\.\\d+)?\\b", options: [])
        numberRegex.enumerateMatches(in: text, options: [], range: fullRange) { match, _, _ in
            if let range = match?.range {
                let color = nsAttr.attribute(.foregroundColor, at: range.location, effectiveRange: nil) as? NSColor
                if color != commentColor && color != stringColor {
                    nsAttr.addAttribute(.foregroundColor, value: numberColor, range: range)
                }
            }
        }
        
        // 4. Highlight Redis Commands
        let wordRegex = try! NSRegularExpression(pattern: "\\b\\w+\\b", options: [])
        wordRegex.enumerateMatches(in: text, options: [], range: fullRange) { match, _, _ in
            if let range = match?.range {
                let word = nsString.substring(with: range).lowercased()
                if redisCommands.contains(word) {
                    let color = nsAttr.attribute(.foregroundColor, at: range.location, effectiveRange: nil) as? NSColor
                    if color != commentColor && color != stringColor {
                        nsAttr.addAttribute(.foregroundColor, value: commandColor, range: range)
                    }
                }
            }
        }
        
        return nsAttr
    }
}

// MARK: - Command Query Main View
struct CommandQueryView: View {
    @State var viewModel: CommandQueryViewModel
    
    var body: some View {
        VSplitView {
            VStack(alignment: .leading, spacing: 0) {
                CommandQueryTextEditor(text: $viewModel.queryText, selectedCommand: $viewModel.selectedCommand) { cmd in
                    viewModel.executeCommand(cmd)
                }
                .background(Color(NSColor.textBackgroundColor))
            }
            .frame(minHeight: 120, maxHeight: .infinity)
            
            VStack(alignment: .leading, spacing: 0) {
                // Divider / status bar
                HStack(spacing: 8) {
                    Image(systemName: "terminal")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                    
                    Text(viewModel.selectedCommand.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "0 commands selected" : "1 command selected")
                        .font(.system(.subheadline))
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Button(action: {
                        viewModel.executeCommand(viewModel.selectedCommand)
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 10))
                            Text("Execute Selected")
                            Text("⌘↩")
                                .font(.system(.caption, design: .monospaced))
                                .opacity(0.8)
                        }
                    }
                    .keyboardShortcut(.return, modifiers: .command)
                    .disabled(viewModel.selectedCommand.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isExecuting)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.thinMaterial)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(Color(NSColor.separatorColor))
                        .frame(height: 0.5)
                }
                
                // Console Output
                ScrollView {
                    ScrollViewReader { proxy in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(viewModel.outputText.isEmpty ? "Console ready. Type a command and press Cmd+Enter to execute." : viewModel.outputText)
                                .font(.system(.body, design: .monospaced))
                                .foregroundStyle(viewModel.outputText.isEmpty ? .secondary : .primary)
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(10)
                                .id("output-bottom")
                        }
                        .onChange(of: viewModel.outputText) { _, _ in
                            withAnimation {
                                proxy.scrollTo("output-bottom", anchor: .bottom)
                            }
                        }
                    }
                }
                .background(Color(NSColor.textBackgroundColor))
                
                // Bottom actions
                Divider()
                HStack {
                    Button(action: {
                        viewModel.clearOutput()
                    }) {
                        Label("Clear Console", systemImage: "trash")
                            .font(.system(.subheadline))
                    }
                    .buttonStyle(.plain)
                    .help("Clear Console Output")
                    
                    Spacer()
                    
                    Button(action: {
                        exportConsole()
                    }) {
                        Label("Export...", systemImage: "square.and.arrow.up")
                            .font(.system(.subheadline))
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.outputText.isEmpty)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.thinMaterial)
            }
            .frame(minHeight: 180, maxHeight: .infinity)
        }
    }
    
    private func exportConsole() {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.plainText]
        savePanel.nameFieldStringValue = "redis_command_output.txt"
        savePanel.isExtensionHidden = false
        
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                do {
                    try viewModel.outputText.write(to: url, atomically: true, encoding: .utf8)
                } catch {
                    Messages.show(error)
                }
            }
        }
    }
}

// MARK: - Command Query Text Editor (NSViewRepresentable)
struct CommandQueryTextEditor: NSViewRepresentable {
    @Binding var text: String
    @Binding var selectedCommand: String
    var onExecute: (String) -> Void
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        let textView = CommandQueryInternalTextView()
        textView.onExecute = { [weak textView] in
            guard let textView = textView else { return }
            
            let string = textView.string
            let selectedRange = textView.selectedRange()
            let commandToExecute: String
            
            if selectedRange.length > 0 {
                commandToExecute = (string as NSString).substring(with: selectedRange)
            } else {
                let nsString = string as NSString
                let lineRange = nsString.lineRange(for: NSRange(location: selectedRange.location, length: 0))
                commandToExecute = nsString.substring(with: lineRange)
            }
            
            let trimmed = commandToExecute.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                onExecute(trimmed)
            }
        }
        
        scrollView.documentView = textView
        
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
        textView.textContainerInset = NSSize(width: 8, height: 8)
        
        // Initial highlighting
        let highlighted = RedisHighlighter.highlight(text)
        textView.textStorage?.setAttributedString(highlighted)
        
        return scrollView
    }
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        let textView = nsView.documentView as! NSTextView
        let coordinator = context.coordinator
        
        if textView.string != text {
            coordinator.isUpdating = true
            let selectedRange = textView.selectedRange()
            let highlighted = RedisHighlighter.highlight(text)
            textView.textStorage?.setAttributedString(highlighted)
            if selectedRange.location <= highlighted.length {
                textView.setSelectedRange(selectedRange)
            }
            coordinator.isUpdating = false
            
            // Initial update of selectedCommand if empty
            if selectedCommand.isEmpty {
                coordinator.updateSelectedCommand(textView)
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: CommandQueryTextEditor
        var isUpdating = false
        var isDeleting = false
        
        init(_ parent: CommandQueryTextEditor) {
            self.parent = parent
        }
        
        // Track whether text was deleted to avoid popping autocomplete lists on backspace
        func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool {
            if let rep = replacementString, rep.isEmpty {
                isDeleting = true
            } else {
                isDeleting = false
            }
            return true
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView, !isUpdating else { return }
            
            isUpdating = true
            let selectedRange = textView.selectedRange()
            let highlighted = RedisHighlighter.highlight(textView.string)
            textView.textStorage?.setAttributedString(highlighted)
            if selectedRange.location <= highlighted.length {
                textView.setSelectedRange(selectedRange)
            }
            
            if parent.text != textView.string {
                parent.text = textView.string
            }
            isUpdating = false
            
            updateSelectedCommand(textView)
            
            // Autocomplete if user is typing forward
            if !isDeleting {
                triggerAutocomplete(textView)
            }
        }
        
        private func triggerAutocomplete(_ textView: NSTextView) {
            let selectedRange = textView.selectedRange()
            guard selectedRange.length == 0 && selectedRange.location > 0 else { return }
            
            let nsString = textView.string as NSString
            let char = nsString.substring(with: NSRange(location: selectedRange.location - 1, length: 1))
            
            // Only trigger autocomplete when typing letters
            guard CharacterSet.letters.contains(UnicodeScalar(char) ?? UnicodeScalar(0)) else { return }
            
            // Only trigger if the current word (up to cursor) has no spaces before it on the same line
            // i.e., we are typing the first word (command) on the line
            let lineRange = nsString.lineRange(for: NSRange(location: selectedRange.location, length: 0))
            let lineUpToCursor = nsString.substring(with: NSRange(location: lineRange.location, length: selectedRange.location - lineRange.location))
            let wordPart = lineUpToCursor.trimmingCharacters(in: .init(charactersIn: "# "))
            // If there is a space in the trimmed prefix, the user is typing an argument — skip autocomplete
            if wordPart.contains(" ") || wordPart.contains("\t") { return }
            
            DispatchQueue.main.async {
                if textView.window?.firstResponder == textView {
                    textView.complete(nil)
                }
            }
        }
        
        // Autocomplete list completions
        func textView(_ textView: NSTextView, completions words: [String], forPartialWordRange charRange: NSRange, indexOfSelectedItem index: UnsafeMutablePointer<Int>?) -> [String] {
            let nsString = textView.string as NSString
            let partialWord = nsString.substring(with: charRange).lowercased()
            guard !partialWord.isEmpty else { return [] }
            
            // Only offer completions when partial word is at the start of a command line (no preceding content on line)
            let cursorLocation = charRange.location
            let lineRange = nsString.lineRange(for: NSRange(location: cursorLocation, length: 0))
            let linePrefix = nsString.substring(with: NSRange(location: lineRange.location, length: cursorLocation - lineRange.location))
            let trimmedPrefix = linePrefix.trimmingCharacters(in: .whitespaces)
            // If there's already a word with a space before partial word, user is typing an argument
            if trimmedPrefix.contains(" ") || trimmedPrefix.contains("\t") { return [] }
            
            let matches = RedisHighlighter.redisCommands.filter { $0.hasPrefix(partialWord) }.sorted()
            if !matches.isEmpty {
                // Do not pre-select any item — let user manually pick
                index?.pointee = -1
                return matches
            }
            return []
        }
        
        func textViewDidChangeSelection(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            updateSelectedCommand(textView)
        }
        
        func updateSelectedCommand(_ textView: NSTextView) {
            let string = textView.string
            let selectedRange = textView.selectedRange()
            let commandToExecute: String
            
            if selectedRange.length > 0 {
                commandToExecute = (string as NSString).substring(with: selectedRange)
            } else {
                let nsString = string as NSString
                let lineRange = nsString.lineRange(for: NSRange(location: selectedRange.location, length: 0))
                commandToExecute = nsString.substring(with: lineRange)
            }
            
            if parent.selectedCommand != commandToExecute {
                parent.selectedCommand = commandToExecute
            }
        }
    }
}

class CommandQueryInternalTextView: NSTextView {
    var onExecute: (() -> Void)?
    
    override func keyDown(with event: NSEvent) {
        let modifierFlags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        if modifierFlags == .command && (event.keyCode == 36 || event.keyCode == 76) {
            onExecute?()
            return
        }
        super.keyDown(with: event)
    }
    
    // Allow Esc to cancel autocomplete popup
    override func cancelOperation(_ sender: Any?) {
        // If the completion popup is visible, dismiss it by calling complete with a non-nil sender
        // which cancels the current completion session
        if NSApp.keyWindow?.firstResponder == self {
            // Dismiss completion list if shown
            let event = NSApp.currentEvent
            if event?.keyCode == 53 { // Esc key
                self.complete(self) // calling with non-nil cancels completion
                return
            }
        }
        super.cancelOperation(sender)
    }
}
