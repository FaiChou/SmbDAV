//
//  Home.swift
//  WebdavDemo
//
//  Created by FaiChou on 2023/12/28.
//

import SwiftUI

struct Home: View {
    @StateObject private var model = DriveListModel()
    @State private var presentedPage: [DriveInfoModel] = []
    @State private var showAddView = false
    @State private var showDriveInfoDetails = true
    var body: some View {
        NavigationStack(path: $presentedPage) {
            List(model.drives, id: \.self) { item in
                NavigationLink {
                    switch item.driveType {
                    case .WebDAV:
                        FileListPage(drive: WebDAV(baseURL: item.address,
                                                    port: item.port,
                                                    username: item.username,
                                                    password: item.password,
                                                    subfolder: item.subfolder),
                                     path: "/")
                    case .smb:
                        FileListPage(drive: SMB(baseURL: item.address,
                                                port: item.port,
                                                username: item.username,
                                                password: item.password,
                                                subfolder: item.subfolder),
                                     path: "/")
                    case .nfs:
                        FileListPage(drive: NFS(baseURL: item.address, share: item.subfolder)!, path: "/")
                    }
                } label: {
                    HStack {
                        Image(getDriveImageName(driveType: item.driveType))
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                        VStack(alignment: .leading) {
                            Text(item.alias)
                            if showDriveInfoDetails {
                                Text(item.driveDetail)
                                    .foregroundStyle(.secondary)
                                    .font(.footnote)
                            }
                        }
                        Spacer()
                    }
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        model.delete(drive: item)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    Button {
                        presentedPage = [item]
                    } label: {
                        Label("Edit", systemImage: "square.and.pencil")
                    }
                }
            }
            .navigationDestination(for: DriveInfoModel.self) {
                DriveSetupPage(listModel: model, driveInfoModel: $0)
            }
            .navigationTitle("Drives")
            .toolbar {
                Button {
                    showAddView = true
                } label: {
                    Image(systemName: "plus")
                        .resizable()
                        .foregroundStyle(.blue)
                }
            }
            .sheet(isPresented: $showAddView) {
                DriveSetupPage(listModel: model)
            }
        }
        .onShake {
            showDriveInfoDetails.toggle()
        }
    }
    private func getDriveImageName(driveType: DriveType) -> String {
        switch driveType {
        case .WebDAV:
            return "webdav"
        case .smb:
            return "smb"
        case .nfs:
            return "nfs"
        }
    }
}
