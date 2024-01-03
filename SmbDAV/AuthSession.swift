//
//  AuthSession.swift
//  SmbDAV
//
//  Created by 周辉 on 2024/1/3.
//

import Foundation

class SessionDelegate: NSObject, URLSessionTaskDelegate {
    let user: String
    let password: String
    init(user: String, password: String) {
        self.user = user
        self.password = password
        super.init()
    }
    func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge) async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodHTTPBasic ||
            challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodNTLM {
            let credential = URLCredential(user: self.user, password: self.password, persistence: .forSession)
            return (.useCredential, credential)
        }
        return (.performDefaultHandling, nil)
    }
}
