//
//  FileListPage.swift
//  WebdavDemo
//
//  Created by FaiChou on 2023/12/23.
//

import Foundation
import SwiftUI

struct FileListPage: View {
    @EnvironmentObject var settings: SettingsModel
    let drive: SmbDAVDrive
    let path: String
    @State private var data: [SmbDAVFile] = []
    @State private var searchText = ""
    @State private var isConfirming = false
    @State private var fileToBeDeleted: SmbDAVFile?
    var processedData: [SmbDAVFile] {
        var d = data
        if settings.folderFirst {
            d = d.filter { $0.isDirectory } + d.filter { !$0.isDirectory }
        }
        if !settings.showHiddenFiles {
            d = d.filter { !$0.name.hasPrefix(".") }
        }
        return d
    }
    var filteredResult: [SmbDAVFile] {
        if searchText.isEmpty {
            return processedData
        }
        return processedData.filter { $0.name.contains(searchText) }
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
                    Text(item.name)
                }
            } label: {
                HStack {
                    Image(item.isDirectory ? "folder" : "file")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 40)
                        .padding(.trailing, 5)
                    VStack(alignment: .leading) {
                        Text(item.name)
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
                        copyToClipboard(text: item.name)
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
        .toolbar {
            Menu {
                Toggle(isOn: settings.$folderFirst) {
                    Label("Folder First", systemImage: "folder")
                }
                Toggle(isOn: settings.$showHiddenFiles) {
                    Label("Show Hidden files", systemImage: settings.showHiddenFiles ? "eye" : "eye.slash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
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
                if try await drive.deleteFile(file: file) {
                    data = data.filter { $0.id != file.id }
                } else {
                    print("delete failed: \(file.name)")
                }
            } catch {
                print("error when delete \(file.name): \(error)")
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
