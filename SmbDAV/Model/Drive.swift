//
//  Drive.swift
//  SmbDAV
//
//  Created by 周辉 on 2023/12/29.
//

import Foundation

protocol SmbDAVDrive {
    var baseURL: URL { get }
    var auth: String { get }
    func ping() async -> Bool
    func listFiles(atPath path: String) async throws -> [SmbDAVFile]
    func deleteFile(atPath path: String) async throws -> Bool
}
