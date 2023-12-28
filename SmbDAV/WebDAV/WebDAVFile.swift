//
//  WebDAVFile.swift
//  WebDAV-Swift
//
//  Created by Isaac Lyons on 11/16/20.
//

import Foundation
import SWXMLHash

struct WebDAVFile: Identifiable, Codable, Equatable, Hashable {

    public private(set) var path: String
    public private(set) var id: String
    public private(set) var isDirectory: Bool
    public private(set) var lastModified: Date
    public private(set) var size: Int64
    public private(set) var url: URL
    public private(set) var auth: String

    init(path: String, id: String, isDirectory: Bool, lastModified: Date, size: Int64, url: URL, auth: String) {
        self.path = path
        self.id = id
        self.isDirectory = isDirectory
        self.lastModified = lastModified
        self.size = size
        self.url = url
        self.auth = auth
    }
    init?(xml: XMLIndexer, baseURL: URL, auth: String) {
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
              let date = WebDAVFile.rfc1123Formatter.date(from: dateString) else { return nil }
        let isDirectory = properties["getcontenttype"].element == nil
        if let decodedPath = path.removingPercentEncoding {
            path = decodedPath
        }
        path = WebDAVFile.removing(endOf: baseURL.absoluteString, from: path)
        if path.first == "/" {
            path.removeFirst()
        }
        var size: Int64 = 0
        if let sizeString = properties["getcontentlength"].element?.text {
            size = Int64(sizeString) ?? 0
        }
        let url = baseURL.appendingPathComponent(path)
        self.init(path: path, id: UUID().uuidString, isDirectory: isDirectory, lastModified: date, size: size, url: url, auth: auth)
    }

    //MARK: Static
    static let rfc1123Formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss z"
        return formatter
    }()

    private static func removing(endOf string1: String, from string2: String) -> String {
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

    //MARK: Public
    public var description: String {
        "WebDAVFile(path: \(path), id: \(id), isDirectory: \(isDirectory), lastModified: \(WebDAVFile.rfc1123Formatter.string(from: lastModified)), size: \(size))"
    }
    public var fileURL: URL {
        URL(fileURLWithPath: path)
    }
    /// The file name including extension.
    public var fileName: String {
        return fileURL.lastPathComponent
    }
    /// The file extension.
    public var `extension`: String {
        fileURL.pathExtension
    }
    /// The name of the file without its extension.
    public var name: String {
        isDirectory ? fileName : fileURL.deletingPathExtension().lastPathComponent
    }
}
