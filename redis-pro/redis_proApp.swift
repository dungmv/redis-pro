//
//  redis_proApp.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/1/19.
//

import Foundation
import SwiftUI
import Logging
import ComposableArchitecture

@main
struct redis_proApp: App {
    private let logger = Logger(label: "app")
    @AppStorage(UserDefaultsKeysEnum.AppColorScheme.rawValue)
    private var colorSchemeValue: String = ColorSchemeEnum.SYSTEM.rawValue
    
    // 会造成indexView 多次初始化
//    @Environment(\.scenePhase) var scenePhase
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    // settings
    var settingsStore:StoreOf<SettingsStore> = Store(initialState: SettingsStore.State()) {
        SettingsStore()
    }
//    private var store:StoreOf<AppStore>
    private var rootStore = Store(initialState: AppRootStore.State()) {
        AppRootStore()
    }
    private var mainWindowId = UUID().uuidString
    
    // 应用启动只初始化一次
    init() {
        // logger init
        LoggerFactory().setUp()
        rootStore.send(.addWindow(mainWindowId))
    }
    
    var body: some Scene {
       
        WindowGroup {
            IndexView(store: rootStore.scope(state: \.windows[id: self.mainWindowId]!, action: \.windows[id: self.mainWindowId]))
                .preferredColorScheme(preferredColorScheme)
        }
        .commands {
            CommandGroup(replacing: CommandGroupPlacement.toolbar) {
                Button(action: openNewWindow) {
                    Text("New Tab")
                }
                .keyboardShortcut("T", modifiers: [.command])
            }
        }
        .commands {
            RedisProCommands()
        }
        
//        WindowGroup {
//            IndexView(settingStore: settingsStore)
//                .onAppear {
//                    self.settingsStore.send(.initial)
//                }
//        }
//        .commands {
//            RedisProCommands()
//        }
        
        WindowGroup("AboutView") {
            AboutView()
                .preferredColorScheme(preferredColorScheme)
        }.handlesExternalEvents(matching: Set(arrayLiteral: "AboutView"))
        
        Settings {
            SettingsView(store: settingsStore)
                .preferredColorScheme(preferredColorScheme)
        }
    }

    private var preferredColorScheme: ColorScheme? {
        switch colorSchemeValue {
        case ColorSchemeEnum.DARK.rawValue:
            return .dark
        case ColorSchemeEnum.LIGHT.rawValue:
            return .light
        default:
            return nil
        }
    }
    
    func openNewWindow() {
        guard let currentWindow = NSApp.keyWindow else { return }
            
        // 创建新窗口
        currentWindow.windowController?.newWindowForTab(nil)
        
        // 获取新创建的窗口
        guard let newWindow = NSApp.windows.last,
              newWindow != currentWindow else { return }
        
        // 替换内容视图
                        
        let windowId = UUID().uuidString
        rootStore.send(.addWindow(windowId))
        let store = rootStore.scope(state: \.windows[id: windowId]!, action: \.windows[id: windowId])
      
        let customView = IndexView(store: store)
        newWindow.contentViewController = NSHostingController(rootView: customView)
        
        // 添加到标签页
        currentWindow.addTabbedWindow(newWindow, ordered: .above)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    let logger = Logger(label: "redis-app")
    
    func applicationWillFinishLaunching(_: Notification) {
        logger.info("redis pro before launch ...")
        
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        logger.info("redis pro launch complete")
        logger.info("redis pro launch, scene color scheme ready...")
        
    }
    
    func applicationWillTerminate(_ notification: Notification)  {
        logger.info("redis pro application will terminate...")
    }
    
    func didFinishLaunchingWithOptions(_ notification: Notification)  {
        logger.info("redis didFinishLaunchingWithOptions...")
    }
    
    func applicationWillUnhide(_: Notification) {
        logger.info("redis pro applicationWillUnhide...")
    }
    func applicationDidHide(_ notification:Notification) {
        logger.info("redis pro applicationDidHide...")
    }
    
    
    func applicationWillBecomeActive(_ notification: Notification) {
        logger.info("redis applicationWillBecomeActive...")
    }
    
    func applicationWillResignActive(_:Notification) {
        logger.info("redis pro applicationWillResignActive...")
    }

    func applicationShouldHandleReopen(_: NSApplication, hasVisibleWindows: Bool) -> Bool {
        logger.info("redis pro applicationShouldHandleReopen, hasVisibleWindows: \(hasVisibleWindows)")
        return true
    }

    func applicationShouldOpenUntitledFile(_:NSApplication) -> Bool {
        logger.info("redis pro applicationShouldOpenUntitledFile...")
        return true

    }
    
}
