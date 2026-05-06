//
//  AboutView.swift
//  redis-pro
//
//  Liquid Glass about / credits window.
//

import SwiftUI

struct AboutView: View {

    private let dependencies: [(String, String)] = [
        ("Valkey", "https://github.com/valkey-io/valkey-swift"),
        ("NIOSSH", "https://github.com/apple/swift-nio-ssh"),
        ("SwiftJSONFormatter", "https://github.com/luin/SwiftJSONFormatter"),
        ("swift-log", "https://github.com/apple/swift-log"),

    ]

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.clear)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                VStack(spacing: LiquidGlass.spacing20) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color.accentColor.opacity(0.95), Color.accentColor.opacity(0.72)],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                            .overlay(
                                RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    .strokeBorder(LiquidGlass.glassHighlight, lineWidth: 0.5)
                            )
                            .shadow(color: LiquidGlass.glassShadow, radius: 12, x: 0, y: 6)

                        Image(systemName: "server.rack")
                            .font(.system(size: 36, weight: .medium))
                            .foregroundStyle(.white)
                            .symbolRenderingMode(.hierarchical)
                    }

                    VStack(spacing: LiquidGlass.spacing4) {
                        Text("Redis Pro")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(.primary)

                        Text("A beautiful Redis client for macOS")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)

                        Link("github.com/cmushroom/redis-pro",
                             destination: URL(string: "https://github.com/cmushroom/redis-pro")!)
                            .font(.system(size: 12))
                            .foregroundStyle(Color.accentColor)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 24)
                .padding(.top, 28)
                .padding(.bottom, 24)
                .glassCard(cornerRadius: LiquidGlass.radiusLG)

                VStack(alignment: .leading, spacing: 0) {
                    Text("Open Source Libraries")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .kerning(0.5)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)

                    VStack(spacing: 0) {
                        ForEach(dependencies, id: \.0) { dep in
                            HStack {
                                Image(systemName: "shippingbox")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)

                                Link(dep.0, destination: URL(string: dep.1)!)
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color.accentColor)

                                Spacer()

                                Image(systemName: "arrow.up.right.square")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .contentShape(Rectangle())

                            if dep.0 != dependencies.last?.0 {
                                Divider().padding(.horizontal, 20)
                            }
                        }
                    }
                    .glassCard(cornerRadius: LiquidGlass.radiusMD)
                }
                .padding(.top, 16)

                Spacer()

                Text("Made by the open-source community")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 20)
            }
            .padding(16)
        }
        .glassWindowSurface()
        .frame(minWidth: 400, maxWidth: 480, minHeight: 420, maxHeight: 520)
    }
}
