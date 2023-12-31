//
//  VideoPlayerPage.swift
//  WebdavDemo
//
//  Created by FaiChou on 2023/12/28.
//

import SwiftUI
import AVKit

struct VideoPlayerPage: View {
    let file: SmbDAVFile
    let drive: SmbDAVDrive
    @State private var player: AVPlayer?
    var body: some View {
        VStack {
            if let player {
                VideoPlayer(player: player)
            } else {
                Text(file.fileName)
            }
        }
        .onAppear {
            if file.driveType == .WebDAV {
                let webdav = drive as! WebDAV
                let headers: [String: String] = [
                    "Authorization": "Basic \(webdav.auth)"
                ]
                guard let url = drive.getFileURL(file: file) else {
                    return
                }
                let asset = AVURLAsset(url: url, options: ["AVURLAssetHTTPHeaderFieldsKey": headers])
                let playerItem = AVPlayerItem(asset: asset)
                player = AVPlayer(playerItem: playerItem)
                player?.play()
            }
            try! AVAudioSession.sharedInstance().setCategory(.playback)
        }
        .ignoresSafeArea()
    }
}
