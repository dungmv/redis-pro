//
//  SearchBar.swift
//  redis-pro
//
//  Liquid Glass search field with history dropdown.
//

import SwiftUI
import Logging

struct SearchBar: View {

    @State private var keywords: String = ""
    @State private var searchHistory: [String] = []
    @State private var isFocused: Bool = false
    @State private var showHistory: Bool = false

    var placeholder: String = "Search..."
    var onCommit: ((String) -> Void)?

    private static let logger = Logger(label: "search-bar")

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)

                TextField("", text: $keywords, prompt: Text(placeholder).foregroundColor(.secondary))
                    .textFieldStyle(.plain)
                    .font(LiquidGlass.fontBody)
                    .onSubmit { commit() }
                    .onChange(of: keywords) { _, _ in
                        showHistory = isFocused && !searchHistory.isEmpty
                    }
                    .onHover { inside in
                        if inside { NSCursor.iBeam.push() } else { NSCursor.pop() }
                    }

                if !keywords.isEmpty {
                    Button(action: {
                        keywords = ""
                        showHistory = false
                        onCommit?("")
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .transition(.opacity.combined(with: .scale))
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: LiquidGlass.radiusSM)
                    .fill(Color(NSColor.textBackgroundColor).opacity(0.85))
            )
            .overlay(
                RoundedRectangle(cornerRadius: LiquidGlass.radiusSM)
                    .strokeBorder(
                        isFocused ? Color.accentColor.opacity(0.5) : LiquidGlass.glassStroke,
                        lineWidth: isFocused ? 1.5 : 1
                    )
            )
            .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isFocused)
        }
        .zIndex(10)
        .onAppear {
            searchHistory = RedisDefaults.getSearchHistory()
        }
    }

    // MARK: - History dropdown (rendered by parent overlay)

    @ViewBuilder
    var historyDropdown: some View {
        if showHistory {
            let filtered = searchHistory.filter { keywords.isEmpty || $0.localizedCaseInsensitiveContains(keywords) }
            if !filtered.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(filtered.prefix(8), id: \.self) { item in
                        HStack {
                            Image(systemName: "clock")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                            Text(item)
                                .font(LiquidGlass.fontBody)
                                .lineLimit(1)
                            Spacer()
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            keywords = item
                            showHistory = false
                            commit()
                        }
                        .onHover { inside in
                            if inside { NSCursor.pointingHand.push() } else { NSCursor.pop() }
                        }
                        Divider().padding(.horizontal, 8)
                    }
                }
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: LiquidGlass.radiusSM))
                .overlay(
                    RoundedRectangle(cornerRadius: LiquidGlass.radiusSM)
                        .strokeBorder(LiquidGlass.glassBorder, lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                .zIndex(100)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)),
                    removal: .opacity
                ))
            }
        }
    }

    // MARK: - Private

    private func commit() {
        Self.logger.info("SearchBar commit, keywords: \(keywords)")
        var history = searchHistory
        history.removeAll { $0 == keywords }
        if !keywords.isEmpty { history.insert(keywords, at: 0) }
        searchHistory = Array(history.prefix(20))
        RedisDefaults.saveSearchHistory(history: searchHistory)
        onCommit?(keywords)
        showHistory = false
    }
}
