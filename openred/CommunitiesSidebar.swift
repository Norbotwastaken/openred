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
    @Binding var isInboxInternalPresented: Bool
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
                                            target: $target, loadPosts: $loadPosts, isInboxInternalPresented: $isInboxInternalPresented)
                                Section() {
                                    ForEach(model.mainPageCommunities) { community in
                                        CommunityRow(community: community, isFavoritable: false, showPosts: $showPosts, target: $target, loadPosts: $loadPosts,
                                                     isInboxInternalPresented: $isInboxInternalPresented)
                                    }
                                }
                                if model.userSessionManager.userName != nil {
                                    Section() {
                                        ForEach(model.userFunctionCommunities) { community in
                                            CommunityRow(community: community, isFavoritable: false, showPosts: $showPosts, target: $target, loadPosts: $loadPosts,
                                                         isInboxInternalPresented: $isInboxInternalPresented)
                                        }
                                    }
                                }
                            }
                            if !model.favoriteCommunities.isEmpty {
                                Section(header: Text("Favorites")) {
                                    ForEach(filteredFavoriteCommunities) { community in
                                        CommunityRow(community: community, showPosts: $showPosts, target: $target, loadPosts: $loadPosts,
                                                     isInboxInternalPresented: $isInboxInternalPresented)
                                    }
                                }
                                .background(Color.clear)
                            }
                            if !model.communityCollections.isEmpty {
                                Section(header: Text("Collections")) {
                                    ForEach(filteredCollections) { collection in
                                        CollectionRow(collection: collection, showPosts: $showPosts, target: $target, loadPosts: $loadPosts,
                                                      isInboxInternalPresented: $isInboxInternalPresented)
                                    }
                                }
                                .background(Color.clear)
                            }
                            if !model.communities.isEmpty {
                                Section(header: Text("Subreddits")) {
                                    ForEach(filteredSubscribedCommunities) { community in
                                        CommunityRow(community: community, showPosts: $showPosts, target: $target, loadPosts: $loadPosts,
                                                     isInboxInternalPresented: $isInboxInternalPresented)
                                    }
                                }
                                .background(Color.clear)
                            }
                        }
                        .listStyle(PlainListStyle())
                        .refreshable {
                            model.loadCommunitiesData()
                        }
                    }
                    if !model.pages.isEmpty {
                        ZStack {
                            Circle()
                                .fill(Color.themeColor)
                                .frame(width: 65, height: 65, alignment: .bottomTrailing)
                                .onTapGesture {
                                    restoreScroll = true
//                                    showPosts = false
//                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                        showPosts = true
//                                    }
                                }
                            Image(systemName: "chevron.right")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                        }
                        .padding(EdgeInsets(top: 0, leading: 0, bottom: 30, trailing: 30))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .navigationTitle("Communities")
                .navigationBarTitleDisplayMode(.inline)
                .navigationDestination(isPresented: $showPosts) {
                    PostsViewEnclosure(itemInView: $itemInView, restoreScroll: $restoreScroll, target: $target, loadPosts: $loadPosts)
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
    
    var filteredCollections: [CollectionListItem] {
        if searchText.isEmpty {
            return model.communityCollections
        } else {
            return model.communityCollections.filter {
                $0.name.lowercased().contains(searchText.lowercased())
            }
        }
    }
    
    var filteredFavoriteCommunities: [Community] {
        if searchText.isEmpty {
            return model.favoriteCommunities
                .sorted { $0.name.lowercased() < $1.name.lowercased() }
        } else {
            return model.favoriteCommunities
                .filter { $0.name.lowercased().contains(searchText.lowercased()) }
                .sorted { $0.name.lowercased() < $1.name.lowercased() }
        }
    }
}

struct CommunityRow: View {
    @EnvironmentObject var model: Model
    @EnvironmentObject var commentsModel: CommentsModel
    var community: Community
    var isFavoritable: Bool = true
    @Binding var showPosts: Bool
    @Binding var target: CommunityOrUser
    @Binding var loadPosts: Bool
    @Binding var isInboxInternalPresented: Bool
    
    var body: some View {
        Button(action: {
            isInboxInternalPresented = false
            loadPosts = true
            target = CommunityOrUser(community: community)
            commentsModel.resetPages()
            model.resetPagesTo(target: target)
            showPosts = true
        }) {
            HStack {
                if community.iconName != nil {
                    Text(Image(systemName: community.iconName!))
                } else if let icon = community.iconURL {
                    AsyncImage(url: URL(string: icon)) { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: 30, maxHeight: 30)
                            .clipShape(Circle())
                    } placeholder: {
                        Text(Image(systemName: "r.circle.fill"))
                            .frame(maxWidth: 30, maxHeight: 30)
                    }
                }
                Text(community.displayName ?? community.name.prefix(1).capitalized + community.name.dropFirst())
                    .lineLimit(1)
                if isFavoritable && model.userName != nil {
                    Spacer()
                    if community.isFavorite {
                        Image(systemName: "star.fill")
                            .foregroundColor(.secondary)
                            .frame(alignment: .trailing)
                            .onTapGesture {
                                model.toggleAsFavoriteCommunity(community: community)
                            }
                    } else {
                        Image(systemName: "star")
                            .foregroundColor(.secondary)
                            .frame(alignment: .trailing)
                            .onTapGesture {
                                model.toggleAsFavoriteCommunity(community: community)
                            }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .listRowBackground(Color.clear)
    }
}

struct CollectionRow: View {
    @EnvironmentObject var model: Model
    @EnvironmentObject var commentsModel: CommentsModel
    var collection: CollectionListItem
    var isFavoritable: Bool = true
    @Binding var showPosts: Bool
    @Binding var target: CommunityOrUser
    @Binding var loadPosts: Bool
    @Binding var isInboxInternalPresented: Bool
    
    var body: some View {
        Button(action: {
            isInboxInternalPresented = false
            loadPosts = true
            target = CommunityOrUser(community: Community(collection: collection))
            commentsModel.resetPages()
            model.resetPagesTo(target: target)
            showPosts = true
        }) {
            HStack {
                Text(Image(systemName: "circle.hexagongrid.fill"))
                    .frame(maxWidth: 30, maxHeight: 30)
                Text(collection.name)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .listRowBackground(Color.clear)
    }
}


struct UserSection: View {
    @EnvironmentObject var model: Model
    @EnvironmentObject var commentsModel: CommentsModel
    @EnvironmentObject var settingsModel: SettingsModel
    @EnvironmentObject var messageModel: MessageModel
    @EnvironmentObject var overlayModel: MessageOverlayModel
    @Binding var loginPopupShowing: Bool
    @Binding var showPosts: Bool
    @Binding var target: CommunityOrUser
    @Binding var loadPosts: Bool
    @Binding var isInboxInternalPresented: Bool
    @State private var showingExitAlert = false
    
    var body: some View {
        if model.userSessionManager.userName != nil {
            Menu {
                Button(action: {
                    isInboxInternalPresented = false
                    loadPosts = true
                    target = CommunityOrUser(user: User(model.userName!))
                    model.resetPagesTo(target: target)
                    commentsModel.resetPages()
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
                if settingsModel.hasPremium {
                    Menu {
                        ForEach(model.savedUserNames, id: \.self) { userName in
                            Button(userName, action: {
                                model.switchAccountTo(userName: userName)
                                if !messageModel.messages.isEmpty {
                                    // reload only if previously loaded
                                    messageModel.openInbox(forceLoad: true)
                                }
                                overlayModel.show(duration: 3, loading: true)
                            })
                        }
                    } label: {
                        Label("Switch account", systemImage: "person.2")
                    }
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
                    Button("Cancel", role: .cancel) { showingExitAlert = false }
                    Button("Log out") {
                        model.logOut()
                        showingExitAlert = false
                        loginPopupShowing = true
                    }.keyboardShortcut(.defaultAction)
                } message: {
                    Text("To add a new account you first need to log out of your current session.")
                }
            }
        } else {
            if model.savedUserNames.isEmpty || !settingsModel.hasPremium {
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
