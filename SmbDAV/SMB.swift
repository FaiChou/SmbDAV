//
//  SMB.swift
//  SmbDAV
//
//  Created by 周辉 on 2023/12/30.
//

import Foundation
import AMSMB2
import UIKit

class SMB: SmbDAVDrive {
    let baseURL: URL
    let share: String
    let credential: URLCredential
    lazy private var client = SMB2Manager(url: self.baseURL, credential: self.credential)!
    init(baseURL: String, port: Int, username: String, password: String, subfolder: String) {
        let processedBaseURL: String
        if baseURL.hasPrefix("smb://") {
            processedBaseURL = baseURL
        } else {
            processedBaseURL = "smb://" + baseURL
        }
        let trimmedBaseURL = processedBaseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        var fullURLString = trimmedBaseURL
        if port != 445 {
            fullURLString += ":\(port)"
        }
        let path = subfolder.hasPrefix("/") ? String(subfolder.dropFirst()) : subfolder
        self.share = path.isEmpty ? "/" : path
        self.baseURL = URL(string: fullURLString)!
        let user = username.isEmpty ? "Guest" : username
        self.credential = URLCredential(user: user, password: password, persistence: .forSession)
    }
    func getFileURL(file: SmbDAVFile) -> URL? {
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            return nil
        }
        if let username = credential.user, !username.isEmpty {
            components.user = username
            if let password = credential.password, !password.isEmpty {
                components.password = password
            }
        }
        if !share.isEmpty {
            components.path = components.path.appending("/\(share)")
        }
        return components.url?.appendingPathComponent(file.path)
    }
    private func connect() async throws -> SMB2Manager {
        try await client.connectShare(name: self.share)
        return self.client
    }
    func listShares() async throws -> [String] {
        let shares = try await self.client.listShares()
        return shares.compactMap { $0.name }
    }
    func ping() async -> Bool {
        do {
            let _ = try await connect()
            return true
        } catch {
            print(error)
            return false
        }
    }
    func listFiles(atPath path: String) async throws -> [SmbDAVFile] {
        let client = try await self.connect()
        let files = try await client.contentsOfDirectory(atPath: path)
        return files.compactMap { SmbDAVFile(smbFile: $0) }
    }
    func deleteFile(file: SmbDAVFile) async -> Bool {
        do {
            let client = try await self.connect()
            if file.isDirectory {
                try await client.removeDirectory(atPath: file.path, recursive: true)
            } else {
                try await client.removeFile(atPath: file.path)
            }
            return true
        } catch {
            return false
        }
    }
    func getImage(file: SmbDAVFile) async -> UIImage? {
        do {
            let client = try await self.connect()
            let data = try await client.contents(atPath: file.path) { bytes, total in
//                print("downloaded:", bytes, "of", total)
                return true
            }
            return UIImage(data: data)
        } catch {
            return nil
        }
    }
}
