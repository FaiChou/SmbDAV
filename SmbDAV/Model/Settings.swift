//
//  Settings.swift
//  SmbDAV
//
//  Created by 周辉 on 2023/12/31.
//

import Foundation
import SwiftUI

class SettingsModel: ObservableObject {
    static let shared = SettingsModel()
    @AppStorage("ShowHiddenFiles") var showHiddenFiles = false
    @AppStorage("FolderFirst") var folderFirst = true
}
