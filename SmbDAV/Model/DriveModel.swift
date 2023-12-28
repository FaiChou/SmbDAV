//
//  DriveModel.swift
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

struct DriveModel: Identifiable, Codable, Hashable, Equatable {
    var id: UUID = UUID()
    var driveType: DriveType = .WebDAV
    var alias: String = "My Drive"
    var address: String = ""
    var username: String = ""
    var password: String = ""
    var port: Int = 80
    var path: String = ""
    static func == (lhs: DriveModel, rhs: DriveModel) -> Bool {
        return lhs.id == rhs.id
    }
    var driveDetail: String {
        var address = self.address
        if port != 80 && port != 443 {
            address += ":\(port)"
        }
        if !path.isEmpty {
            let slashPrefixedPath = path.hasPrefix("/") ? path : "/\(path)"
            address += slashPrefixedPath
        }
        return address
    }
}
