//
//  WebDAV.swift
//  WebDAV-Swift
//
//  Created by Isaac Lyons on 10/29/20.
//

import Foundation
import SWXMLHash
import UIKit

enum WebDAVError: Error {
    /// The credentials or path were unable to be encoded.
    /// No network request was called.
    case invalidCredentials
    /// The credentials were incorrect.
    case unauthorized
    /// The server was unable to store the data provided.
    case insufficientStorage
    /// The server does not support this feature.
    case unsupported
    /// Another unspecified Error occurred.
    case nsError(Error)
    /// The returned value is simply a placeholder.
    case placeholder

    static func getError(statusCode: Int?, error: Error?) -> WebDAVError? {
        if let statusCode = statusCode {
            switch statusCode {
            case 200...299: // Success
                return nil
            case 401...403:
                return .unauthorized
            case 507:
                return .insufficientStorage
            default:
                break
            }
        }
    
        if let error = error {
            return .nsError(error)
        }
        return nil
    }

    static func getError(response: URLResponse?, error: Error?) -> WebDAVError? {
        getError(statusCode: (response as? HTTPURLResponse)?.statusCode, error: error)
    }
}

class WebDAV: SmbDAVDrive {
    var baseURL: URL
    var auth: String
    init(baseURL: String, port: Int, username: String, password: String, path: String) {
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
        if !path.isEmpty {
            let slashPrefixedPath = path.hasPrefix("/") ? path : "/\(path)"
            fullURLString += slashPrefixedPath
        }
        self.baseURL = URL(string: fullURLString)!
        let authString = username + ":" + password
        let authData = authString.data(using: .utf8)
        self.auth = authData?.base64EncodedString() ?? ""
    }
    public static func sortedFiles(_ files: [SmbDAVFile]) -> [SmbDAVFile] {
        var files = files
        // remove self
        if !files.isEmpty {
            files.removeFirst()
        }
        // folder first
        files = files.filter { $0.isDirectory } + files.filter { !$0.isDirectory }
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
    func listFiles(atPath path: String) async throws -> [SmbDAVFile] {
        guard var request = authorizedRequest(path: path, method: "PROPFIND") else {
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
            let files = xml["multistatus"]["response"].all.compactMap { SmbDAVFile(xml: $0, baseURL: self.baseURL) }
            let sortedFiles = WebDAV.sortedFiles(files)
            return sortedFiles
        } catch {
            throw WebDAVError.nsError(error)
        }
    }
    func deleteFile(atPath path: String) async throws -> Bool {
        guard let request = authorizedRequest(path: path, method: "DELETE") else {
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
    func getImage(atPath path: String) async -> UIImage? {
        let url = self.baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.addValue("Basic \(self.auth)", forHTTPHeaderField: "Authorization")
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { fatalError("Error while fetching attchment") }
            return UIImage(data: data)
        } catch {
            return nil
        }
    }
}

extension WebDAV {
    func authorizedRequest(path: String, method: String) -> URLRequest? {
        let url = self.baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Basic \(self.auth)", forHTTPHeaderField: "Authorization")
        request.setValue("1", forHTTPHeaderField: "Depth")
        return request
    }
}
