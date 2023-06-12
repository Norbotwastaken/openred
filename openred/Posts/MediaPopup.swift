//
//  MediaPopup.swift
//  openred
//
//  Created by Norbert Antal on 6/12/23.
//

import Foundation
import SwiftUI
import AVKit
import ExytePopupView

struct MediaPopupContent: View {
    @Binding var mediaPopupShowing: Bool
    @Binding var mediaPopupImage: Image?
    @Binding var videoLink: String?
    @Binding var contentType: ContentType
    @Binding var player: AVPlayer
    @State var toolbarVisible = false
    
//    var videoLink: String = "https://v.redd.it/8twxap1nxc5b1/HLSPlaylist.m3u8"
//    var videoLink: String = "https://i.imgur.com/a41akKA.mp4"
    
    var body: some View {
        ZStack {
            if (contentType == ContentType.video) {
                VideoPlayer(player: player)
                    .onAppear() {
                        // TODO: missing link
                        player = AVPlayer(url: URL(string: videoLink ?? "")!)
                        player.isMuted = true
                        player.play()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                if toolbarVisible {
                    ZStack {
                        Rectangle()
                            .fill(Color.black)
                            .opacity(0.8)
                            .frame(maxWidth: .infinity, maxHeight: 45, alignment: .top)
                        Image(systemName: "xmark")
                            .font(.system(size: 30))
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                            .foregroundColor(Color.white)
                            .opacity(0.6)
                            .padding(EdgeInsets(top: 6, leading: 22, bottom: 0, trailing: 0))
                            .onTapGesture {
                                mediaPopupShowing = false
                                player.pause()
                            }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
            } else if (contentType == ContentType.image) {
                ZoomableScrollView {
                    mediaPopupImage!
                        .resizable()
                        .scaledToFit()
                        .preferredColorScheme(.dark)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                if toolbarVisible {
                    ZStack {
                        Rectangle()
                            .fill(Color.black)
                            .opacity(0.8)
                            .frame(maxWidth: .infinity, maxHeight: 45, alignment: .top)
                        Image(systemName: "xmark")
                            .font(.system(size: 30))
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                            .foregroundColor(Color.white)
                            .opacity(0.6)
                            .padding(EdgeInsets(top: 30, leading: 22, bottom: 0, trailing: 0))
                            .onTapGesture {
                                mediaPopupShowing = false
//                                player.pause()
                            }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    ZStack {
                        Rectangle()
                            .fill(Color.black)
                            .opacity(0.8)
                            .frame(maxWidth: .infinity, maxHeight: 50, alignment: .bottom)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                }
            }
        }
        .onTapGesture {
            toolbarVisible.toggle()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
    }
}
