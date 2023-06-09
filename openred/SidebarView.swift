//
//  SidebarView.swift
//  openred
//
//  Created by Norbert Antal on 6/9/23.
//

import Foundation
import SwiftUI

struct MenuContent: View {
    @EnvironmentObject var model: Model
    
    init() {
        UIScrollView.appearance().bounces = false
    }
    
    var body: some View {
        HStack {
            ZStack {
                VStack(alignment: .leading, spacing: 0) {
                    List {
                        ForEach(model.mainPageCommunities) { community in
                            CommunityRow(community: community)
                        }
                        // TODO: tie this to logged in user
                        ForEach(model.userFunctionCommunities) { community in
                            CommunityRow(community: community)
                        }
                        Section(header: Text("Subreddits")) {
                            ForEach(model.communities) { community in
                                CommunityRow(community: community)
                            }
                        }
                    }.scrollContentBackground(.visible)
                    .listStyle(PlainListStyle())
//                    .frame(height: 140)
//                    .padding(.bottom, 30)
//                    Spacer()
                }
                .padding(.top, 45)
                .padding(.bottom, 20)
                .frame(width: 300)
                .background(
                    .background
                )
            }
            Spacer()
        }.background(.clear)
    }
}

struct CommunityRow: View {
    var community: Community
    var body: some View {
        HStack {
            if community.iconName != nil {
                Image(systemName: community.iconName!)
            }
            Text(community.name)
        }
    }
}

struct CommunitiesSidebar: View {
    @Binding var isShowing: Bool
    
    var edgeTransition: AnyTransition = .move(edge: .leading)
    var body: some View {
        ZStack(alignment: .bottom) {
            if (isShowing) {
                Color.black
                    .opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        isShowing.toggle()
                    }
                MenuContent()
                    .transition(edgeTransition)
                    .background(
                        Color.clear
                    )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .ignoresSafeArea()
        .animation(.easeInOut, value: isShowing)
    }
}
