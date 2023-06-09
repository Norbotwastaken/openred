//
//  PostsAndCommunitiesView.swift
//  openred
//
//  Created by Norbert Antal on 6/9/23.
//

import Foundation
import SwiftUI

@available(iOS 14.0, *)
struct PostsAndCommunitiesView: View {
    @State
    private var tabViewSelection: Int = 1
    
//    @State
//    private var tabBarSelection: CGFloat = 0
//    @State
//    private var isAnimatingForTap: Bool = false
    
    private var cooridnateSpaceName: String {
        return "scrollview"
    }
    
    var body: some View {
        VStack(alignment: .leading) {
//            SlidingTabBar(
//                selection: $tabBarSelection,
//                tabs: ["First", "Second"]
//            ) { newValue in
//                isAnimatingForTap = true
//                tabViewSelection = newValue
//                DispatchQueue.main.asyncAfter(deadline: .now().advanced(by: .milliseconds(300))) {
//                    isAnimatingForTap = false
//                }
//            }
//            THIS requires SlidingTabView functions
            TabView(selection: $tabViewSelection) {
//                HStack {
//                    Spacer()
                    Text("Communities (placeholder)")
//                    Spacer()
//                }
                .tag(0)
//                .readFrame(in: .named(cooridnateSpaceName)) { frame in
//                    guard !isAnimatingForTap else { return }
//                    tabBarSelection = (-frame.origin.x / frame.width)
//                }
//                THIS requires SlidingTabView functions
                
//                HStack {
                    PostsView()
//                }
                .tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .coordinateSpace(name: cooridnateSpaceName)
            .animation(.linear(duration: 0.2), value: tabViewSelection)
            
        }
    }
}
