//
//  VideoPlayerPage.swift
//  WebdavDemo
//
//  Created by FaiChou on 2023/12/28.
//

import SwiftUI
import AVKit

struct VideoPlayerPage: View {
    let file: WebDAVFile
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
            let headers: [String: String] = [
                "Authorization": "Basic \(file.auth)"
            ]
            let asset = AVURLAsset(url: file.url, options: ["AVURLAssetHTTPHeaderFieldsKey": headers])
            let playerItem = AVPlayerItem(asset: asset)
            player = AVPlayer(playerItem: playerItem)
            player?.play()
        }
        .ignoresSafeArea()
    }
}
