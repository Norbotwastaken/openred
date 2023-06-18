//
//  CommunitiesSidebar.swift
//  openred
//
//  Created by Norbert Antal on 6/9/23.
//

import Foundation
import SwiftUI

struct CommunitiesStack: View {
    @EnvironmentObject var model: Model
    @Binding var loginPopupShowing: Bool
    @State var showPosts = false
    @State private var searchText = ""
    @State var itemInView = ""
    
    var body: some View {
        ZStack {
            NavigationStack() {
                ZStack {
                    VStack(alignment: .leading, spacing: 0) {
                        List {
                            if searchText.isEmpty {
                                UserSection2(loginPopupShowing: $loginPopupShowing)
                                Section() {
                                    ForEach(model.mainPageCommunities) { community in
                                        CommunityRow2(community: community, showPosts: $showPosts)
                                    }
                                }
                                if model.userName != nil {
                                    Section() {
                                        ForEach(model.userFunctionCommunities) { community in
                                            CommunityRow2(community: community, showPosts: $showPosts)
                                        }
                                    }
                                }
                            }
                            if !model.subscribedCommunities.isEmpty {
                                Section(header: Text("Subscriptions")) {
                                    ForEach(filteredSubscribedCommunities) { community in
                                        CommunityRow2(community: community, showPosts: $showPosts)
                                    }
                                }
                                .background(Color.clear)
                            }
                            Section(header: Text("More Subreddits")) {
                                ForEach(filteredCommunities) { community in
                                    CommunityRow2(community: community, showPosts: $showPosts)
                                }
                            }
                            .background(Color.clear)
                        }
                        .listStyle(PlainListStyle())
                    }
//                    .padding(.top, 30)
                    ZStack {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 65, height: 65, alignment: .bottomTrailing)
                            .onTapGesture {
                                showPosts = true
                            }
                        Image(systemName: "chevron.right")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                    }
                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 30, trailing: 30))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .navigationTitle("Communities")
                .navigationBarTitleDisplayMode(.inline)
                .navigationDestination(isPresented: $showPosts) {
                    PostsView(itemInView: $itemInView)
                }
            }
            .searchable(text: $searchText)
            .toolbar(.hidden, for: .navigationBar)
        }
    }
    
    var filteredSubscribedCommunities: [Community] {
        if searchText.isEmpty {
            return model.subscribedCommunities
        } else {
            return model.subscribedCommunities.filter {
                $0.name.lowercased().contains(searchText.lowercased())
            }
        }
    }
    
    var filteredCommunities: [Community] {
        if searchText.isEmpty {
            return model.communities
        } else {
            return model.communities.filter {
                $0.name.lowercased().contains(searchText.lowercased())
            }
        }
    }
}

struct CommunitiesSidebarContent: View {
    @EnvironmentObject var model: Model
    @Binding var sidebarOffset: CGSize
    @Binding var loginPopupShowing: Bool
    
    init(sidebarOffset: Binding<CGSize>, loginPopupShowing: Binding<Bool>) {
        UIScrollView.appearance().bounces = false
        self._sidebarOffset = sidebarOffset
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
                            UserSection(sidebarOffset: $sidebarOffset, loginPopupShowing: $loginPopupShowing)
                        }
                        Section() {
                            ForEach(model.mainPageCommunities) { community in
                                CommunityRow(sidebarOffset: $sidebarOffset,
                                             community: community)
                            }
                            if model.userName != nil {
                                ForEach(model.userFunctionCommunities) { community in
                                    CommunityRow(sidebarOffset: $sidebarOffset,
                                                 community: community)
                                }
                            }
                        }
                        if !model.subscribedCommunities.isEmpty {
                            Section(header: Text("Subscriptions")) {
                                ForEach(model.subscribedCommunities) { community in
                                    CommunityRow(sidebarOffset: $sidebarOffset,
                                                 community: community)
                                }
                            }
                            .background(Color.clear)
                        }
                        Section(header:
//                                    HStack {
                            Text("More Subreddits")
//                            Text("Edit").frame(maxWidth: .infinity, alignment: .trailing)}
                        ) {
                            ForEach(model.communities) { community in
                                CommunityRow(sidebarOffset: $sidebarOffset,
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
        }
        .background(.clear)
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
}

struct CommunityRow2: View {
    @EnvironmentObject var model: Model
    var community: Community
    @Binding var showPosts: Bool
    
    var body: some View {
        Button(action: {
            model.loadCommunity(community: community)
            showPosts = true
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

struct CommunityRow: View {
    @EnvironmentObject var model: Model
    @Binding var sidebarOffset: CGSize
    var community: Community
    
    var body: some View {
        Button(action: {
            model.loadCommunity(community: community)
            sidebarOffset.width = -300
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

struct UserSection2: View {
    @EnvironmentObject var model: Model
    @Binding var loginPopupShowing: Bool
    
    var body: some View {
        if model.userName != nil {
            Menu {
                Button(action: {
                    // logout action
                }) {
                    Label("Log out", systemImage: "rectangle.portrait.and.arrow.forward")
                }
            } label: {
                Button(action: {
                    
                }) {
                    HStack {
                        Image(systemName: "person.crop.circle")
                        Text(model.userName!)
                    }
                    .foregroundColor(.primary)
                }
                .listRowBackground(Color.clear)
            }
//            .foregroundColor(.primary)
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


struct UserSection: View {
    @EnvironmentObject var model: Model
    @Binding var sidebarOffset: CGSize
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

struct MenuItem: Identifiable {
    var id = UUID()
    var name: String
    var subMenuItems: [MenuItem]?
}
