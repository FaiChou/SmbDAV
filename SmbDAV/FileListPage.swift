//
//  FileListPage.swift
//  WebdavDemo
//
//  Created by FaiChou on 2023/12/23.
//

import Foundation
import SwiftUI

struct FileListPage: View {
    let drive: DriveModel
    let path: String
    @State private var data: [WebDAVFile] = []
    private let webdav: WebDAV
    init(drive: DriveModel, path: String) {
        self.drive = drive
        self.path = path
        webdav = WebDAV(baseURL: drive.address,
                        port: drive.port,
                        username: drive.username,
                        password: drive.password,
                        path: drive.path)
    }
    var body: some View {
        List(data) { item in
            NavigationLink {
                if item.isDirectory {
                    FileListPage(drive: drive, path: item.path)
                } else if item.extension == "png" {
                    AsyncImageWithAuth(file: item) { image in
                        image.resizable().scaledToFit()
                    } placeholder: {
                        Text(item.fileName)
                    }
                } else if item.extension == "mp4" {
                    VideoPlayerPage(file: item)
                } else {
                    Text(item.fileName)
                }
            } label: {
                HStack {
                    Image(item.isDirectory ? "folder" : "file")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 40)
                        .padding(.trailing, 5)
                    VStack(alignment: .leading) {
                        Text(item.fileName)
                        Text(item.lastModified.formatted())
                            .foregroundStyle(.secondary)
                            .font(.footnote)
                    }
                    Spacer()
                    if !item.isDirectory {
                        Text(ByteCountFormatter().string(fromByteCount: item.size))
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                }
            }
        }
        .refreshable {
            loadData()
        }
        .navigationTitle(path == "/" ? "root" : path)
        .onAppear {
            loadData()
        }
    }
    private func loadData() {
        Task {
            do {
                data = try await webdav.listFiles(atPath: path)
            } catch {
                print("error=\(error)")
            }
        }
    }
}
