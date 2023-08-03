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
    @Binding var showPosts: Bool
    @Binding var target: CommunityOrUser
    @State var itemInView: String = ""
    @State private var searchText = ""
    @State var restoreScroll: Bool = true
    @State var loadPosts: Bool = true
    
    var body: some View {
        ZStack {
            NavigationStack() {
                ZStack {
                    VStack(alignment: .leading, spacing: 0) {
                        List {
                            if searchText.isEmpty {
                                UserSection(loginPopupShowing: $loginPopupShowing, showPosts: $showPosts,
                                            target: $target, loadPosts: $loadPosts)
                                Section() {
                                    ForEach(model.mainPageCommunities) { community in
                                        CommunityRow(community: community, showPosts: $showPosts, target: $target, loadPosts: $loadPosts)
                                    }
                                }
                                if model.userSessionManager.userName != nil {
                                    Section() {
                                        ForEach(model.userFunctionCommunities) { community in
                                            CommunityRow(community: community, showPosts: $showPosts, target: $target, loadPosts: $loadPosts)
                                        }
                                    }
                                }
                            }
                            if !model.communities.isEmpty {
                                Section(header: Text("Subreddits")) {
                                    ForEach(filteredSubscribedCommunities) { community in
                                        CommunityRow(community: community, showPosts: $showPosts, target: $target, loadPosts: $loadPosts)
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
                                restoreScroll = true
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
                    PostsView(itemInView: $itemInView, restoreScroll: $restoreScroll, target: $target, loadPosts: $loadPosts)
                }
            }
            .id(target.id)
            .searchable(text: $searchText)
            .toolbar(.hidden, for: .navigationBar)
        }
    }
    
    var filteredSubscribedCommunities: [Community] {
        if searchText.isEmpty {
            return model.communities
        } else {
            return model.communities.filter {
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
    @Binding var target: CommunityOrUser
    @Binding var loadPosts: Bool
    
    var body: some View {
        Button(action: {
            loadPosts = true
            target = CommunityOrUser(community: community)
            model.resetPagesTo(target: target)
//            model.loadCommunity(community: CommunityOrUser(community: community))
            showPosts = true
        }) {
            HStack {
                if community.iconName != nil {
                    Text(Image(systemName: community.iconName!))
                } else if let icon = community.iconURL {
                    ZStack {
                        Text(Image(systemName: "r.circle.fill"))
                            .frame(maxWidth: 30, maxHeight: 30)
                        AsyncImage(url: URL(string: icon)) { image in
                            image.image?
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: 30, maxHeight: 30)
                                .clipShape(Circle())
                        }
                    }
                }
                Text(community.displayName ?? community.name.prefix(1).capitalized + community.name.dropFirst())
            }
        }
        .listRowBackground(Color.clear)
    }
}

struct UserSection: View {
    @EnvironmentObject var model: Model
    @EnvironmentObject var overlayModel: MessageOverlayModel
    @Binding var loginPopupShowing: Bool
    @Binding var showPosts: Bool
    @Binding var target: CommunityOrUser
    @Binding var loadPosts: Bool
    @State private var showingExitAlert = false
    
    var body: some View {
        if model.userName != nil {
            Menu {
                Button(action: {
                    loadPosts = true
                    target = CommunityOrUser(user: User(model.userName!))
                    model.resetPagesTo(target: target)
                    showPosts = true
//                    model.loadCommunity(community: target)
                }) {
                    Label("My Profile", systemImage: "person")
                }
                Button(action: {
                    showingExitAlert = true
                }) {
                    Label("Add account", systemImage: "plus")
                }
                Menu {
                    ForEach(model.savedUserNames, id: \.self) { userName in
                        Button(userName, action: {
                            model.switchAccountTo(userName: userName)
                            overlayModel.loading = true
                            overlayModel.showing = true
                        })
                    }
                } label: {
                    Label("Switch account", systemImage: "person.2")
                }
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
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    .foregroundColor(.primary)
                }
                .listRowBackground(Color.clear)
                .alert("Log out", isPresented: $showingExitAlert) {
                    Button("Log out", role: .destructive) {
                        model.logOut()
                        showingExitAlert = false
                        loginPopupShowing = true
                    }
                    Button("Cancel", role: .cancel) { showingExitAlert = false }
                } message: {
                    Text("To add a new account you first need to log out of your current session.")
                }
            }
        } else {
            if model.savedUserNames.isEmpty {
                Button(action: {
                    loginPopupShowing.toggle()
                }) {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.forward")
                        Text("Log in")
                    }
                }
                .listRowBackground(Color.clear)
            } else {
                Menu {
                    Button(action: {
                        loginPopupShowing = true
                    }) {
                        Label("Add account", systemImage: "plus")
                    }
                    ForEach(model.savedUserNames, id: \.self) { userName in
                        Button(userName, action: { model.switchAccountTo(userName: userName) })
                    }
                } label: {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.forward")
                        Text("Log in")
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    .foregroundColor(.primary)
                }
            }
        }
    }
}
