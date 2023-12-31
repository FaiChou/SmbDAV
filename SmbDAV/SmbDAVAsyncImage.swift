//
//  SmbDAVAsyncImage.swift
//  WebdavDemo
//
//  Created by 周辉 on 2023/12/27.
//

import SwiftUI

struct SmbDAVAsyncImage<Content: View, Placeholder: View>: View {
    @State var uiImage: UIImage?
    let file: SmbDAVFile
    let drive: SmbDAVDrive
    let content: (Image) -> Content
    let placeholder: () -> Placeholder
    init(
        file: SmbDAVFile,
        drive: SmbDAVDrive,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ){
        self.file = file
        self.drive = drive
        self.content = content
        self.placeholder = placeholder
    }
    var body: some View {
        if let uiImage = uiImage {
            content(Image(uiImage: uiImage))
        } else {
            placeholder()
                .task {
                    self.uiImage = await drive.getImage(file: file)
                }
        }
    }
}
