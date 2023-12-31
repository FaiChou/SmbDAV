//
//  SmbDAVFile.swift
//  SmbDAV
//
//  Created by 周辉 on 2023/12/29.
//

import Foundation
import UIKit
import SWXMLHash

struct SmbDAVFile: Identifiable, Hashable, Equatable {
    var path: String
    var id: String
    var isDirectory: Bool
    var lastModified: Date
    var size: Int64
    var driveType: DriveType
    init(path: String, id: String, isDirectory: Bool, lastModified: Date, size: Int64, driveType: DriveType) {
        self.path = path
        self.id = id
        self.isDirectory = isDirectory
        self.lastModified = lastModified
        self.size = size
        self.driveType = driveType
    }
    init?(xml: XMLIndexer, baseURL: URL) {
        // the first is good result
        let properties = xml["propstat"][0]["prop"]
        guard var path = xml["href"].element?.text,
              let dateString = properties["getlastmodified"].element?.text,
              let date = SmbDAVFile.rfc1123Formatter.date(from: dateString) else { return nil }
        let isDirectory = properties["getcontenttype"].element == nil
        if let decodedPath = path.removingPercentEncoding {
            path = decodedPath
        }
        path = SmbDAVFile.removing(endOf: baseURL.absoluteString, from: path)
        if path.first == "/" {
            path.removeFirst()
        }
        var size: Int64 = 0
        if let sizeString = properties["getcontentlength"].element?.text {
            size = Int64(sizeString) ?? 0
        }
        self.init(path: path, id: UUID().uuidString, isDirectory: isDirectory, lastModified: date, size: size, driveType: .WebDAV)
    }
    init?(smbFile: [URLResourceKey: Any]) {
        guard let path = smbFile[.pathKey] as? String,
              let size = smbFile[.fileSizeKey] as? Int64,
              let isDirectory = smbFile[.isDirectoryKey] as? Bool,
              let lastModified = smbFile[.contentModificationDateKey] as? Date else {
            return nil
        }
        self.init(path: path,
                  id: UUID().uuidString,
                  isDirectory: isDirectory,
                  lastModified: lastModified,
                  size: size,
                  driveType: .smb
        )
    }

    static let rfc1123Formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss z"
        return formatter
    }()

    static func removing(endOf string1: String, from string2: String) -> String {
        guard let first = string2.first else { return string2 }
        for (i, c) in string1.enumerated() {
            guard c == first else { continue }
            let end = string1.dropFirst(i)
            if string2.hasPrefix(end) {
                return String(string2.dropFirst(end.count))
            }
        }
        return string2
    }
    var description: String {
        "SmbDAVFile(path: \(path), id: \(id), isDirectory: \(isDirectory), lastModified: \(lastModified.formatted()), size: \(size))"
    }
    private var fileURL: URL {
        URL(fileURLWithPath: path)
    }
    var fullName: String {
        return fileURL.lastPathComponent
    }
    var `extension`: String {
        fileURL.pathExtension
    }
    var name: String {
        isDirectory ? fullName : fileURL.deletingPathExtension().lastPathComponent
    }
    var isImage: Bool {
        return ["png", "jpg", "jpeg"].contains { $0 == self.extension }
    }
    var isVideo: Bool {
        return ["mkv", "mp4"].contains { $0 == self.extension }
    }
}
