//
//  SmbDAVApp.swift
//  SmbDAV
//
//  Created by 周辉 on 2023/12/28.
//

import SwiftUI
import KSPlayer

@main
struct SmbDAVApp: App {
    init() {
        #if DEBUG
        KSOptions.logLevel = .debug
        #endif
        KSOptions.firstPlayerType = KSMEPlayer.self
        KSOptions.secondPlayerType = KSMEPlayer.self
        KSOptions.isAutoPlay = true
    }
    var body: some Scene {
        WindowGroup {
            Home().environmentObject(SettingsModel.shared)
        }
    }
}
