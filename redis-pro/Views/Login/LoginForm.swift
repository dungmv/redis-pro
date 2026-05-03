//
//  LoginForm.swift
//  redis-pro
//
//  Liquid Glass connection form.
//

import SwiftUI
import ComposableArchitecture

struct LoginForm: View {

    @Environment(\.openURL) var openURL
    @Bindable var store: StoreOf<LoginStore>

    var body: some View {
        WithPerceptionTracking {
            TabView(selection: $store.connectionType) {
                tcpTab
                    .tabItem { Label("TCP/IP", systemImage: "network") }
                    .tag(RedisConnectionTypeEnum.TCP.rawValue)

                sshTab
                    .tabItem { Label("SSH Tunnel", systemImage: "bolt.horizontal") }
                    .tag(RedisConnectionTypeEnum.SSH.rawValue)
            }
            .padding(20)
            .frame(width: 500, height: store.height)
            .glassWindowSurface()
        }
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
                    FormItemText(label: "SSH Host", placeholder: "hostname", value: $store.sshHost)
                    FormItemInt(label: "SSH Port", placeholder: "22", value: $store.sshPort)
                    FormItemText(label: "SSH User", placeholder: "username", value: $store.sshUser)
                    FormItemPassword(label: "SSH Pass", value: $store.sshPass)
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
            FormItemText(label: "Name", placeholder: "connection name", value: $store.name)
            FormItemText(label: "Host", placeholder: "127.0.0.1", value: $store.host)
            FormItemInt(label: "Port", placeholder: "6379", value: $store.port)
            FormItemText(label: "User", placeholder: "default", value: $store.username)
            FormItemPassword(label: "Password", value: $store.password)
            FormItemInt(label: "Database", value: $store.database)
        }
        .sectionSurface()
    }

    private var footerSection: some View {
        VStack(spacing: 10) {
            Divider().padding(.top, 12)

            // Status + Connect row
            HStack(alignment: .center, spacing: 8) {
                if !store.loading {
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

                MLoading(text: store.pingR, loadingText: "Connecting...", loading: store.loading)
                    .help(store.pingR)
                    .frame(maxWidth: .infinity, alignment: .leading)

                MButton(text: "Connect", action: { store.send(.connect) }, disabled: store.loading, style: .primary, keyEquivalent: .return)
                    .keyboardShortcut(.defaultAction)
            }

            // Action row
            HStack(spacing: 8) {
                MButton(text: "Add to Favorites", action: { store.send(.add) })
                Spacer()
                MButton(text: "Save Changes", action: { store.send(.save) })
                Spacer()
                MButton(text: "Test Connection", action: { store.send(.testConnect) }, disabled: store.loading)
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
