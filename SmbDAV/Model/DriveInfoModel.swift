//
//  DriveInfoModel.swift
//  WebdavDemo
//
//  Created by FaiChou on 2023/12/28.
//

import Foundation
import SwiftUI

enum DriveType: String, CaseIterable, Codable, Identifiable {
    case WebDAV, smb
    var id: Self { self }
}

struct DriveInfoModel: Identifiable, Codable, Hashable, Equatable {
    var id: UUID = UUID()
    var driveType: DriveType = .WebDAV
    var alias: String = "My Drive"
    var address: String = ""
    var username: String = ""
    var password: String = ""
    var port: Int = 80
    var subfolder: String = ""
    static func == (lhs: DriveInfoModel, rhs: DriveInfoModel) -> Bool {
        return lhs.id == rhs.id
    }
    var driveDetail: String {
        var address = self.address
        if port != 80 && port != 443 && port != 445 {
            address += ":\(port)"
        }
        if !subfolder.isEmpty {
            let slashPrefixedPath = subfolder.hasPrefix("/") ? subfolder : "/\(subfolder)"
            address += slashPrefixedPath
        }
        if !username.isEmpty {
            address = "\(username)@\(address)"
        }
        return address
    }
}
