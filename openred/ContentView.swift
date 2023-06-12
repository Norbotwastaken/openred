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
    
    var body: some View {
        ZStack{
            TabView {
                PostsView(communitiesSidebarVisible: $communitiesSidebarVisible)
                    .tabItem {
                        Label("Feed", systemImage: "newspaper")
                    }
                Text("Inbox")
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

struct ZoomableScrollView<Content: View>: UIViewRepresentable {
  private var content: Content

  init(@ViewBuilder content: () -> Content) {
    self.content = content()
  }

  func makeUIView(context: Context) -> UIScrollView {
    // set up the UIScrollView
    let scrollView = UIScrollView()
    scrollView.delegate = context.coordinator  // for viewForZooming(in:)
    scrollView.maximumZoomScale = 20
    scrollView.minimumZoomScale = 1
    scrollView.bouncesZoom = true

    // create a UIHostingController to hold our SwiftUI content
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
