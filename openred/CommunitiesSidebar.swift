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
    @State var showPosts = true
    @State private var searchText = ""
    @State var itemInView = ""
    
    var body: some View {
        ZStack {
            NavigationStack() {
                ZStack {
                    VStack(alignment: .leading, spacing: 0) {
                        List {
                            if searchText.isEmpty {
                                UserSection(loginPopupShowing: $loginPopupShowing)
                                Section() {
                                    ForEach(model.mainPageCommunities) { community in
                                        CommunityRow(community: community, showPosts: $showPosts)
                                    }
                                }
                                if model.userSessionManager.userName != nil {
                                    Section() {
                                        ForEach(model.userFunctionCommunities) { community in
                                            CommunityRow(community: community, showPosts: $showPosts)
                                        }
                                    }
                                }
                            }
                            if !model.subscribedCommunities.isEmpty {
                                Section(header: Text("Subreddits")) {
                                    ForEach(filteredSubscribedCommunities) { community in
                                        CommunityRow(community: community, showPosts: $showPosts)
                                    }
                                }
                                .background(Color.clear)
                            }
//                            if !filteredCommunities.isEmpty {
//                                Section(header: Text("More Subreddits")) {
//                                    ForEach(filteredCommunities) { community in
//                                        CommunityRow(community: community, showPosts: $showPosts)
//                                    }
//                                }
//                                .background(Color.clear)
//                            }
                        }
                        .listStyle(PlainListStyle())
                    }
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

struct CommunityRow: View {
    @EnvironmentObject var model: Model
    var community: Community
    @Binding var showPosts: Bool
    
    var body: some View {
        Button(action: {
            model.loadCommunity(communityCode: community.communityCode)
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

struct UserSection: View {
    @EnvironmentObject var model: Model
    @Binding var loginPopupShowing: Bool
    
    var body: some View {
        if model.userName != nil {
            Menu {
                Button(action: {
                    model.logOut()
                }) {
                    Label("Log out", systemImage: "rectangle.portrait.and.arrow.forward")
                }
            } label: {
                Button(action: {
                    
                }) {
                    HStack {
                        Image(systemName: "person.crop.circle")
                        Text(model.userSessionManager.userName!)
                    }
                    .foregroundColor(.primary)
                }
                .listRowBackground(Color.clear)
            }
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
