//
//  SettingsView.swift
//  redis-pro
//
//  Liquid Glass settings panel.
//

import SwiftUI
import ComposableArchitecture
import Logging

struct SettingsView: View {

    private static let logger = Logger(label: "settings-view")
    private let labelWidth: CGFloat = 160

    @Bindable var store: StoreOf<SettingsStore>

    var body: some View {
        WithPerceptionTracking {
            Form {
                Section {
                    Picker(
                        selection: $store.defaultFavorite.sending(\.setDefaultFavorite),
                        label: Text("Default Favorite").frame(width: labelWidth, alignment: .trailing)
                    ) {
                        Text("Last Used").tag("last")
                        ForEach(store.redisModels, id: \.id) { Text($0.name).tag($0.id) }
                    }

                    Picker(
                        selection: $store.colorSchemeValue.sending(\.setColorScheme),
                        label: Text("Appearance").frame(width: labelWidth, alignment: .trailing)
                    ) {
                        ForEach(ColorSchemeEnum.allCases.map(\.rawValue), id: \.self) {
                            Text(verbatim: $0)
                        }
                    }
                }

                Section {
                    FormItemInt(
                        label: "String Max Length",
                        labelWidth: labelWidth,
                        tips: "HELP_STRING_GET_RANGE_LENGTH",
                        value: $store.stringMaxLength.sending(\.setStringMaxLength)
                    )

                    Toggle(isOn: $store.fastPage.sending(\.setFastPage)) {
                        Text("Fast Pagination")
                            .frame(width: labelWidth, alignment: .trailing)
                    }
                    .toggleStyle(.switch)
                    .help("HELP_FAST_PAGE")

                    FormItemInt(
                        label: "Search History Size",
                        labelWidth: labelWidth,
                        tips: "HELP_SEARCH_HISTORY_SIZE",
                        value: $store.searchHistorySize.sending(\.setSearchHistorySize)
                    )
                }
            }
            .formStyle(.grouped)
            .onAppear { store.send(.initial) }
            .navigationTitle("Preferences")
            .frame(minWidth: 420, minHeight: 260)
        }
    }
}
