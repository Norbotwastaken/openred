//
//  PopupViewModel.swift
//  openred
//
//  Created by Norbert Antal on 6/15/23.
//

import Foundation
import SwiftUI
import AVKit

class PopupViewModel: ObservableObject {
    @Published var mediaPopupShowing: Bool = false
    @Published var mediaPopupImage: Image?
    @Published var mediaPopupGalleryImages: [Image] = []
    @Published var videoLink: String?
    @Published var contentType: ContentType = ContentType.link
    @Published var player: AVPlayer = AVPlayer()
}
