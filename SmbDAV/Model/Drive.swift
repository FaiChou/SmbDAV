//
//  Drive.swift
//  SmbDAV
//
//  Created by 周辉 on 2023/12/29.
//

import Foundation
import UIKit

protocol SmbDAVDrive {
    func ping() async -> Bool
    func listFiles(atPath path: String) async throws -> [SmbDAVFile]
    func deleteFile(atPath path: String) async throws -> Bool
    func getImage(atPath path: String) async -> UIImage?
}
