//
//  KeyObjectBar.swift
//  redis-pro
//
//  Created by chengpan on 2023/7/30.
//  Migrated to MVVM (Swift 6)
//

import SwiftUI
import Logging

struct KeyObjectBar: View {
    let viewModel: KeyObjectViewModel

    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: "cpu")
                        .font(.system(size: 11, weight: .medium))
                    Text("Encoding")
                        .font(.subheadline.weight(.medium))
                }
                .foregroundColor(.secondary)
                
                Text(viewModel.encoding.isEmpty ? "–" : viewModel.encoding)
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
                    .help("Internal Redis encoding")
            }
            
            HStack(spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: "memorychip")
                        .font(.system(size: 11, weight: .medium))
                    Text("Memory")
                        .font(.subheadline.weight(.medium))
                }
                .foregroundColor(.secondary)
                
                Text(viewModel.memorySize)
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
                    .help("Memory usage (approximate)")
            }
        }
        .padding(.horizontal, 10)
    }
}
