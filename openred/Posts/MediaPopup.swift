//
//  MediaPopup.swift
//  openred
//
//  Created by Norbert Antal on 6/12/23.
//

import Foundation
import SwiftUI
import AVFoundation
import AVKit
import VideoPlayer

struct MediaPopupContent: View {
    @EnvironmentObject var popupViewModel: PopupViewModel
    @EnvironmentObject var settingsModel: SettingsModel
    @Environment(\.dismiss) var dismiss
    @State var toolbarVisible = false
    @State private var play: Bool = false
    @State private var time: CMTime = .zero
    @State private var autoReplay: Bool = true
    @State private var mute: Bool = false
    @State private var stateText: String = ""
    @State private var totalDuration: Double = 0
    @State private var showingSaveDialog = false
    @State private var currentImageLink: String?
    @State private var activeGalleryTab: Int = 0
    @State private var offset = CGSize.zero
    @State private var videoBarOffset: Double = 0
    @State private var videoBarDetached: Bool = false
    @State private var showProgressView = true
    
    @State var player = AVPlayer()
    var body: some View {
        ZStack {
            if (popupViewModel.contentType == ContentType.video) {
                ZStack {
                    Rectangle()
                        .fill(Color.black)
                        .opacity(Double(1) - (abs(offset.height) / Double(250)))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    if showProgressView {
                        ProgressView()
                            .onAppear{
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                    showProgressView = false
                                }
                            }
                    }
                    VideoPlayer(url: URL(string: popupViewModel.videoLink ?? "")!, play: $play, time: $time)
                        .contentMode(.scaleAspectFit)
                        .autoReplay(autoReplay)
                        .mute(mute)
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
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
                            self.play = true
                        })
                    }
                    .onDisappear { self.play = false }
                    .offset(x: offset.width, y: offset.height)
                    .gesture(
                        DragGesture()
                            .onChanged { gesture in
                                offset = gesture.translation
                            }
                            .onEnded { _ in
                                if abs(offset.height) > 130 {
                                    dismissPopup()
                                } else {
                                    withAnimation{offset = .zero}
                                }
                            }
                    )
                    Text("\(getTimeRemainingString())")
                        .foregroundColor(Color(red: 242, green: 242, blue: 247))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                        .padding(EdgeInsets(top: 0, leading: 0, bottom: 30, trailing: 30))
                    if toolbarVisible {
                        ZStack {
                            Rectangle()
                                .fill(Color(UIColor.systemGray6))
                                .opacity(0.2)
                                .background(.ultraThinMaterial)
                                .background(VisualEffect(style: .systemUltraThinMaterial).opacity(0.6))
                                .cornerRadius(8)
                                .frame(width: 340, height: 120)
                            VStack {
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerSize: CGSize(width: 8, height: 8))
                                        .frame(width: 300, height: 10)
                                        .background(.clear)
                                        .foregroundColor(Color(UIColor.systemGray6))
                                    RoundedRectangle(cornerSize: CGSize(width: 8, height: 8))
                                        .frame(width: 10 + (videoBarDetached ? videoBarOffset :
                                                                300 * (time.seconds / totalDuration)), height: 10, alignment: .leading)
                                        .background(.clear)
                                        .foregroundColor(Color.primary)
                                    Circle()
                                        .foregroundColor(Color.primary)
                                        .opacity(1)
                                        .frame(width: 20, height: 20, alignment: .leading)
                                        .padding(EdgeInsets(top: 0, leading: videoBarDetached ? videoBarOffset :
                                                                300 * (time.seconds / totalDuration), bottom: 0, trailing: 0))
                                        .gesture(
                                            DragGesture()
                                                .onChanged { gesture in
                                                    play = false
                                                    videoBarDetached = true
                                                    videoBarOffset = max(0, min(300, 300 * (time.seconds / totalDuration) + gesture.translation.width))
                                                }
                                                .onEnded { _ in
                                                    self.time = CMTimeMakeWithSeconds(videoBarOffset * (totalDuration / 300), preferredTimescale: self.time.timescale)
                                                    play = true
                                                    videoBarDetached = false
                                                }
                                        )
                                }
                                .padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
                                .frame(maxWidth: .infinity, maxHeight: 20, alignment: .leading)
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
                                    Button() {
                                        self.time = CMTimeMakeWithSeconds(max(0, self.time.seconds - 10), preferredTimescale: self.time.timescale)
                                    } label: {
                                        Image(systemName: "gobackward.10")
                                            .resizable()
                                            .frame(width: 30, height: 30)
                                            .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
                                    }
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
                                    Button() {
                                        self.time = CMTimeMakeWithSeconds(min(self.totalDuration, self.time.seconds + 10), preferredTimescale: self.time.timescale)
                                    } label: {
                                        Image(systemName: "goforward.10")
                                            .resizable()
                                            .frame(width: 30, height: 30)
                                            .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
                                    }
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
                                }
                                .foregroundColor(.primary)
                                .opacity(0.8)
                                .frame(width: 340, height: 80)
                            }
                            .foregroundColor(.primary)
                            .frame(width: 340, height: 120)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                        .padding(EdgeInsets(top: 0, leading: 0, bottom: 80, trailing: 0))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .task {
                    mute = !settingsModel.unmuteVideos
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
                                popupViewModel.isShowing = false
                                popupViewModel.player.pause()
                                dismiss()
                            }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
            } else if (popupViewModel.contentType == ContentType.image) {
                ZStack {
                    Rectangle()
                        .fill(Color.black)
                        .opacity(Double(1) - (abs(offset.height) / Double(250)))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    AsyncImage(url: URL(string: popupViewModel.fullImageLink! )) { image in
                        GeometryReader { proxy in
                            image.image?
                                .resizable()
                                .scaledToFit()
                                .frame(width: proxy.size.width, height: proxy.size.height)
                                .clipShape(Rectangle())
                                .modifier(ImageModifier(contentSize: CGSize(width: proxy.size.width, height: proxy.size.height)))
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .offset(x: offset.width, y: offset.height)
                    .gesture(
                        DragGesture()
                            .onChanged { gesture in
                                offset = gesture.translation
                            }
                            .onEnded { _ in
                                if abs(offset.height) > 130 {
                                    dismissPopup()
                                } else {
                                    withAnimation{offset = .zero}
                                }
                            }
                    )
                }
                if toolbarVisible {
                    ZStack {
                        Rectangle()
                            .fill(Color.black)
                            .opacity(0.6)
                            .frame(maxWidth: .infinity, maxHeight: 80, alignment: .top)
                        HStack {
                            Image(systemName: "xmark")
                                .font(.system(size: 30))
                                .frame(maxWidth: .infinity, alignment: .topLeading)
                                .foregroundColor(Color.white)
                                .opacity(0.6)
                                .padding(EdgeInsets(top: 40, leading: 22, bottom: 0, trailing: 0))
                                .onTapGesture {
                                    popupViewModel.isShowing = false
                                    dismiss()
                                }
                            Image(systemName: "arrow.down.square")
                                .font(.system(size: 30))
                                .frame(maxWidth: .infinity, alignment: .topTrailing)
                                .foregroundColor(Color.white)
                                .opacity(0.6)
                                .padding(EdgeInsets(top: 40, leading: 0, bottom: 0, trailing: 22))
                                .onTapGesture {
                                    showingSaveDialog = true
                                }
                                .alert("Save image to library?", isPresented: $showingSaveDialog) {
                                    SaveImageAlert(showingSaveDialog: $showingSaveDialog, link: popupViewModel.fullImageLink)
                                }
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
            } else if (popupViewModel.contentType == ContentType.gallery) {
                ZStack {
                    Rectangle()
                        .fill(Color.black)
                        .opacity(Double(1) - (abs(offset.height) / Double(250)))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    TabView(selection: $activeGalleryTab) {
                        ForEach(popupViewModel.gallery!.items.indices) { i in
                            ZStack {
                                AsyncImage(url: URL(string: popupViewModel.gallery!.items[i].fullLink )) { image in
                                    GeometryReader { proxy in
                                        image.image?
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: proxy.size.width, height: proxy.size.height)
                                            .clipShape(Rectangle())
                                            .modifier(ImageModifier(contentSize: CGSize(width: proxy.size.width, height: proxy.size.height)))
                                            .offset(x: offset.width, y: offset.height)
                                            .gesture(
                                                DragGesture()
                                                    .onChanged { gesture in
                                                        offset = gesture.translation
                                                    }
                                                    .onEnded { _ in
                                                        if abs(offset.height) > 130 {
                                                            dismissPopup()
                                                        } else {
                                                            withAnimation{offset = .zero}
                                                        }
                                                    }
                                            )
                                    }
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                }
                                if toolbarVisible && popupViewModel.gallery!.items[i].caption != nil {
                                    Text(popupViewModel.gallery!.items[i].caption!)
                                        .padding(SwiftUI.EdgeInsets(top: 6, leading: 6, bottom: 6, trailing: 6))
                                        .background(.black.opacity(0.6))
                                        .cornerRadius(8)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                                        .padding(SwiftUI.EdgeInsets(top: 0, leading: 30, bottom: 100, trailing: 30))
                                        .ignoresSafeArea()
                                }
                            }
                            .tag(i)
                        }
                    }
                    .onChange(of: activeGalleryTab, perform: { i in
                        currentImageLink = popupViewModel.gallery!.items[i].fullLink
                    })
                    .tabViewStyle(PageTabViewStyle())
                    .onAppear {
                        currentImageLink = popupViewModel.gallery!.items[0].fullLink
                    }
                }
                if toolbarVisible {
                    ZStack {
                        Rectangle()
                            .fill(Color.black)
                            .opacity(0.6)
                            .frame(maxWidth: .infinity, maxHeight: 80, alignment: .top)
                        HStack {
                            Image(systemName: "xmark")
                                .font(.system(size: 30))
                                .frame(maxWidth: .infinity, alignment: .topLeading)
                                .foregroundColor(Color.white)
                                .opacity(0.6)
                                .padding(EdgeInsets(top: 40, leading: 22, bottom: 0, trailing: 0))
                                .onTapGesture {
                                    popupViewModel.isShowing = false
                                    dismiss()
                                }
                            Image(systemName: "arrow.down.square")
                                .font(.system(size: 30))
                                .frame(maxWidth: .infinity, alignment: .topTrailing)
                                .foregroundColor(Color.white)
                                .opacity(0.6)
                                .padding(EdgeInsets(top: 40, leading: 0, bottom: 0, trailing: 22))
                                .onTapGesture {
                                    showingSaveDialog = true
                                }
                                .alert("Save image to library?", isPresented: $showingSaveDialog) {
                                    SaveImageAlert(showingSaveDialog: $showingSaveDialog, link: currentImageLink,
                                                   links: popupViewModel.gallery!.items.map{ $0.fullLink })
                                }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
            }
            else if (popupViewModel.contentType == ContentType.gif) {
                ZStack {
                    Rectangle()
                        .fill(Color.black)
                        .opacity(Double(1) - (abs(offset.height) / Double(250)))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    if popupViewModel.videoLink != nil {
                        GIFView(url: URL(string: popupViewModel.videoLink!)!)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .offset(x: offset.width, y: offset.height)
                            .gesture(
                                DragGesture()
                                    .onChanged { gesture in
                                        offset = gesture.translation
                                    }
                                    .onEnded { _ in
                                        if abs(offset.height) > 130 {
                                            dismissPopup()
                                        } else {
                                            withAnimation{offset = .zero}
                                        }
                                    }
                            )
                    }
                }
                if toolbarVisible {
                    ZStack {
                        Rectangle()
                            .fill(Color.black)
                            .opacity(0.6)
                            .frame(maxWidth: .infinity, maxHeight: 80, alignment: .top)
                        Image(systemName: "xmark")
                            .font(.system(size: 30))
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                            .foregroundColor(Color.white)
                            .opacity(0.6)
                            .padding(EdgeInsets(top: 40, leading: 22, bottom: 0, trailing: 0))
                            .onTapGesture {
                                popupViewModel.isShowing = false
                                dismiss()
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
        let timeLeft = time.seconds.distance(to: totalDuration)
        let m = Int(timeLeft / 60)
        let s = Int(timeLeft.truncatingRemainder(dividingBy: 60))
        return String(format: "-%d:%02d", arguments: [m, s])
    }
    
    private func dismissPopup() {
        popupViewModel.player.pause()
        popupViewModel.isShowing = false
    }
}
