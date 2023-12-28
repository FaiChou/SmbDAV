//
//  DriveSetupPage.swift
//  WebdavDemo
//
//  Created by FaiChou on 2023/12/22.
//

import SwiftUI

struct DriveSetupPage: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showLoading = false
    @State private var showError = false
    @StateObject var listModel: DriveListModel
    var driveModel: DriveModel?
    @State private var driveType: DriveType = .WebDAV
    @State private var alias: String = ""
    @State private var address: String = ""
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var port: Int = 80
    @State private var path: String = ""
    init(listModel: DriveListModel) {
        _listModel = .init(wrappedValue: listModel)
    }
    init(listModel: DriveListModel, driveModel: DriveModel) {
        _listModel = .init(wrappedValue: listModel)
        self.driveModel = driveModel
        _driveType = .init(initialValue: driveModel.driveType)
        _alias = .init(initialValue: driveModel.alias)
        _address = .init(initialValue: driveModel.address)
        _username = .init(initialValue: driveModel.username)
        _password = .init(initialValue: driveModel.password)
        _port = .init(initialValue: driveModel.port)
        _path = .init(initialValue: driveModel.path)
    }
    var body: some View {
        NavigationView {
            ZStack {
                Form {
                    Section(header: Text("Basic")) {
                        Picker("Drive Type", selection: $driveType) {
                            ForEach(DriveType.allCases) { type in
                                Text(type.rawValue)
                            }
                        }
                        TextField("Alias", text: $alias)
                        TextField("http[s]://192.168.11.199", text: $address)
                            .keyboardType(.URL)
                            .autocapitalization(.none)
                        TextField("Username", text: $username)
                        SecureField("Password", text: $password)
                    }
                    Section(header: Text("Advanced")) {
                        #if os(macOS)
                        TextField("Port", value: $port, formatter: NumberFormatter())
                        #else
                        TextField("Port", value: $port, formatter: NumberFormatter())
                            .keyboardType(.numberPad)
                        #endif
                        TextField("Path, eg: /subfolder", text: $path)
                    }
                    Button("Submit") {
                        guard !address.isEmpty else {
                            showError = true
                            return
                        }
                        showLoading = true
                        Task {
                            let webdav = WebDAV(baseURL: address,
                                                port: port,
                                                username: username,
                                                password: password,
                                                path: path)
                            if await webdav.ping() {
                                showLoading = false
                                var drive = DriveModel(driveType: driveType, alias: alias, address: address, username: username, password: password, port: port, path: path)
                                if let driveModel {
                                    drive.id = driveModel.id
                                    listModel.update(drive: drive)
                                } else {
                                    listModel.addDrive(drive)
                                }
                                dismiss()
                            } else {
                                showLoading = false
                                showError = true
                            }
                        }
                    }
                }
                .alert(
                    "Validate failed",
                    isPresented: $showError
                ) {
                    Button("OK") {}
                }
                if showLoading {
                    VStack {
                        ProgressView()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.gray.opacity(0.4))
                }
            }
        }
        .navigationTitle("Drive Setup")
    }
}
