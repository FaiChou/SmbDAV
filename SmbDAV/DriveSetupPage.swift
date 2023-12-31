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
    var driveInfoModel: DriveInfoModel?
    @State private var driveType: DriveType = .WebDAV
    @State private var alias: String = ""
    @State private var address: String = ""
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var port: Int = 80
    @State private var subfolder: String = ""
    @State private var isSmbConfirming = false
    @State private var smbShares: [String] = []
    init(listModel: DriveListModel) {
        _listModel = .init(wrappedValue: listModel)
    }
    init(listModel: DriveListModel, driveInfoModel: DriveInfoModel) {
        _listModel = .init(wrappedValue: listModel)
        self.driveInfoModel = driveInfoModel
        _driveType = .init(initialValue: driveInfoModel.driveType)
        _alias = .init(initialValue: driveInfoModel.alias)
        _address = .init(initialValue: driveInfoModel.address)
        _username = .init(initialValue: driveInfoModel.username)
        _password = .init(initialValue: driveInfoModel.password)
        _port = .init(initialValue: driveInfoModel.port)
        _subfolder = .init(initialValue: driveInfoModel.subfolder)
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
                        TextField(driveType == .WebDAV ? "http[s]://192.168.11.199" : "192.168.11.199", text: $address)
                            .keyboardType(.URL)
                            .autocapitalization(.none)
                        TextField("Username", text: $username)
                        SecureField("Password", text: $password)
                    }
                    Section(header: Text("Advanced")) {
                        TextField("Port", value: $port, formatter: NumberFormatter())
                            .keyboardType(.numberPad)
                        TextField("Path, eg: /subfolder", text: $subfolder)
                    }
                    Button("Submit") {
                        handleSubmit()
                    }
                }
                .onChange(of: driveType) { _, newValue in
                    if newValue == .smb {
                        port = 445 // default smb port
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
        .confirmationDialog(
            "Please select one share to connect",
            isPresented: $isSmbConfirming
        ) {
            ForEach(smbShares, id: \.self) {share in
                Button(share) {
                    var info = DriveInfoModel(driveType: driveType, alias: alias, address: address, username: username, password: password, port: port, subfolder: share)
                    if let driveInfoModel {
                        info.id = driveInfoModel.id
                        listModel.update(drive: info)
                    } else {
                        listModel.addDrive(info)
                    }
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) {
                smbShares = []
            }
        } message: {
            Text("Please select one share to connect")
        }
        .navigationTitle("Drive Setup")
    }
    private func handleSubmit() {
        guard !address.isEmpty else {
            showError = true
            return
        }
        showLoading = true
        Task {
            var drive: SmbDAVDrive
            switch driveType {
            case .WebDAV:
                drive = WebDAV(baseURL: address, port: port, username: username, password: password, subfolder: subfolder)
            case .smb:
                drive = SMB(baseURL: address, port: port, username: username, password: password, subfolder: subfolder)
                if subfolder.isEmpty {
                    let smb = drive as! SMB
                    if let shares = try? await smb.listShares() {
                        showLoading = false
                        if shares.isEmpty {
                            showError = true
                        } else {
                            smbShares = shares
                            isSmbConfirming = true
                        }
                    }
                    return
                }
            }
            if await drive.ping() {
                showLoading = false
                var info = DriveInfoModel(driveType: driveType, alias: alias, address: address, username: username, password: password, port: port, subfolder: subfolder)
                if let driveInfoModel {
                    info.id = driveInfoModel.id
                    listModel.update(drive: info)
                } else {
                    listModel.addDrive(info)
                }
                dismiss()
            } else {
                showLoading = false
                showError = true
            }
        }
    }
}
