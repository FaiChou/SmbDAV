//
//  NFS.swift
//  SmbDAV
//
//  Created by 周辉 on 2024/1/1.
//

import Foundation
import UIKit
import NFSKit

class NFS: SmbDAVDrive {
    let baseURL: URL
    let client: NFSClient
    let share: String
    init?(baseURL: String, share: String) {
        let processedBaseURL: String
        if baseURL.hasPrefix("nfs://") {
            processedBaseURL = baseURL
        } else {
            processedBaseURL = "nfs://" + baseURL
        }
        let trimmedBaseURL = processedBaseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let u = URL(string: trimmedBaseURL),
              let c = try? NFSClient(url: u) else {
            return nil
        }
        self.baseURL = u
        self.client = c
        self.share = share.hasPrefix("/") ? String(share.dropFirst()) : share
    }
    private func connect() async -> Bool {
        let result = await client.connect(export: share)
        return result == nil
    }
    func ping() async -> Bool {
        return await connect()
    }
    func listExports() async throws -> [String] {
        let result = try await client.listExports()
        switch result {
        case .success(let exports):
            return exports
        case .failure(let failure):
            throw failure
        }
    }
    func listFiles(atPath path: String) async throws -> [SmbDAVFile] {
        guard await connect() else {
            return []
        }
        let result = await client.contentsOfDirectory(atPath: path)
        switch result {
        case .success(let items):
            return items.compactMap { SmbDAVFile(nfsFile: $0) }
        case .failure(let error):
            throw error
        }
    }
    func deleteFile(file: SmbDAVFile) async -> Bool {
        guard await connect() else {
            return false
        }
        if file.isDirectory {
            await client.removeDirectory(atPath: file.path, recursive: true)
        } else {
            await client.removeItem(atPath: file.path)
        }
        return true
    }
    func getImage(file: SmbDAVFile) async -> UIImage? {
        guard await connect() else {
            return nil
        }
        return await withCheckedContinuation { continuation in
            client.contents(atPath: file.path) { bytes, total in
                print("downloaded:", bytes, "of", total)
                return true
            } completionHandler: { result in
                switch result {
                case .success(let data):
                    continuation.resume(returning: UIImage(data: data))
                case .failure(let error):
                    print(error)
                    continuation.resume(returning: nil)
                }
            }
        }
    }
    // nfs://<server|ipv4|ipv6>[:<port>]/path[?arg=val[&arg=val]*]
    func getFileURL(file: SmbDAVFile) -> URL? {
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            return nil
        }
        if !share.isEmpty {
            components.path = components.path.appending("/\(share)")
        }
        return components.url?.appendingPathComponent(file.path)
    }
}
