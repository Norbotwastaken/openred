//
//  ContentView.swift
//  openred
//
//  Created by Norbert Antal on 6/4/23.
//

import SwiftUI
import SwiftyGif
import AVKit

struct ContentView: View {
    @State var communitiesSidebarVisible = false
    @State var player = AVPlayer(url: URL(string: "https://i.imgur.com/A0uSYLF.mp4")!)
    
    var body: some View {
        ZStack{
            TabView {
                PostsView(communitiesSidebarVisible: $communitiesSidebarVisible)
                    .tabItem {
                        Label("Feed", systemImage: "newspaper")
                    }
//                Text("Inbox")
                VideoPlayer(player: player)
                    .tabItem {
                        Label("Inbox", systemImage: "envelope")
                    }
                Text("Search")
                    .tabItem {
                        Label("Search", systemImage: "magnifyingglass")
                    }
                Text("Settings")
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
            }
            CommunitiesSidebar(isShowing: $communitiesSidebarVisible)
        }
    }
}

//struct AnimatedGifView: UIViewRepresentable {
//    @Binding var url: URL
//
//    func makeUIView(context: Context) -> UIImageView {
//        let imageView = UIImageView(gifURL: self.url)
//        imageView.contentMode = .scaleAspectFit
//        return imageView
//    }
//
//    func updateUIView(_ uiView: UIImageView, context: Context) {
//        uiView.setGifFromURL(self.url)
//    }
//}

extension AVPlayerViewController {
    override open func viewDidLoad() {
        super.viewDidLoad()
        self.showsPlaybackControls = true
        self.videoGravity = .resizeAspect
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
