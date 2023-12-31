//
//  VideoPlayerPage.swift
//  WebdavDemo
//
//  Created by FaiChou on 2023/12/28.
//

import SwiftUI
import AVKit
import KSPlayer

struct VideoPlayerPage: View {
    let file: SmbDAVFile
    let drive: SmbDAVDrive
    var url: URL {
        return drive.getFileURL(file: file)!
    }
    var options: KSOptions {
        let options = KSOptions()
        if file.driveType == .WebDAV {
            let webdav = drive as! WebDAV
            options.appendHeader(["Authorization": "Basic \(webdav.auth)"])
        }
        return options
    }
    var body: some View {
        KSVideoPlayerView(url: url, options: options)
    }
}
