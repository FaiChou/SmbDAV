//
//  FileListPage.swift
//  WebdavDemo
//
//  Created by FaiChou on 2023/12/23.
//

import Foundation
import SwiftUI

struct FileListPage: View {
    let drive: SmbDAVDrive
    let path: String
    @State private var data: [SmbDAVFile] = []
    @State private var searchText = ""
    @State private var isConfirming = false
    @State private var fileToBeDeleted: SmbDAVFile?
    var filteredResult: [SmbDAVFile] {
        if searchText.isEmpty {
            return data
        }
        return data.filter { $0.fileName.contains(searchText) }
    }
    init(drive: SmbDAVDrive, path: String) {
        self.drive = drive
        self.path = path
    }
    var body: some View {
        List(filteredResult) { item in
            NavigationLink {
                if item.isDirectory {
                    FileListPage(drive: drive, path: item.path)
                } else if item.extension == "png" {
                    ImagePreviewPage(item: item, drive: drive)
                } else if item.extension == "mp4" {
                    VideoPlayerPage(file: item, drive: drive)
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
                .contextMenu {
                    Button("Copy Name") {
                        copyToClipboard(text: item.fileName)
                    }
                    Button("Delete", role: .destructive) {
                        fileToBeDeleted = item
                        isConfirming = true
                    }
                }
            }
            .swipeActions(edge: .trailing) {
                Button(role: .destructive) {
                    delete(file: item)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
        .confirmationDialog(
            "Are you sure you want to delete this file?",
            isPresented: $isConfirming, presenting: fileToBeDeleted
        ) { file in
            Button("Delete", role: .destructive) {
                delete(file: file)
            }
            Button("Cancel", role: .cancel) {
                fileToBeDeleted = nil
            }
        }
        .searchable(text: $searchText)
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
                data = try await drive.listFiles(atPath: path)
            } catch {
                print("error=\(error)")
            }
        }
    }
    private func delete(file: SmbDAVFile) {
        Task {
            do {
                if try await drive.deleteFile(atPath: file.path) {
                    data = data.filter { $0.id != file.id }
                } else {
                    print("delete failed: \(file.fileName)")
                }
            } catch {
                print("error when delete \(file.fileName): \(error)")
            }
        }
    }
    private func copyToClipboard(text: String) {
        if text.isEmpty {
            return
        }
        let pasteboard = UIPasteboard.general
        pasteboard.string = text
    }
}
