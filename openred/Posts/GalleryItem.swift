//
//  GalleryItem.swift
//  openred
//
//  Created by Norbert Antal on 6/15/23.
//

import Foundation

struct Gallery: Codable {
    var text: String?
    var items: [GalleryItem]
    
    init(galleryData: [JSONPostGalleryDataItem], galleryItems: [String : JSONPostMediaMetaDataItem], text: String? = nil) {
        self.items = []
        for galleryDataElement in galleryData {
            self.items.append(GalleryItem(galleryData: galleryDataElement, galleryItem: galleryItems[galleryDataElement.media_id]!))
        }
        self.text = text
    }
}

struct GalleryItem: Identifiable, Codable {
    var id: String
    var type: String
    var previewLink: String
    var fullLink: String
    var caption: String?
    var url: String?
    
//    init(_ previewLink: String, fullLink: String, caption: String?) {
//        self.id = previewLink
//        self.previewLink = previewLink
//        self.fullLink = fullLink
//        self.caption = caption
//    }
    
    init(galleryData: JSONPostGalleryDataItem, galleryItem: JSONPostMediaMetaDataItem) {
        self.id = String(galleryData.id)
        self.type = galleryItem.e!
        // preview is second to last preview item or full sized image
        self.previewLink = galleryItem.p[max(galleryItem.p.count - 2, 0)].u ?? galleryItem.s!.u!
        if self.type == "AnimatedImage" {
            self.fullLink = galleryItem.s!.mp4!
        } else {
            self.fullLink = galleryItem.s!.u!
        }
        self.caption = galleryData.caption
        self.url = galleryData.outbound_url
    }
}
