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
    @Published var drives: [DriveModel] = [DriveModel]() {
        didSet {
            storeInUserDefaults()
        }
    }
    private func storeInUserDefaults() {
        NSUbiquitousKeyValueStore.default.set(try? JSONEncoder().encode(drives), forKey: K_STORAGE_DriveListModelKEY)
    }
    private func restoreFromUserDefaults() {
        if let jsonData = NSUbiquitousKeyValueStore.default.data(forKey: K_STORAGE_DriveListModelKEY),
               let decoded = try? JSONDecoder().decode(Array<DriveModel>.self, from: jsonData) {
            drives = decoded
        }
    }
    init() {
        restoreFromUserDefaults()
    }
    func addDrive(_ drive: DriveModel) {
        let filtered = self.drives.filter { $0 == drive }
        if filtered.count == 0 {
            self.drives.append(drive)
        }
    }
    func clearAll() {
        self.drives = []
    }
    func delete(drive: DriveModel) {
        self.drives = self.drives.filter { $0 != drive }
    }
    func getDrive(by id: UUID) -> DriveModel? {
        return self.drives.first { $0.id == id }
    }
    func update(drive: DriveModel) {
        if let index = self.drives.firstIndex(where: { $0 == drive }) {
            self.drives[index] = drive
        }
    }
}
