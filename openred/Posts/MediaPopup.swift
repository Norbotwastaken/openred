//
//  MediaPopup.swift
//  openred
//
//  Created by Norbert Antal on 6/12/23.
//

import Foundation
import SwiftUI
import AVFoundation
import VideoPlayer

struct MediaPopupContent: View {
    @Binding var mediaPopupShowing: Bool
    @Binding var mediaPopupImage: Image?
    @Binding var videoLink: String?
    @Binding var contentType: ContentType
    @Binding var player: AVPlayer
    @State var toolbarVisible = false
    @State private var play: Bool = true
    @State private var time: CMTime = .zero
    @State private var autoReplay: Bool = true
    @State private var mute: Bool = false
    @State private var stateText: String = ""
    @State private var totalDuration: Double = 0
    
    var body: some View {
        ZStack {
            if (contentType == ContentType.video) {
                ZStack {
                    Rectangle()
                        .fill(Color.black)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    ProgressView()
                    VideoPlayer(url: URL(string: videoLink ?? "")!, play: $play, time: $time)
                        .contentMode(.scaleAspectFit)
                        .autoReplay(autoReplay)
                        .mute(mute)
//                        .onBufferChanged { progress in print("onBufferChanged \(progress)") }
//                        .onPlayToEndTime { print("onPlayToEndTime") }
//                        .onReplay { print("onReplay") }
                        .onStateChanged { state in
                            switch state {
                            case .loading:
                                self.stateText = "Loading..."
                            case .playing(let totalDuration):
                                self.stateText = "Playing!"
                                self.totalDuration = totalDuration
                            case .paused(let playProgress, let bufferProgress):
                                self.stateText = "Paused: play \(Int(playProgress * 100))% buffer \(Int(bufferProgress * 100))%"
                            case .error(let error):
                                self.stateText = "Error: \(error)"
                            }
                        }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onDisappear { self.play = false }
                    Text("\(getTimeRemainingString())")
                        .foregroundColor(Color(red: 242, green: 242, blue: 247))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                        .padding(EdgeInsets(top: 0, leading: 0, bottom: 30, trailing: 30))
                    if toolbarVisible {
                        ZStack {
                            Rectangle()
                                .fill(Color.black)
                                .opacity(0.75)
                                .cornerRadius(8)
                                .frame(width: 340, height: 80)
                            HStack {
                                Button() {
                                    self.autoReplay.toggle()
                                } label: {
                                    self.autoReplay ? Image(systemName: "arrow.clockwise.circle.fill")
                                        .resizable()
                                        .frame(width: 30, height: 30)
                                        .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10)) :
                                    Image(systemName: "arrow.clockwise.circle")
                                        .resizable()
                                        .frame(width: 30, height: 30)
                                        .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
                                }
                                .foregroundColor(Color.gray)
                                Button() {
                                    self.time = CMTimeMakeWithSeconds(max(0, self.time.seconds - 10), preferredTimescale: self.time.timescale)
                                } label: {
                                    Image(systemName: "gobackward.10")
                                        .resizable()
                                        .frame(width: 30, height: 30)
                                        .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
                                }
                                .foregroundColor(Color.gray)
                                Button() {
                                    self.play.toggle()
                                } label: {
                                    self.play ? Image(systemName: "pause.fill")
                                        .resizable()
                                        .frame(width: 40, height: 40)
                                        .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10)) :
                                    Image(systemName: "play.fill")
                                        .resizable()
                                        .frame(width: 40, height: 40)
                                        .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
                                }
                                .foregroundColor(Color.gray)
                                Button() {
                                    self.time = CMTimeMakeWithSeconds(min(self.totalDuration, self.time.seconds + 10), preferredTimescale: self.time.timescale)
                                } label: {
                                    Image(systemName: "goforward.10")
                                        .resizable()
                                        .frame(width: 30, height: 30)
                                        .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
                                }
                                .foregroundColor(Color.gray)
                                Button() {
                                    self.mute.toggle()
                                } label: {
                                    self.mute ? Image(systemName: "speaker.slash.fill")
                                        .resizable()
                                        .frame(width: 30, height: 30)
                                        .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10)) :
                                    Image(systemName: "speaker.wave.2.fill")
                                        .resizable()
                                        .frame(width: 30, height: 30)
                                        .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
                                }
                                .foregroundColor(Color.gray)
                            }
                            .frame(width: 340, height: 80)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                        .padding(EdgeInsets(top: 0, leading: 0, bottom: 80, trailing: 0))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                if toolbarVisible {
                    ZStack {
                        Rectangle()
                            .fill(Color.black)
                            .opacity(0.8)
                            .frame(maxWidth: .infinity, maxHeight: 65, alignment: .top)
                        Image(systemName: "xmark")
                            .font(.system(size: 30))
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                            .foregroundColor(Color.white)
                            .opacity(0.6)
                            .padding(EdgeInsets(top: 30, leading: 22, bottom: 0, trailing: 0))
                            .onTapGesture {
                                mediaPopupShowing = false
                                player.pause()
                            }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
            } else if (contentType == ContentType.image) {
                ZStack {
                    Rectangle()
                        .fill(Color.black)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    ZoomableScrollView {
                        mediaPopupImage!
                            .resizable()
                            .scaledToFit()
                            .preferredColorScheme(.dark)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                if toolbarVisible {
                    ZStack {
                        Rectangle()
                            .fill(Color.black)
                            .opacity(0.8)
                            .frame(maxWidth: .infinity, maxHeight: 65, alignment: .top)
                        Image(systemName: "xmark")
                            .font(.system(size: 30))
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                            .foregroundColor(Color.white)
                            .opacity(0.6)
                            .padding(EdgeInsets(top: 30, leading: 22, bottom: 0, trailing: 0))
                            .onTapGesture {
                                mediaPopupShowing = false
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
    
    func getTimeRemainingString() -> String {
        var timeLeft = time.seconds.distance(to: totalDuration)
        let m = Int(timeLeft / 60)
        let s = Int(timeLeft.truncatingRemainder(dividingBy: 60))
        return String(format: "-%d:%02d", arguments: [m, s])
    }
}
