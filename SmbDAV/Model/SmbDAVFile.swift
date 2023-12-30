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
    var url: URL
    var driveType: DriveType
    init(path: String, id: String, isDirectory: Bool, lastModified: Date, size: Int64, url: URL, driveType: DriveType) {
        self.path = path
        self.id = id
        self.isDirectory = isDirectory
        self.lastModified = lastModified
        self.size = size
        self.url = url
        self.driveType = driveType
    }
    init?(xml: XMLIndexer, baseURL: URL) {
        /**
         <D:response>
             <D:href>http://example.com/resource</D:href>
             <D:propstat>
                 <D:prop>
                     <D:getcontentlength>1234</D:getcontentlength>
                     <D:getcontenttype>text/html</D:getcontenttype>
                 </D:prop>
                 <D:status>HTTP/1.1 200 OK</D:status>
             </D:propstat>
             <D:propstat>
                 <D:prop>
                     <D:customproperty></D:customproperty>
                 </D:prop>
                 <D:status>HTTP/1.1 404 Not Found</D:status>
             </D:propstat>
         </D:response>
         */
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
        let url = baseURL.appendingPathComponent(path)
        self.init(path: path, id: UUID().uuidString, isDirectory: isDirectory, lastModified: date, size: size, url: url, driveType: .WebDAV)
    }
    init?(smbFile: [URLResourceKey: Any], baseURL: URL?) {
        /**
         print(
             "name:", entry[.nameKey] as! String,
             ", path:", entry[.pathKey] as! String,
             ", type:", entry[.fileResourceTypeKey] as! URLFileResourceType,
             ", size:", entry[.fileSizeKey] as! Int64,
             ", modified:", entry[.contentModificationDateKey] as! Date,
             ", created:", entry[.creationDateKey] as! Date)
         */
        guard let path = smbFile[.pathKey] as? String,
              let size = smbFile[.fileSizeKey] as? Int64,
              let isDirectory = smbFile[.isDirectoryKey] as? Bool,
              let lastModified = smbFile[.contentModificationDateKey] as? Date,
              let url = baseURL else {
            return nil
        }
        self.init(path: path,
                  id: UUID().uuidString,
                  isDirectory: isDirectory,
                  lastModified: lastModified,
                  size: size,
                  url: url.appendingPathComponent(path),
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
    var fileURL: URL {
        URL(fileURLWithPath: path)
    }
    var fileName: String {
        return fileURL.lastPathComponent
    }
    var `extension`: String {
        fileURL.pathExtension
    }
    var name: String {
        isDirectory ? fileName : fileURL.deletingPathExtension().lastPathComponent
    }
}
