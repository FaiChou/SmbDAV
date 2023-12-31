//
//  DriveListModel.swift
//  WebdavDemo
//
//  Created by FaiChou on 2023/12/28.
//

import Foundation
import SwiftUI

let K_STORAGE_DriveListModelKEY = "K_STORAGE_DriveListModelKEY"

class DriveListModel: ObservableObject {
    static let shared = DriveListModel()
    @Published var drives: [DriveInfoModel] = [DriveInfoModel]() {
        didSet {
            storeInUserDefaults()
        }
    }
    private func storeInUserDefaults() {
        NSUbiquitousKeyValueStore.default.set(try? JSONEncoder().encode(drives), forKey: K_STORAGE_DriveListModelKEY)
    }
    private func restoreFromUserDefaults() {
        if let jsonData = NSUbiquitousKeyValueStore.default.data(forKey: K_STORAGE_DriveListModelKEY),
               let decoded = try? JSONDecoder().decode(Array<DriveInfoModel>.self, from: jsonData) {
            drives = decoded
        }
    }
    init() {
        restoreFromUserDefaults()
    }
    func addDrive(_ drive: DriveInfoModel) {
        let filtered = self.drives.filter { $0 == drive }
        if filtered.count == 0 {
            self.drives.append(drive)
        }
    }
    func clearAll() {
        self.drives = []
    }
    func delete(drive: DriveInfoModel) {
        self.drives = self.drives.filter { $0 != drive }
    }
    func getDrive(by id: UUID) -> DriveInfoModel? {
        return self.drives.first { $0.id == id }
    }
    func update(drive: DriveInfoModel) {
        if let index = self.drives.firstIndex(where: { $0 == drive }) {
            self.drives[index] = drive
        }
    }
}
