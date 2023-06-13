//
//  CommunitiesSidebar.swift
//  openred
//
//  Created by Norbert Antal on 6/9/23.
//

import Foundation
import SwiftUI

struct CommunitiesSidebarContent: View {
    @EnvironmentObject var model: Model
    @Binding var communitiesSidebarVisible: Bool
    @Binding var loginPopupShowing: Bool
    
    init(communitiesSidebarVisible: Binding<Bool>, loginPopupShowing: Binding<Bool>) {
        UIScrollView.appearance().bounces = false
        self._communitiesSidebarVisible = communitiesSidebarVisible
        self._loginPopupShowing = loginPopupShowing
    }
    
    var body: some View {
        HStack {
            ZStack {
                Rectangle()
                    .fill(Color(UIColor.systemGray6))
                    .frame(width: 300)
                    .opacity(0.5)
                    .background(.ultraThinMaterial)
                    .background(VisualEffect(style: .systemUltraThinMaterial).opacity(0.8))
                VStack(alignment: .leading, spacing: 0) {
                    Spacer()
                        .frame(width: 300, height: 30, alignment: .top)
                        .background(Color.clear)
                    List {
                        Section() {
                            UserSection(communitiesSidebarVisible: $communitiesSidebarVisible, loginPopupShowing: $loginPopupShowing)
                        }
                        Section() {
                            ForEach(model.mainPageCommunities) { community in
                                CommunityRow(communitiesSidebarVisible: $communitiesSidebarVisible,
                                             community: community)
                            }
                            if model.userName != nil {
                                ForEach(model.userFunctionCommunities) { community in
                                    CommunityRow(communitiesSidebarVisible: $communitiesSidebarVisible,
                                                 community: community)
                                }
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
                .background(Color.clear)
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
        }
        .listRowBackground(Color.clear)
    }
}

struct CommunitiesSidebar: View {
    @Binding var isShowing: Bool
    @Binding var loginPopupShowing: Bool
    
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
                CommunitiesSidebarContent(communitiesSidebarVisible: $isShowing, loginPopupShowing: $loginPopupShowing)
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

struct UserSection: View {
    @EnvironmentObject var model: Model
    @Binding var communitiesSidebarVisible: Bool
    @Binding var loginPopupShowing: Bool
    
    var body: some View {
        if model.userName != nil {
            Button(action: {
                
            }) {
                HStack {
                    Image(systemName: "person.crop.circle")
                    Text(model.userName!)
                }
            }
            .listRowBackground(Color.clear)
        } else {
            Button(action: {
                loginPopupShowing.toggle()
            }) {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.forward")
                    Text("Log in")
                }
            }
            .listRowBackground(Color.clear)
        }
    }
}
