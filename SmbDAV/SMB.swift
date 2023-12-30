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
    let path: String
    let credential: URLCredential
    var smbURL: URL? {
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            return nil
        }
        if let username = credential.user, !username.isEmpty {
            components.user = username
            if let password = credential.password, !password.isEmpty {
                components.password = password
            }
        }
        if !path.isEmpty {
            components.path = components.path.appending("/\(path)")
        }
        return components.url
    }
    lazy private var client = SMB2Manager(url: self.baseURL, credential: self.credential)!
    init(baseURL: String, port: Int, username: String, password: String, path: String) {
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
        let p = path.hasPrefix("/") ? String(path.dropFirst()) : path
        self.path = p.isEmpty ? "/" : p
        self.baseURL = URL(string: fullURLString)!
        self.credential = URLCredential(user: username, password: password, persistence: .forSession)
    }
    private func connect() async throws -> SMB2Manager {
        try await client.connectShare(name: self.path)
        return self.client
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
        return files.compactMap { SmbDAVFile(smbFile: $0, baseURL: self.smbURL) }
    }
    func deleteFile(atPath path: String) async -> Bool {
        do {
            let client = try await self.connect()
            try await client.removeFile(atPath: path)
            return true
        } catch {
            return false
        }
    }
    func getImage(atPath path: String) async -> UIImage? {
        do {
            let client = try await self.connect()
            let data = try await client.contents(atPath: path) { bytes, total in
                print("downloaded:", bytes, "of", total)
                return true
            }
            return UIImage(data: data)
        } catch {
            return nil
        }
    }
}
