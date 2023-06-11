//
//  SidebarView.swift
//  openred
//
//  Created by Norbert Antal on 6/9/23.
//

import Foundation
import SwiftUI

struct CommunitiesSidebarContent: View {
    @EnvironmentObject var model: Model
    @Binding var communitiesSidebarVisible: Bool
    
    init(communitiesSidebarVisible: Binding<Bool>) {
        UIScrollView.appearance().bounces = false
        self._communitiesSidebarVisible = communitiesSidebarVisible
    }
    
    var body: some View {
        HStack {
            ZStack {
                VStack(alignment: .leading, spacing: 0) {
                    Spacer()
                        .frame(width: 300, height: 30, alignment: .top)
                        .background(Color(UIColor.systemGray6))
                    List {
                        // TODO: top section for user field
                        Section() {
                            ForEach(model.mainPageCommunities) { community in
                                CommunityRow(communitiesSidebarVisible: $communitiesSidebarVisible,
                                             community: community)
                            }
                            // TODO: tie this to logged in user
                            ForEach(model.userFunctionCommunities) { community in
                                CommunityRow(communitiesSidebarVisible: $communitiesSidebarVisible,
                                             community: community)
                            }
                        }
                        Section(header: HStack {
                            Text("Subreddits")
                            Text("Edit").frame(maxWidth: .infinity, alignment: .trailing)}
                        ) {
                            ForEach(model.communities) { community in
                                CommunityRow(communitiesSidebarVisible: $communitiesSidebarVisible,
                                             community: community)
                            }
                        }
                        .background(Color.clear)
                    }
                    .scrollContentBackground(.visible)
                    .listStyle(PlainListStyle())
                }
                .padding(.top, 30)
                .padding(.bottom, 20)
                .frame(width: 300)
                .background(Color(UIColor.systemGray6))
            }
            Spacer()
        }.background(.clear)
    }
}

struct CommunityRow: View {
    @EnvironmentObject var model: Model
    @Binding var communitiesSidebarVisible: Bool
    var community: Community
    
    var body: some View {
        Button(action: {
            model.loadCommunity(community: community)
            communitiesSidebarVisible.toggle()
        }) {
            HStack {
                if community.iconName != nil {
                    Image(systemName: community.iconName!)
                }
                Text(community.name)
            }
        }.listRowBackground(Color(UIColor.systemGray6))
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
                CommunitiesSidebarContent(communitiesSidebarVisible: $isShowing)
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
