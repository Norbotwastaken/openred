//
//  Search.swift
//  openred
//
//  Created by Norbert Antal on 6/25/23.
//

import SwiftUI

struct SearchView: View {
    @EnvironmentObject var model: Model
    @EnvironmentObject var commentsModel: CommentsModel
    @EnvironmentObject var searchModel: SearchModel
    @Binding var tabSelection: Int
    @Binding var showPosts: Bool
    @Binding var target: CommunityOrUser
    @Binding var isInboxInternalPresented: Bool
    @State private var communityName: String = ""
    @FocusState private var isFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            TextField("Search...", text: $communityName)
                .textFieldStyle(.roundedBorder)
                .focused($isFieldFocused)
                .border(Color(UIColor.systemGray6))
                .autocapitalization(.none)
                .onTapGesture {} // override other onTap
                .onSubmit {
                    let community = CommunityOrUser(community: Community(communityName, isMultiCommunity: ["all", "popular", "saved", "mod", ""]
                        .contains(communityName.lowercased())))
                    performNavigation(community)
                }
                .onChange(of: communityName) { value in
                    if communityName.count > 2 {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            if communityName == value {
                                searchModel.searchCommunities(searchQuery: value)
                            }
                        }
                    } else {
                        searchModel.communities = []
                    }
                }
                .frame(alignment: .top)
            if communityName.count > 2 {
                ScrollView {
                    VStack(spacing: 0) {
                        ZStack {
                            Rectangle()
                                .fill(Color(UIColor.systemGray6))
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                            Label("Community r/\(communityName)", systemImage: "r.circle")
                                .padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                        }
                        .frame(maxWidth: .infinity, maxHeight: 45, alignment: .top)
                        .onTapGesture {
                            let community = CommunityOrUser(community: Community(communityName, isMultiCommunity: ["all", "popular", "saved", "mod", ""]
                                .contains(communityName.lowercased())))
                            performNavigation(community)
                        }
                        Divider()
                        ZStack {
                            Rectangle()
                                .fill(Color(UIColor.systemGray6))
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                            Label("User \(communityName)", systemImage: "person")
                                .padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                        }
                        .frame(maxWidth: .infinity, maxHeight: 45, alignment: .top)
                        .onTapGesture {
                            let community = CommunityOrUser(user: User(communityName))
                            performNavigation(community)
                        }
                        Divider()
                        ForEach(searchModel.communities) { community in
                            SearchResultView(community: community, tabSelection: $tabSelection,
                                             showPosts: $showPosts, target: $target, communityName: $communityName,
                                             isInboxInternalPresented: $isInboxInternalPresented)
                        }
                    }
                }
            } else {
                ScrollView {
                    if !searchModel.visitedCommunities.isEmpty {
                        VStack(spacing: 0) {
                            Spacer()
                                .frame(height: 25)
                            HStack {
                                Text("Recently visited".uppercased())
                                    .font(.system(size: 14, weight: .semibold))
                                    .lineLimit(1)
                                    .frame(maxWidth: .infinity, alignment: .topLeading)
                                Image(systemName: "trash")
                                    .frame(maxWidth: .infinity, alignment: .topTrailing)
                                    .onTapGesture {
                                        searchModel.visitedCommunities = []
                                    }
                            }
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            Spacer()
                                .frame(maxWidth: .infinity, maxHeight: 30)
                            ForEach(searchModel.visitedCommunities) { community in
                                SearchResultView(community: community, tabSelection: $tabSelection,
                                                 showPosts: $showPosts, target: $target, communityName: $communityName,
                                                 isInboxInternalPresented: $isInboxInternalPresented,
                                                 color: Color(UIColor.systemBackground), iconName: "clock")
                            }
                        }
                    }
                    if !searchModel.popularCommunities.isEmpty {
                        VStack(spacing: 0) {
                            Spacer()
                                .frame(height: 25)
                            Text("Popular communities".uppercased())
                                .font(.system(size: 14, weight: .semibold))
                                .lineLimit(1)
                                .frame(maxWidth: .infinity, alignment: .topLeading)
                                .foregroundColor(.secondary)
                            Spacer()
                                .frame(maxWidth: .infinity, maxHeight: 30)
                            ForEach(searchModel.popularCommunities) { community in
                                SearchResultView(community: community, tabSelection: $tabSelection,
                                                 showPosts: $showPosts, target: $target, communityName: $communityName,
                                                 isInboxInternalPresented: $isInboxInternalPresented,
                                                 color: Color(UIColor.systemBackground), iconName: "chart.line.uptrend.xyaxis")
                            }
                        }
                    }
                }
                .refreshable {
                    searchModel.loadPopularCommunities()
                }
            }
        }
        .padding(EdgeInsets(top: 50, leading: 30, bottom: 0, trailing: 30))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
//        .background(Color(UIColor.systemGray6))
        .onTapGesture {
            isFieldFocused = false
        }
    }
    
    func performNavigation(_ community: CommunityOrUser) {
        isInboxInternalPresented = false
        model.resetPagesTo(target: community)
        commentsModel.resetPages()
        model.loadCommunity(community: community)
        target = community
        communityName = ""
        tabSelection = 1
        showPosts = true
    }
}

struct SearchResultView: View {
    @EnvironmentObject var model: Model
    @EnvironmentObject var commentsModel: CommentsModel
    @EnvironmentObject var searchModel: SearchModel
    var community: Community
    @Binding var tabSelection: Int
    @Binding var showPosts: Bool
    @Binding var target: CommunityOrUser
    @Binding var communityName: String
    @Binding var isInboxInternalPresented: Bool
    var color: Color = Color(UIColor.systemGray6)
    var iconName: String = "chevron.right.circle"
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(color)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            Label(community.name, systemImage: iconName)
                .padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: 45, alignment: .top)
        .onTapGesture {
            searchModel.addVisitedCommunity(community: community)
            let targetCommunity = CommunityOrUser(community: community)
            isInboxInternalPresented = false
            model.resetPagesTo(target: targetCommunity)
            commentsModel.resetPages()
            model.loadCommunity(community: targetCommunity)
            target = targetCommunity
            communityName = ""
            tabSelection = 1
            showPosts = true
        }
        Divider()
    }
}
