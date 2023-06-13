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
    @State var mediaPopupShowing = false
    @State var loginPopupShowing = false
    @State var popupContentType: ContentType = .link
    @State var mediaPopupImage: Image?
    @State var videoLink: String?
    @State var player = AVPlayer()
    
    var body: some View {
        ZStack{
            TabView {
                PostsView(communitiesSidebarVisible: $communitiesSidebarVisible,
                          mediaPopupShowing: $mediaPopupShowing, popupContentType: $popupContentType,
                          mediaPopupImage: $mediaPopupImage, videoLink: $videoLink, player: $player)
                    .tabItem {
                        Label("Feed", systemImage: "newspaper")
                    }
                InboxView()
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
            CommunitiesSidebar(isShowing: $communitiesSidebarVisible, loginPopupShowing: $loginPopupShowing)
            if mediaPopupShowing {
                MediaPopupContent(mediaPopupShowing: $mediaPopupShowing, mediaPopupImage: $mediaPopupImage,
                                  videoLink: $videoLink, contentType: $popupContentType, player: $player)
                .ignoresSafeArea()
                .gesture(DragGesture(minimumDistance: 3.0, coordinateSpace: .local)
                    .onEnded { value in
                        print(value.translation)
                        switch(value.translation.width, value.translation.height) {
//                        case (...0, -30...30): print("left swipe")
//                        case (0..., -30...30): print("right swipe")
                        case (-100...100, ...0): dismissPopup() // up swipe
                        case (-100...100, 0...): dismissPopup() // down swipe
                        default: print("no clue")
                        }
                    }
                )
            }
            if loginPopupShowing {
                LoginPopup(loginPopupShowing: $loginPopupShowing)
            }
        }
    }
    
    private func dismissPopup() {
        player.pause()
        mediaPopupShowing = false
    }
}

struct ZoomableScrollView<Content: View>: UIViewRepresentable {
  private var content: Content

  init(@ViewBuilder content: () -> Content) {
    self.content = content()
  }

  func makeUIView(context: Context) -> UIScrollView {
    let scrollView = UIScrollView()
    scrollView.delegate = context.coordinator  // for viewForZooming(in:)
    scrollView.maximumZoomScale = 20
    scrollView.minimumZoomScale = 1
    scrollView.bouncesZoom = true

    let hostedView = context.coordinator.hostingController.view!
    hostedView.translatesAutoresizingMaskIntoConstraints = true
    hostedView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    hostedView.frame = scrollView.bounds
    scrollView.addSubview(hostedView)

    return scrollView
  }

  func makeCoordinator() -> Coordinator {
    return Coordinator(hostingController: UIHostingController(rootView: self.content))
  }

  func updateUIView(_ uiView: UIScrollView, context: Context) {
    // update the hosting controller's SwiftUI content
    context.coordinator.hostingController.rootView = self.content
    assert(context.coordinator.hostingController.view.superview == uiView)
  }

  // MARK: - Coordinator

  class Coordinator: NSObject, UIScrollViewDelegate {
    var hostingController: UIHostingController<Content>

    init(hostingController: UIHostingController<Content>) {
      self.hostingController = hostingController
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
      return hostingController.view
    }
  }
}

struct SizeCalculator: ViewModifier {
    
    @Binding var size: CGSize
    
    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { proxy in
                    Color.clear
                        .onAppear {
                            size = proxy.size
                        }
                }
            )
    }
}

extension View {
    func saveSize(in size: Binding<CGSize>) -> some View {
        modifier(SizeCalculator(size: size))
    }
}

struct VisualEffect: UIViewRepresentable {
    @State var style : UIBlurEffect.Style // 1
    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: style)) // 2
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
    } // 3
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

//extension AVPlayerViewController {
//    override open func viewDidLoad() {
//        super.viewDidLoad()
//        self.showsPlaybackControls = true
//        self.videoGravity = .resizeAspect
//    }
//}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
