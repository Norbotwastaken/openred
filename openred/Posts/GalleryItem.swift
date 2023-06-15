//
//  GalleryItem.swift
//  openred
//
//  Created by Norbert Antal on 6/15/23.
//

import Foundation

struct Gallery: Codable {
    var textHTML: String?
    var items: [GalleryItem]
}

struct GalleryItem: Identifiable, Codable {
    var id: String
    var previewLink: String
    var fullLink: String
    var caption: String?
    
    init(_ previewLink: String, fullLink: String, caption: String?) {
        self.id = previewLink
        self.previewLink = previewLink
        self.fullLink = fullLink
        self.caption = caption
    }
}
