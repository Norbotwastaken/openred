//
//  ContentView.swift
//  openred
//
//  Created by Norbert Antal on 6/4/23.
//

import SwiftUI
import AVKit

struct ContentView: View {
    @EnvironmentObject var popupViewModel: PopupViewModel
    @State var communitiesSidebarVisible = true
    @State var loginPopupShowing = false
    @State private var sidebarOffset = CGSize(width: -300, height: 0)
    
    var body: some View {
        ZStack {
            TabView {
                ZStack {
                    PostsView(sidebarOffset: $sidebarOffset)
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
                        if sidebarOffset.width == -300 {
                            if gesture.startLocation.x < 20 {
                                sidebarOffset.width = min(sidebarOffset.width + (gesture.translation.width / 20), 0)
                            }
                        } else {
                            sidebarOffset.width = min(sidebarOffset.width + (gesture.translation.width / 35), 0)
                        }
                    }
                    .onEnded { gesture in
                        if gesture.startLocation.x < 20 {
//                            if sidebarOffset.width < -200 {
//                                sidebarOffset.width = -300
//                            } else {
                                sidebarOffset.width = -1
//                            }
                        }
                    }
            )
            if sidebarOffset.width > -200 {
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
            
            if popupViewModel.isShowing {
                MediaPopupContent()
                .ignoresSafeArea()
                .gesture(DragGesture(minimumDistance: 3.0, coordinateSpace: .local)
                    .onEnded { value in
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
        popupViewModel.player.pause()
        popupViewModel.isShowing = false
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

/// Zoom 2
struct ImageModifier: ViewModifier {
    private var contentSize: CGSize
    private var min: CGFloat = 1.0
    private var max: CGFloat = 3.0
    @State var currentScale: CGFloat = 1.0

    init(contentSize: CGSize) {
        self.contentSize = contentSize
    }
    
    var doubleTapGesture: some Gesture {
        TapGesture(count: 2).onEnded {
            if currentScale <= min { currentScale = max } else
            if currentScale >= max { currentScale = min } else {
                currentScale = ((max - min) * 0.5 + min) < currentScale ? max : min
            }
        }
    }
    
    func body(content: Content) -> some View {
        ScrollView([.horizontal, .vertical]) {
            content
                .frame(width: contentSize.width * currentScale, height: contentSize.height * currentScale, alignment: .center)
                .modifier(PinchToZoom(minScale: min, maxScale: max, scale: $currentScale))
        }
        .gesture(doubleTapGesture)
        .animation(.easeInOut, value: currentScale)
    }
}

class PinchZoomView: UIView {
    let minScale: CGFloat
    let maxScale: CGFloat
    var isPinching: Bool = false
    var scale: CGFloat = 1.0
    let scaleChange: (CGFloat) -> Void
    
    init(minScale: CGFloat,
           maxScale: CGFloat,
         currentScale: CGFloat,
         scaleChange: @escaping (CGFloat) -> Void) {
        self.minScale = minScale
        self.maxScale = maxScale
        self.scale = currentScale
        self.scaleChange = scaleChange
        super.init(frame: .zero)
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(pinch(gesture:)))
        pinchGesture.cancelsTouchesInView = false
        addGestureRecognizer(pinchGesture)
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    @objc private func pinch(gesture: UIPinchGestureRecognizer) {
        switch gesture.state {
        case .began:
            isPinching = true
            
        case .changed, .ended:
            if gesture.scale <= minScale {
                scale = minScale
            } else if gesture.scale >= maxScale {
                scale = maxScale
            } else {
                scale = gesture.scale
            }
            scaleChange(scale)
        case .cancelled, .failed:
            isPinching = false
            scale = 1.0
        default:
            break
        }
    }
}

struct PinchZoom: UIViewRepresentable {
    let minScale: CGFloat
    let maxScale: CGFloat
    @Binding var scale: CGFloat
    @Binding var isPinching: Bool
    
    func makeUIView(context: Context) -> PinchZoomView {
        let pinchZoomView = PinchZoomView(minScale: minScale, maxScale: maxScale, currentScale: scale, scaleChange: { scale = $0 })
        return pinchZoomView
    }
    
    func updateUIView(_ pageControl: PinchZoomView, context: Context) { }
}

struct PinchToZoom: ViewModifier {
    let minScale: CGFloat
    let maxScale: CGFloat
    @Binding var scale: CGFloat
    @State var anchor: UnitPoint = .center
    @State var isPinching: Bool = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(scale, anchor: anchor)
            .animation(.spring(), value: isPinching)
            .overlay(PinchZoom(minScale: minScale, maxScale: maxScale, scale: $scale, isPinching: $isPinching))
    }
}
