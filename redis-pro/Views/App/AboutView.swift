//
//  AboutView.swift
//  redis-pro
//
//  Liquid Glass about / credits window.
//

import SwiftUI

struct AboutView: View {

    private let dependencies: [(String, String)] = [
        ("RediStack", "https://github.com/Mordil/RediStack"),
        ("SwiftJSONFormatter", "https://github.com/luin/SwiftJSONFormatter"),
        ("Puppy", "https://github.com/sushichop/Puppy"),
        ("ComposableArchitecture", "https://github.com/pointfreeco/swift-composable-architecture"),
    ]

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.08, blue: 0.12),
                    Color(red: 0.05, green: 0.05, blue: 0.10),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // ── App Icon + Name ─────────────────────────────────────────
                VStack(spacing: 12) {
                    // App icon placeholder (uses asset catalog icon if available)
                    ZStack {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color(red: 0.85, green: 0.25, blue: 0.15), Color(red: 0.60, green: 0.10, blue: 0.08)],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                            .shadow(color: Color(red: 0.85, green: 0.25, blue: 0.15).opacity(0.4), radius: 16, x: 0, y: 8)

                        Image(systemName: "server.rack")
                            .font(.system(size: 36, weight: .medium))
                            .foregroundStyle(.white)
                            .symbolRenderingMode(.hierarchical)
                    }

                    VStack(spacing: 4) {
                        Text("Redis Pro")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(.white)

                        Text("A beautiful Redis client for macOS")
                            .font(.system(size: 13))
                            .foregroundStyle(.white.opacity(0.6))

                        Link("github.com/cmushroom/redis-pro",
                             destination: URL(string: "https://github.com/cmushroom/redis-pro")!)
                            .font(.system(size: 12))
                            .foregroundStyle(Color.accentColor)
                    }
                }
                .padding(.top, 36)
                .padding(.bottom, 24)

                Divider()
                    .background(.white.opacity(0.1))

                // ── Open Source Credits ──────────────────────────────────────
                VStack(alignment: .leading, spacing: 0) {
                    Text("Open Source Libraries")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.5))
                        .kerning(0.5)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)

                    VStack(spacing: 0) {
                        ForEach(dependencies, id: \.0) { dep in
                            HStack {
                                Image(systemName: "shippingbox")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.white.opacity(0.4))

                                Link(dep.0, destination: URL(string: dep.1)!)
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color.accentColor)

                                Spacer()

                                Image(systemName: "arrow.up.right.square")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.white.opacity(0.3))
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .contentShape(Rectangle())

                            if dep.0 != dependencies.last?.0 {
                                Divider().padding(.horizontal, 20).background(.white.opacity(0.1))
                            }
                        }
                    }
                    .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal, 16)
                }

                Spacer()

                // ── Footer ───────────────────────────────────────────────────
                Text("Made with ❤️ by the open-source community")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.3))
                    .padding(.bottom, 20)
            }
        }
        .frame(minWidth: 400, maxWidth: 480, minHeight: 420, maxHeight: 520)
    }
}
