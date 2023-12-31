//
//  SmbDAVApp.swift
//  SmbDAV
//
//  Created by 周辉 on 2023/12/28.
//

import SwiftUI

@main
struct SmbDAVApp: App {
    var body: some Scene {
        WindowGroup {
            Home().environmentObject(SettingsModel.shared)
        }
    }
}
