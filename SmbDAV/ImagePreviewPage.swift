//
//  ImagePreviewPage.swift
//  SmbDAV
//
//  Created by FaiChou on 2023/12/29.
//

import SwiftUI

struct Photo: Transferable {
    static var transferRepresentation: some TransferRepresentation {
        ProxyRepresentation(exporting: \.image)
    }
    public var image: Image
    public var caption: String
}

struct ImagePreviewPage: View {
    let item: SmbDAVFile
    let drive: SmbDAVDrive
    @State private var img: Photo?
    var body: some View {
        SmbDAVAsyncImage(file: item, drive: drive) { image in
            image.resizable().scaledToFit().onAppear {
                img = Photo(image: image, caption: item.name)
            }
        } placeholder: {
            Text(item.name)
        }
        .toolbar {
            if let photo = img {
                ShareLink(
                    item: photo,
                    preview: SharePreview(
                        photo.caption,
                        image: photo.image
                    )
                )
            }
        }
    }
}
