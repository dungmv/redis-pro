//
//  LoginForm.swift
//  redis-pro
//
//  Liquid Glass connection form.
//  Migrated to MVVM (Swift 6)
//

import SwiftUI

struct LoginForm: View {

    @Environment(\.openURL) var openURL
    @State var viewModel: LoginViewModel

    var body: some View {
        TabView(selection: Binding(
            get: { viewModel.connectionType },
            set: { viewModel.connectionType = $0 }
        )) {
            tcpTab
                .tabItem { Label("TCP/IP", systemImage: "network") }
                .tag(RedisConnectionTypeEnum.TCP.rawValue)

            sshTab
                .tabItem { Label("SSH Tunnel", systemImage: "bolt.horizontal") }
                .tag(RedisConnectionTypeEnum.SSH.rawValue)
        }
        .padding(20)
        .frame(width: 500, height: viewModel.height)
        .glassWindowSurface()
    }

    // MARK: - TCP Tab

    private var tcpTab: some View {
        ScrollView {
            VStack(spacing: 0) {
                connectionSection
                footerSection
            }
            .padding(.bottom, 8)
        }
    }

    // MARK: - SSH Tab

    private var sshTab: some View {
        ScrollView {
            VStack(spacing: 0) {
                connectionSection

                VStack(alignment: .leading, spacing: 12) {
                    sectionHeader("SSH Configuration", icon: "lock.shield")
                    FormItemText(label: "SSH Host", placeholder: "hostname", value: Binding(get: { viewModel.sshHost }, set: { viewModel.sshHost = $0 }))
                    FormItemInt(label: "SSH Port", placeholder: "22", value: Binding(get: { viewModel.sshPort }, set: { viewModel.sshPort = $0 }))
                    FormItemText(label: "SSH User", placeholder: "username", value: Binding(get: { viewModel.sshUser }, set: { viewModel.sshUser = $0 }))
                    FormItemPassword(label: "SSH Pass", value: Binding(get: { viewModel.sshPass }, set: { viewModel.sshPass = $0 }))
                }
                .sectionSurface()
                .padding(.top, 12)

                footerSection
            }
            .padding(.bottom, 8)
        }
    }

    // MARK: - Shared sections

    private var connectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Connection", icon: "server.rack")
            FormItemText(label: "Name", placeholder: "connection name", value: Binding(get: { viewModel.name }, set: { viewModel.name = $0 }))
            FormItemText(label: "Host", placeholder: "127.0.0.1", value: Binding(get: { viewModel.host }, set: { viewModel.host = $0 }))
            FormItemInt(label: "Port", placeholder: "6379", value: Binding(get: { viewModel.port }, set: { viewModel.port = $0 }))
            FormItemText(label: "User", placeholder: "default", value: Binding(get: { viewModel.username }, set: { viewModel.username = $0 }))
            FormItemPassword(label: "Password", value: Binding(get: { viewModel.password }, set: { viewModel.password = $0 }))
            FormItemInt(label: "Database", value: Binding(get: { viewModel.database }, set: { viewModel.database = $0 }))
        }
        .sectionSurface()
    }

    private var footerSection: some View {
        VStack(spacing: 10) {
            Divider().padding(.top, 12)

            // Status + Connect row
            HStack(alignment: .center, spacing: 8) {
                if !viewModel.loading {
                    Button(action: {
                        guard let url = URL(string: Const.REPO_URL) else { return }
                        openURL(url)
                    }) {
                        Image(systemName: "questionmark.circle")
                            .font(.system(size: 15))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Open documentation")
                }

                MLoading(text: viewModel.pingR, loadingText: "Connecting...", loading: viewModel.loading)
                    .help(viewModel.pingR)
                    .frame(maxWidth: .infinity, alignment: .leading)

                MButton(text: "Connect", action: { viewModel.connect() }, disabled: viewModel.loading, style: .primary, keyEquivalent: .return)
                    .keyboardShortcut(.defaultAction)
            }

            // Action row
            HStack(spacing: 8) {
                MButton(text: "Add to Favorites", action: { viewModel.add() })
                Spacer()
                MButton(text: "Save Changes", action: { viewModel.save() })
                Spacer()
                MButton(text: "Test Connection", action: { viewModel.testConnect() }, disabled: viewModel.loading)
            }
        }
    }

    // MARK: - Helpers

    private func sectionHeader(_ name: String, icon: String) -> some View {
        Label(name, systemImage: icon)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.secondary)
            .padding(.bottom, 4)
    }
}

private extension View {
    func sectionSurface() -> some View {
        self
            .padding(.vertical, 4)
            .padding(.horizontal, 14)
            .glassCard(cornerRadius: LiquidGlass.radiusLG)
    }
}
