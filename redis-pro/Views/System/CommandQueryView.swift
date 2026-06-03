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
    
    static func highlight(_ text: String, commands: Set<String>? = nil) -> NSAttributedString {
        let nsAttr = NSMutableAttributedString(string: text)
        let fullRange = NSRange(location: 0, length: text.utf16.count)
        
        // Default style (monospace font and default label color)
        nsAttr.addAttribute(.font, value: NSFont.monospacedSystemFont(ofSize: 13, weight: .regular), range: fullRange)
        nsAttr.addAttribute(.foregroundColor, value: NSColor.labelColor, range: fullRange)
        
        let nsString = text as NSString
        let cmds = commands ?? redisCommands  // fall back to built-in list
        
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
                if cmds.contains(word) {
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
    
    /// Number of non-empty whitespace-separated tokens on the current editor line.
    private var typedTokenCount: Int {
        let line = viewModel.selectedCommand
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !line.isEmpty,
              !line.hasPrefix("#"),
              !line.hasPrefix("//") else { return 0 }
        return line.components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
            .count
    }
    
    /// True when the current line ends with whitespace, meaning the user has finished
    /// typing the last token and is ready to start the next argument.
    private var hasTrailingSpace: Bool {
        // Use selectedCommand before trimming newlines only — preserve trailing spaces
        let line = viewModel.selectedCommand
            .trimmingCharacters(in: .newlines)
        guard !line.isEmpty else { return false }
        return line.last?.isWhitespace == true
    }
    
    var body: some View {
        HSplitView {
            // ── Left: Editor + Console ──────────────────────────────────
            VSplitView {
                VStack(alignment: .leading, spacing: 0) {
                    CommandQueryTextEditor(
                        text: $viewModel.queryText,
                        selectedCommand: $viewModel.selectedCommand,
                        commandNames: viewModel.commandNames,
                        argCompletions: { cmd in viewModel.argCompletions(for: cmd) }
                    ) { cmd in
                        viewModel.executeCommand(cmd)
                    }
                    .background(Color(NSColor.textBackgroundColor))
                    
                    // ── Syntax Hint Bar ─────────────────────────────────
                    if let doc = viewModel.commandDoc, !doc.arguments.isEmpty {
                        CommandSyntaxHintBar(
                            doc: doc,
                            typedTokenCount: typedTokenCount,
                            hasTrailingSpace: hasTrailingSpace
                        )
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .frame(minHeight: 120, maxHeight: .infinity)
                
                VStack(alignment: .leading, spacing: 0) {
                    // Status bar
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
                        
                        Divider().frame(height: 16)
                        
                        // Toggle docs sidebar button
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.showDocsSidebar.toggle()
                            }
                        }) {
                            Image(systemName: "sidebar.right")
                                .font(.system(size: 13))
                                .foregroundStyle(viewModel.showDocsSidebar ? Color.accentColor : Color.secondary)
                        }
                        .buttonStyle(.plain)
                        .help(viewModel.showDocsSidebar ? "Hide Command Docs" : "Show Command Docs")
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
            .frame(minWidth: 340)
            
            // ── Right: Command Docs Sidebar ─────────────────────────────
            if viewModel.showDocsSidebar {
                CommandDocSidebarView(viewModel: viewModel)
                    .frame(minWidth: 300, idealWidth: 380)
            }
        }
        .onChange(of: viewModel.currentDocCommand) { _, newCmd in
            viewModel.fetchCommandDocs(newCmd)
        }
        .onAppear {
            viewModel.fetchCommandList()
            if !viewModel.currentDocCommand.isEmpty {
                viewModel.fetchCommandDocs(viewModel.currentDocCommand)
            }
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

// MARK: - Command Docs Sidebar
struct CommandDocSidebarView: View {
    let viewModel: CommandQueryViewModel
    
    private var docsPageURL: URL? {
        let base = "https://redis.io/docs/latest/commands/"
        let cmd = viewModel.currentDocCommand
        return URL(string: cmd.isEmpty ? base : base + cmd)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 6) {
                Image(systemName: "book.closed")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                Text(viewModel.currentDocCommand.isEmpty
                     ? "Command Docs"
                     : viewModel.currentDocCommand.uppercased())
                    .font(.system(.subheadline, weight: .semibold))
                    .foregroundStyle(viewModel.currentDocCommand.isEmpty ? .secondary : .primary)
                Spacer()
                if let url = docsPageURL {
                    Link(destination: url) {
                        Image(systemName: "arrow.up.right.square")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    .help("Open docs in browser")
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(.thinMaterial)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(Color(NSColor.separatorColor))
                    .frame(height: 0.5)
            }
            
            // Content
            Group {
                if viewModel.isLoadingDoc {
                    VStack(spacing: 8) {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .controlSize(.small)
                        Text("Loading docs...")
                            .font(.system(.caption))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let doc = viewModel.commandDoc {
                    CommandDocContentView(doc: doc)
                } else if let err = viewModel.docError {
                    VStack(spacing: 8) {
                        Image(systemName: "exclamationmark.circle")
                            .font(.system(size: 26))
                            .foregroundStyle(.secondary)
                        Text(err)
                            .font(.system(.callout))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "text.cursor")
                            .font(.system(size: 30))
                            .foregroundStyle(.secondary.opacity(0.4))
                        Text("Place cursor on a command\nto view its documentation")
                            .font(.system(.callout))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// MARK: - Native doc content
struct CommandDocContentView: View {
    let doc: CommandDoc
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                
                // Command name
                Text(doc.name.uppercased())
                    .font(.system(.title2, design: .monospaced, weight: .bold))
                    .textSelection(.enabled)
                
                // Deprecated badge
                if doc.docFlags.contains("deprecated") {
                    Label("Deprecated", systemImage: "exclamationmark.triangle.fill")
                        .font(.system(.caption, weight: .medium))
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Color.orange.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                }
                
                // Summary
                if !doc.summary.isEmpty {
                    Text(doc.summary)
                        .font(.system(.body))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .textSelection(.enabled)
                }
                
                // Group + Since badges
                HStack(spacing: 6) {
                    if !doc.group.isEmpty {
                        Text(doc.group.replacingOccurrences(of: "_", with: " ").capitalized)
                            .font(.system(.caption2, weight: .semibold))
                            .foregroundStyle(Color.accentColor)
                            .padding(.horizontal, 6).padding(.vertical, 3)
                            .background(Color.accentColor.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    if !doc.since.isEmpty {
                        Text("Since v\(doc.since)")
                            .font(.system(.caption2, weight: .medium))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 6).padding(.vertical, 3)
                            .background(Color(NSColor.controlBackgroundColor))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                }
                
                // Complexity
                if !doc.complexity.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Complexity", systemImage: "clock")
                            .font(.system(.caption, weight: .semibold))
                            .foregroundStyle(.secondary)
                        Text(doc.complexity)
                            .font(.system(.caption, design: .monospaced))
                            .fixedSize(horizontal: false, vertical: true)
                            .textSelection(.enabled)
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(NSColor.controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 7))
                }
                
                // Arguments
                if !doc.arguments.isEmpty {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("ARGUMENTS")
                            .font(.system(.caption2, weight: .bold))
                            .foregroundStyle(.secondary)
                            .kerning(1)
                            .padding(.bottom, 2)
                        ForEach(doc.arguments) { arg in
                            CommandArgRow(arg: arg, indent: 0)
                        }
                    }
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Argument row
struct CommandArgRow: View {
    let arg: CommandArgDoc
    let indent: Int
    
    private var typeColor: Color {
        switch arg.type {
        case "key":        return .green
        case "integer", "double": return .orange
        case "pure-token": return Color.accentColor
        case "oneof":      return .purple
        case "block":      return .indigo
        default:           return .secondary
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 4) {
                if let tok = arg.token {
                    Text(tok)
                        .font(.system(.caption, design: .monospaced, weight: .bold))
                        .foregroundStyle(Color.accentColor)
                        .textSelection(.enabled)
                }
                Text(arg.displayText.isEmpty ? arg.name : arg.displayText)
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)
                Spacer()
                Text(arg.type)
                    .font(.system(.caption2))
                    .foregroundStyle(typeColor)
                    .padding(.horizontal, 5).padding(.vertical, 2)
                    .background(typeColor.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 3))
            }
            
            if !arg.flags.isEmpty {
                HStack(spacing: 4) {
                    ForEach(arg.flags, id: \.self) { flag in
                        Text(flag)
                            .font(.system(.caption2))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 4).padding(.vertical, 1)
                            .overlay {
                                RoundedRectangle(cornerRadius: 3)
                                    .stroke(Color.secondary.opacity(0.35), lineWidth: 0.8)
                            }
                    }
                }
            }
            
            // Nested args (oneof / block)
            if !arg.arguments.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(arg.arguments) { nested in
                        HStack(alignment: .top, spacing: 5) {
                            Rectangle()
                                .fill(Color.secondary.opacity(0.25))
                                .frame(width: 1.5)
                                .padding(.leading, 4)
                            CommandArgRow(arg: nested, indent: indent + 1)
                        }
                    }
                }
                .padding(.top, 2)
                .padding(.leading, 4)
            }
        }
        .padding(.horizontal, 8).padding(.vertical, 5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(NSColor.controlBackgroundColor).opacity(indent == 0 ? 0.6 : 0.35))
        .clipShape(RoundedRectangle(cornerRadius: 5))
    }
}

// MARK: - Command Syntax Hint Bar
struct CommandSyntaxHintBar: View {
    let doc: CommandDoc
    /// Total tokens typed on the current line including the command name itself.
    let typedTokenCount: Int
    /// Whether the current line ends with whitespace (user finished typing the last token).
    let hasTrailingSpace: Bool
    
    /// The index of the argument the user is currently on (0 = command name).
    /// - No trailing space: the last typed token is still being typed → currentArgIndex = typedTokenCount - 1
    /// - Trailing space: user finished the last token and is about to type the next → currentArgIndex = typedTokenCount
    private var currentArgIndex: Int {
        hasTrailingSpace ? typedTokenCount : max(0, typedTokenCount - 1)
    }
    
    // MARK: Segment model
    private struct HintSegment: Identifiable {
        let id: Int
        let text: String
    }
    
    private var segments: [HintSegment] {
        doc.arguments.enumerated().map { i, arg in
            HintSegment(id: i, text: formatArgText(arg))
        }
    }
    
    // MARK: Body
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                // Tiny chevron icon
                Image(systemName: "chevron.right")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.tertiary)
                    .padding(.trailing, 7)
                
                // Command name — highlight based on currentArgIndex
                syntaxToken(doc.name.uppercased(),
                            bold: true,
                            style: currentArgIndex > 0 ? .covered : (typedTokenCount >= 1 ? .current : .future))
                
                // Argument segments — light up progressively
                ForEach(segments) { seg in
                    // token index: command = 0, seg.id 0 = token 1, etc.
                    let tokenIdx = seg.id + 1
                    let style = segmentStyle(for: tokenIdx)
                    
                    Text(" ")
                        .font(.system(size: 11, design: .monospaced))
                    
                    syntaxToken(seg.text, bold: style == .current, style: style)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
        .background(Color(NSColor.windowBackgroundColor).opacity(0.95))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color(NSColor.separatorColor))
                .frame(height: 0.5)
        }
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color(NSColor.separatorColor))
                .frame(height: 0.5)
        }
        .animation(.easeInOut(duration: 0.15), value: typedTokenCount)
    }
    
    // MARK: Helpers
    private enum SegStyle { case covered, current, future }
    
    private func segmentStyle(for tokenIndex: Int) -> SegStyle {
        if tokenIndex < currentArgIndex { return .covered }
        if tokenIndex == currentArgIndex { return .current }
        return .future
    }
    
    @ViewBuilder
    private func syntaxToken(_ text: String, bold: Bool, style: SegStyle) -> some View {
        let color: Color = {
            switch style {
            case .covered: return Color.primary.opacity(0.82)
            case .current: return Color.accentColor
            case .future:  return Color.secondary.opacity(0.35)
            }
        }()
        Text(text)
            .font(.system(size: 11, weight: bold ? .bold : (style == .current ? .semibold : .regular), design: .monospaced))
            .foregroundStyle(color)
    }
    
    // MARK: Recursive arg → display text
    private func formatArgText(_ arg: CommandArgDoc) -> String {
        let isOptional = arg.flags.contains("optional")
        let isMultiple = arg.flags.contains("multiple") || arg.flags.contains("variadic")
        
        var inner: String
        switch arg.type {
        case "pure-token":
            inner = arg.token ?? arg.name.uppercased()
        case "oneof":
            // Join nested options with " | "
            let parts = arg.arguments.map { formatArgText($0) }
            inner = parts.joined(separator: " | ")
        case "block":
            // Space-join nested args (e.g. "EX seconds")
            let parts = arg.arguments.map { formatArgText($0) }
            inner = parts.joined(separator: " ")
        default:
            // key, string, integer, double, pattern, unix-time, posix-time, etc.
            inner = arg.displayText.isEmpty ? arg.name : arg.displayText
        }
        
        var result = isOptional ? "[\(inner)]" : inner
        if isMultiple { result += " ..." }
        return result
    }
}

// MARK: - Command Query Text Editor (NSViewRepresentable)
struct CommandQueryTextEditor: NSViewRepresentable {
    @Binding var text: String
    @Binding var selectedCommand: String
    /// Live command list from the server; empty until COMMAND LIST resolves.
    var commandNames: [String]
    /// Returns argument token completions for a given command name (from COMMAND DOCS cache).
    var argCompletions: (String) -> [String]
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
        
        // Sync dynamic command set when COMMAND LIST arrives; re-highlight immediately
        let newSet: Set<String>? = commandNames.isEmpty ? nil : Set(commandNames)
        if newSet != coordinator.dynamicCommandSet {
            coordinator.dynamicCommandSet = newSet
            if !coordinator.isUpdating {
                coordinator.isUpdating = true
                let sel = textView.selectedRange()
                let highlighted = RedisHighlighter.highlight(textView.string, commands: newSet)
                textView.textStorage?.setAttributedString(highlighted)
                if sel.location <= highlighted.length { textView.setSelectedRange(sel) }
                coordinator.isUpdating = false
            }
        }
        
        if textView.string != text {
            coordinator.isUpdating = true
            let selectedRange = textView.selectedRange()
            let highlighted = RedisHighlighter.highlight(text, commands: coordinator.dynamicCommandSet)
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
        /// Live command set from the server; nil until COMMAND LIST completes (falls back to static list).
        var dynamicCommandSet: Set<String>? = nil
        
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
            let highlighted = RedisHighlighter.highlight(textView.string, commands: dynamicCommandSet)
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
            
            // Trigger for both command-name position AND argument position.
            // We used to skip if there was a space before the partial word — now we allow it
            // so argument token completions (EX, NX, GT, …) pop up too.
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
            
            // Determine the position context: are we at the command-name position or an argument position?
            let cursorLocation = charRange.location
            let lineRange = nsString.lineRange(for: NSRange(location: cursorLocation, length: 0))
            let linePrefix = nsString.substring(with: NSRange(location: lineRange.location, length: cursorLocation - lineRange.location))
            let trimmedPrefix = linePrefix.trimmingCharacters(in: .whitespaces)
            
            // ── Argument mode: there is content (command + at least one space) before the partial word ──
            if trimmedPrefix.contains(" ") || trimmedPrefix.contains("\t") {
                // Extract the command name (first token on the line)
                let lineTokens = trimmedPrefix
                    .trimmingCharacters(in: .init(charactersIn: "# \t"))
                    .components(separatedBy: .whitespaces)
                    .filter { !$0.isEmpty }
                guard let commandName = lineTokens.first else { return [] }
                
                // Already-typed arguments on this line (excluding partial word)
                let typedArgs = Set(lineTokens.dropFirst().map { $0.uppercased() })
                
                // Get argument token completions from COMMAND DOCS cache
                let tokens = parent.argCompletions(commandName.lowercased())
                let matches = tokens
                    .filter { $0.lowercased().hasPrefix(partialWord) }
                    .filter { !typedArgs.contains($0) }  // don't re-suggest already-typed tokens
                    .sorted()
                
                if !matches.isEmpty {
                    index?.pointee = -1  // no pre-selection
                    return matches
                }
                return []
            }
            
            // ── Command-name mode: partial word is the first token on the line ──
            let commandSet = dynamicCommandSet ?? RedisHighlighter.redisCommands
            let matches = commandSet.filter { $0.hasPrefix(partialWord) }.sorted()
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
