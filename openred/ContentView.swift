//
//  ContentView.swift
//  openred
//
//  Created by Norbert Antal on 6/4/23.
//

import SwiftUI
import AVKit
import SafariServices

struct ContentView: View {
    @EnvironmentObject var popupViewModel: PopupViewModel
    @EnvironmentObject var model: Model
    @EnvironmentObject var settingsModel: SettingsModel
    @State var communitiesSidebarVisible = true
    @State var loginPopupShowing = false
    @State var showPosts = true
    @State var target: CommunityOrUser = CommunityOrUser(community: Community("all", isMultiCommunity: true))
    @State private var tabSelection = 1
    @State private var firstUnlock: Bool = true
    
    var body: some View {
        ZStack {
            TabView(selection: $tabSelection) {
                CommunitiesStack(loginPopupShowing: $loginPopupShowing, showPosts: $showPosts, target: $target)
                    .tabItem {
                        Label("Feed", systemImage: "newspaper")
                    }
                    .tag(1)
                InboxView()
                    .tabItem {
                        Label("Inbox", systemImage: "envelope")
                    }
                    .badge(model.messageCount)
                    .tag(2)
                SearchView(tabSelection: $tabSelection, showPosts: $showPosts, target: $target)
                    .tabItem {
                        Label("Search", systemImage: "magnifyingglass")
                    }
                    .tag(3)
                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
                    .tag(4)
            }
            .onAppear {
                // correct the transparency bug for Tab bars
                let tabBarAppearance = UITabBarAppearance()
                tabBarAppearance.configureWithOpaqueBackground()
                UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
                // correct the transparency bug for Navigation bars
                let navigationBarAppearance = UINavigationBarAppearance()
                navigationBarAppearance.configureWithOpaqueBackground()
                UINavigationBar.appearance().scrollEdgeAppearance = navigationBarAppearance
            }
            
            if popupViewModel.isShowing {
                MediaPopupContent()
                    .ignoresSafeArea()
                    .gesture(DragGesture(minimumDistance: 3.0, coordinateSpace: .local)
                        .onEnded { value in
                            switch(value.translation.width, value.translation.height) {
                            case (...0, -30...30): print("left swipe")
                            case (0..., -30...30): print("right swipe")
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
            MessageOverlay()
            if settingsModel.lockApp && !settingsModel.isUnlocked {
                ZStack {
                    Rectangle()
                        .fill(Color(UIColor.systemGray6))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .ignoresSafeArea()
                        .onAppear {
                            if firstUnlock {
                                settingsModel.authenticate()
                                firstUnlock = false
                            } else {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                                    settingsModel.authenticate()
                                }
                            }
                        }
                    Button(action: { settingsModel.authenticate() }) {
                        Label("Unlock", systemImage: "key.horizontal")
                    }
                }
            }
        }
        .preferredColorScheme(settingsModel.theme == "dark" ? .dark :
            settingsModel.theme == "light" ? .light : .none)
    }
    
    private func dismissPopup() {
        popupViewModel.player.pause()
        popupViewModel.isShowing = false
    }
}

struct MessageOverlay: View {
    @EnvironmentObject var overlayModel: MessageOverlayModel
    
    var body: some View {
        if overlayModel.showing {
            ZStack {
                if overlayModel.loading {
                    Rectangle()
                        .fill(Color.black)
                        .opacity(0.75)
                        .ignoresSafeArea()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    ProgressView().progressViewStyle(.circular)
                } else if overlayModel.text != nil {
                    ZStack {
                        Text(overlayModel.text!)
                            .opacity(0.8)
                            .padding()
                            .background(VisualEffect(style: .systemUltraThinMaterial))
                            .clipShape(Capsule())
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 100, trailing: 0))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear{
                DispatchQueue.main.asyncAfter(deadline: .now() + overlayModel.duration) {
                    withAnimation {
                        overlayModel.showing = false
                    }
                }
            }
        }
    }
}

class MessageOverlayModel: ObservableObject {
    @Published var showing: Bool
    @Published var text: String?
    @Published var duration: Double
    @Published var loading: Bool
    
    init() {
        self.showing = false
        self.duration = 4.0
        self.loading = false
    }
    
    func show(_ text: String? = nil, duration: Double = 3.0, loading: Bool = false) {
        self.text = text
        self.duration = duration
        self.loading = loading
        self.showing = true
    }
}

struct SaveImageAlert: View {
    @Binding var showingSaveDialog: Bool
    var link: String?
    var links: [String] = []
    
    var body: some View {
        Button("Cancel", role: .cancel) { showingSaveDialog = false }
        Button("Save") {
            DispatchQueue.global().async {
                if let data = try? Data(contentsOf: URL(string: link!)!) {
                    DispatchQueue.main.async {
                        ImageSaver().writeToPhotoAlbum(image: UIImage(data: data)!)
                    }
                }
            }
            showingSaveDialog = false
        }.keyboardShortcut(.defaultAction)
        if links.count > 0 {
            Button("Save all in album") {
                DispatchQueue.global().async {
                    for imageLink in links {
                        if let data = try? Data(contentsOf: URL(string: imageLink)!) {
                            DispatchQueue.main.async {
                                ImageSaver().writeToPhotoAlbum(image: UIImage(data: data)!)
                            }
                        }
                    }
                }
                showingSaveDialog = false
            }
        }
    }
}

struct SizeCalculator: ViewModifier {
    @Binding var size: CGSize
    
    func body(content: Content) -> some View {
        content.background(
            GeometryReader { proxy in
                Color.clear
                    .onAppear {
                        size = proxy.size
                    }
            })
    }
}

extension View {
    func saveSize(in size: Binding<CGSize>) -> some View {
        modifier(SizeCalculator(size: size))
    }
}

struct VisualEffect: UIViewRepresentable {
    @State var style : UIBlurEffect.Style
    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
    }
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
            if currentScale <= min {
                currentScale = max
            } else if currentScale >= max {
                currentScale = min
            } else {
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
        .scrollDisabled(currentScale == 1.0)
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

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

extension View {
    func roundedCorner(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners) )
    }
}

extension Color {
    public static let upvoteOrange: Color = Color(red: 1, green: 112 / 255, blue: 51 / 225)
    public static let downvoteBlue: Color = Color(red: 102 / 255, green: 102 / 255, blue: 1)
}

extension String {
    init?(htmlEncodedString: String) {
        guard let data = htmlEncodedString.data(using: .utf8) else {
            return nil
        }
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]
        guard let attributedString = try? NSAttributedString(data: data, options: options, documentAttributes: nil) else {
            return nil
        }
        self.init(attributedString.string)
    }
}

extension Date {
    func timeAgoDisplay() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

// keep slide back when back button disabled
//extension UINavigationController: UIGestureRecognizerDelegate {
//    override open func viewDidLoad() {
//        super.viewDidLoad()
//        interactivePopGestureRecognizer?.delegate = self
//    }
//
//    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
//        return viewControllers.count > 1
//    }
//}

struct SFSafariViewWrapper: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: UIViewControllerRepresentableContext<Self>) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: UIViewControllerRepresentableContext<SFSafariViewWrapper>) {
        return
    }
}

extension URL {
    var isPost: Bool {
        self.absoluteString.contains("reddit.com/r/") &&
        self.absoluteString.contains("/comments/")
    }
    // community or user
    var isCommunity: Bool {
        (self.absoluteString.contains("reddit.com/user/") ||
            self.absoluteString.contains("reddit.com/u/")) ||
        (self.absoluteString.contains("reddit.com/r/") &&
            !self.absoluteString.contains("/comments/"))
    }
    var isImage: Bool {
        [".jpg", ".jpeg", ".png", ".svg"]
            .filter{ self.lastPathComponent.hasSuffix($0) }.first != nil
    }
}

class ImageSaver: NSObject {
    func writeToPhotoAlbum(image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, self, nil, nil)
    }
}

extension UIImageView {
    func load(url: URL) {
        DispatchQueue.global().async { [weak self] in
            if let data = try? Data(contentsOf: url) {
                if let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self?.image = image
                    }
                }
            }
        }
    }
}
