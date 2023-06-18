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
    @Published var isShowing: Bool = false
    @Published var image: Image?
    @Published var gallery: Gallery?
    @Published var mediaPopupGalleryImageLinks: [String] = []
    @Published var videoLink: String?
    @Published var contentType: ContentType = ContentType.link
    @Published var player: AVPlayer = AVPlayer()
    
    init() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
        } catch(let error) {
            print(error.localizedDescription)
        }
    }
}
