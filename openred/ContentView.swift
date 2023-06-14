//
//  ContentView.swift
//  openred
//
//  Created by Norbert Antal on 6/4/23.
//

import SwiftUI
import AVKit

struct ContentView: View {
    @State var communitiesSidebarVisible = true
    @State var mediaPopupShowing = false
    @State var loginPopupShowing = false
    @State var popupContentType: ContentType = .link
    @State var mediaPopupImage: Image?
    @State var videoLink: String?
    @State var player = AVPlayer()
    @State private var sidebarOffset = CGSize(width: -300, height: 0)
    
    var body: some View {
        ZStack {
            TabView {
                ZStack {
                    PostsView(communitiesSidebarVisible: $communitiesSidebarVisible,
                              mediaPopupShowing: $mediaPopupShowing, popupContentType: $popupContentType,
                              mediaPopupImage: $mediaPopupImage, videoLink: $videoLink, player: $player)
                    .disabled(sidebarOffset.width > -300)
                }
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
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        if gesture.startLocation.x < 20 {
                            sidebarOffset.width = min(sidebarOffset.width + (gesture.translation.width / 20), 0)
                        }
                    }
                    .onEnded { gesture in
                        if gesture.startLocation.x < 20 {
                            if abs(sidebarOffset.width) > -100 {
                                sidebarOffset.width = -1
                            } else {
                                sidebarOffset.width = -300
                            }
                        }
                    }
            )
            if sidebarOffset.width > -300 {
                Rectangle()
                    .fill(.black)
                    .opacity(0.2)
                    .ignoresSafeArea()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onTapGesture {
                        sidebarOffset.width = -300
                    }
                    .gesture(
                        DragGesture()
                            .onChanged { gesture in
                                if gesture.translation.width < 0 && gesture.translation.width < gesture.translation.height {
                                    // Left swipe
                                    sidebarOffset.width = sidebarOffset.width + (gesture.translation.width / 20)
                                }
                                if gesture.translation.width > 0 && gesture.translation.width > gesture.translation.height {
                                    // Right swipe
                                    sidebarOffset.width = min(sidebarOffset.width + (gesture.translation.width / 20), 0)
                                }
                            }
                            .onEnded { value in
                                if sidebarOffset.width < -100 {
                                    // auto close fully
                                    sidebarOffset.width = -300
                                } else {
                                    // cancel close
                                    sidebarOffset.width = -1
                                }
                            }
                    )
            }
            CommunitiesSidebarContent(sidebarOffset: $sidebarOffset, loginPopupShowing: $loginPopupShowing)
                .ignoresSafeArea()
                .offset(x: sidebarOffset.width, y: 0)
            
            if mediaPopupShowing {
                MediaPopupContent(mediaPopupShowing: $mediaPopupShowing, mediaPopupImage: $mediaPopupImage,
                                  videoLink: $videoLink, contentType: $popupContentType, player: $player)
                .ignoresSafeArea()
                .gesture(DragGesture(minimumDistance: 3.0, coordinateSpace: .local)
                    .onEnded { value in
//                        print(value.translation)
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
