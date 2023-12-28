//
//  WebDAV.swift
//  WebDAV-Swift
//
//  Created by Isaac Lyons on 10/29/20.
//

import Foundation
import SWXMLHash

class WebDAV {
    var baseURL: URL
    var auth: String
    init(baseURL: String, port: Int, username: String? = nil, password: String? = nil, path: String? = nil) {
        let processedBaseURL: String
        if baseURL.hasPrefix("http://") || baseURL.hasPrefix("https://") {
            processedBaseURL = baseURL
        } else {
            processedBaseURL = "http://" + baseURL
        }
        let trimmedBaseURL = processedBaseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        var fullURLString = trimmedBaseURL
        if port != 80 && port != 443 {
            fullURLString += ":\(port)"
        }
        if let path, !path.isEmpty {
            let slashPrefixedPath = path.hasPrefix("/") ? path : "/\(path)"
            fullURLString += slashPrefixedPath
        }
        self.baseURL = URL(string: fullURLString)!
        let authString = (username ?? "") + ":" + (password ?? "")
        let authData = authString.data(using: .utf8)
        self.auth = authData?.base64EncodedString() ?? ""
    }
    public static func sortedFiles(_ files: [WebDAVFile], foldersFirst: Bool, includeSelf: Bool) -> [WebDAVFile] {
        var files = files
        if !includeSelf, !files.isEmpty {
            files.removeFirst()
        }
        if foldersFirst {
            files = files.filter { $0.isDirectory } + files.filter { !$0.isDirectory }
        }
        files = files.filter { !$0.fileName.hasPrefix(".") }
        return files
    }
}

extension WebDAV {
    func ping() async -> Bool {
        do {
            let _ = try await listFiles(atPath: "/")
            return true
        } catch {
            return false
        }
    }
    func listFiles(atPath path: String, foldersFirst: Bool = true, includeSelf: Bool = false) async throws -> [WebDAVFile] {
        guard var request = authorizedRequest(path: path, method: .propfind) else {
            throw WebDAVError.invalidCredentials
        }
        let body =
"""
<?xml version="1.0" encoding="utf-8" ?>
<D:propfind xmlns:D="DAV:">
    <D:prop>
        <D:getcontentlength/>
        <D:getlastmodified/>
        <D:getcontenttype />
        <D:resourcetype/>
    </D:prop>
</D:propfind>
"""
        request.httpBody = body.data(using: .utf8)
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let response = response as? HTTPURLResponse,
                  200...299 ~= response.statusCode,
                  let string = String(data: data, encoding: .utf8) else {
                throw WebDAVError.getError(response: response, error: nil) ?? WebDAVError.unsupported
            }
            let xml = XMLHash.config { config in
                config.shouldProcessNamespaces = true
            }.parse(string)
//            print(xml)
            let files = xml["multistatus"]["response"].all.compactMap { WebDAVFile(xml: $0, baseURL: self.baseURL, auth: self.auth) }
            let sortedFiles = WebDAV.sortedFiles(files, foldersFirst: foldersFirst, includeSelf: includeSelf)
            return sortedFiles
        } catch {
            throw WebDAVError.nsError(error)
        }
    }
    func deleteFile(atPath path: String) async throws -> Bool {
        guard let request = authorizedRequest(path: path, method: .delete) else {
            throw WebDAVError.invalidCredentials
        }
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let response = response as? HTTPURLResponse else {
                return false
            }
            return 200...299 ~= response.statusCode
        } catch {
            throw WebDAVError.nsError(error)
        }
    }
}

extension WebDAV {
    /// Creates an authorized URL request at the path and with the HTTP method specified.
    /// - Parameters:
    ///   - path: The path of the request
    ///   - method: The HTTP Method for the request.
    /// - Returns: The URL request if the credentials are valid (can be encoded as UTF-8).
    func authorizedRequest(path: String, method: HTTPMethod) -> URLRequest? {
        let url = self.baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("Basic \(self.auth)", forHTTPHeaderField: "Authorization")
        request.setValue("1", forHTTPHeaderField: "Depth")
        return request
    }
}
