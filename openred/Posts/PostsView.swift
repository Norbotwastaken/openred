//
//  PostsView.swift
//  openred
//
//  Created by Norbert Antal on 6/6/23.
//

import SwiftUI
import AVKit

struct PostsView: View {
    @EnvironmentObject var model: Model
    @EnvironmentObject var popupViewModel: PopupViewModel
    @Binding var itemInView: String
    @State var showComments = false
    @State var commentInView = ""
    
    var body: some View {
        ZStack {
            ScrollViewReader { proxy in
                List {
                    ForEach(model.posts) { post in
                        PostRow(post: post)
                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                Button { model.toggleUpvotePost(post: post) } label: {
                                    Image(systemName: "arrow.up")
                                }
                                .tint(.upvoteOrange)
                                Button { model.toggleDownvotePost(post: post) } label: {
                                    Image(systemName: "arrow.down")
                                }
                                .tint(.downvoteBlue)
                            }
                            .onAppear(perform: {
                                itemInView = post.id
                                if (post.isActiveLoadMarker) {
                                    post.deactivateLoadMarker()
                                    model.loadNextPagePosts()
                                }
                            })
                            .listRowInsets(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0))
                            .listRowSeparator(.hidden)
                            .overlay(
                                NavigationLink(destination: CommentsView(post: post, commentInView: $commentInView), label: { EmptyView() })
                                .opacity(0))
                    }
                }
                .listStyle(PlainListStyle())
                .navigationTitle(model.title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        HStack {
                            SortMenu()
                            Button {
                                // Perform an action
                                print("Add Item Tapped")
                            } label: {
                                Image(systemName: "ellipsis")
                            }
                        }
                    }
                }
                .onAppear(perform: {
                    proxy.scrollTo(itemInView)
                })
                .toolbarBackground(.visible, for: .navigationBar)
            }
        }
    }
}

struct SortMenu: View {
    @EnvironmentObject var model: Model
    
    var body: some View {
        Menu {
            Button(action: {sortCommunity(sortBy: nil, sortTime: nil)}) {
                Label("Hot", systemImage: ViewModelAttributes.sortModifierIcons["hot"]!)
            }
            Menu {
                Button("Hour", action: { sortCommunity(sortBy: "top", sortTime: "hour") })
                Button("Day", action: { sortCommunity(sortBy: "top", sortTime: "day") })
                Button("Week", action: { sortCommunity(sortBy: "top", sortTime: "week") })
                Button("Month", action: { sortCommunity(sortBy: "top", sortTime: "month") })
                Button("Year", action: { sortCommunity(sortBy: "top", sortTime: "year") })
                Button("All Time", action: { sortCommunity(sortBy: "top", sortTime: "all") })
            } label: {
                Label("Top", systemImage: ViewModelAttributes.sortModifierIcons["top"]!)
            }
            Button(action: { sortCommunity(sortBy: "new", sortTime: nil) }) {
                Label("New", systemImage: ViewModelAttributes.sortModifierIcons["new"]!)
            }
            Button(action: { sortCommunity(sortBy: "rising", sortTime: nil) }) {
                Label("Rising", systemImage: ViewModelAttributes.sortModifierIcons["rising"]!)
            }
            Menu {
                Button("Hour", action: { sortCommunity(sortBy: "controversial", sortTime: "hour") })
                Button("Day", action: { sortCommunity(sortBy: "controversial", sortTime: "day") })
                Button("Week", action: { sortCommunity(sortBy: "controversial", sortTime: "week") })
                Button("Month", action: { sortCommunity(sortBy: "controversial", sortTime: "month") })
                Button("Year", action: { sortCommunity(sortBy: "controversial", sortTime: "year") })
                Button("All Time", action: { sortCommunity(sortBy: "controversial", sortTime: "all") })
            } label: {
                Label("Controversial", systemImage: ViewModelAttributes.sortModifierIcons["controversial"]!)
            }
        } label: {
            Label("Sort by", systemImage: model.selectedSortingIcon)
        }
    }
    
    func sortCommunity(sortBy: String?, sortTime: String?) {
        model.loadCommunity(communityCode: model.selectedCommunityCode,
                            sortBy: sortBy, sortTime: sortTime)
    }
}
