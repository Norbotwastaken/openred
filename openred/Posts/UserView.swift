////
////  UserView.swift
////  openred
////
////  Created by Norbert Antal on 7/20/23.
////
//
//import SwiftUI
//import AVKit
//
//struct UserView: View {
//    @EnvironmentObject var model: Model
////    @EnvironmentObject var popupViewModel: PopupViewModel
//    @Binding var itemInView: String
////    @State var showComments = false
////    @State var commentInView = ""
//    @State var isPostCreatorShowing: Bool = false
//    var types: KeyValuePairs<String, String> {
//        return [
//            "": "All", "comments": "Comments", "submitted": "Submitted", "gilded": "Gilded",
////            "upvoted": "Upvoted", "downvoted": "downvoted", "hidden": "Hiddden", "saved": "Saved"
//        ]
//    }
//    @State private var type = "inbox"
//
//    var body: some View {
//        ZStack {
//            ScrollViewReader { proxy in
//                List {
//                    VStack {
//                        Picker("Filter By", selection: $type) {
//                            ForEach(types, id: \.key) { key, value in
//                                Text(value)
//                            }
//                        }.onChange(of: type) { _ in
////                            messageModel.openInbox(filter: type)
//                        }
//                        .foregroundColor(.secondary)
//                    }
//                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
//                    ForEach(model.items) { item in
//                        if !item.isComment {
//                            PostRow(post: item.post!)
//                                .swipeActions(edge: .leading, allowsFullSwipe: true) {
//                                    Button { model.toggleUpvotePost(post: item.post!) } label: {
//                                        Image(systemName: "arrow.up")
//                                    }
//                                    .tint(.upvoteOrange)
//                                    Button { model.toggleDownvotePost(post: item.post!) } label: {
//                                        Image(systemName: "arrow.down")
//                                    }
//                                    .tint(.downvoteBlue)
//                                }
//                                .onAppear(perform: {
//                                    itemInView = item.id
//                                    if (item.isActiveLoadMarker) {
//                                        item.deactivateLoadMarker()
//                                        model.loadNextPagePosts()
//                                    }
//                                })
//                                .listRowInsets(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0))
//                                .listRowSeparator(.hidden)
//                                .overlay(
//                                    NavigationLink(destination: CommentsView(post: item.post!), label: { EmptyView() })
//                                        .opacity(0)
//                                )
//                        } else {
//                            PostCommentRow(comment: item.comment!)
//                                .onAppear(perform: {
//                                    itemInView = item.id
//                                    if (item.isActiveLoadMarker) {
//                                        item.deactivateLoadMarker()
//                                        model.loadNextPagePosts()
//                                    }
//                                })
//                                .listRowInsets(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0))
//                                .listRowSeparator(.hidden)
//                        }
//                    }
//                }
//                .listStyle(PlainListStyle())
//                .navigationTitle(model.title)
//                .navigationBarTitleDisplayMode(.inline)
//                .navigationBarHidden(isPostCreatorShowing)
//                .toolbar {
//                    ToolbarItem(placement: .navigationBarTrailing) {
//                        HStack {
//                            UserSortMenu()
//                            UserActionsMenu(isPostCreatorShowing: $isPostCreatorShowing)
//                        }
//                    }
//                }
//                .onAppear(perform: {
//                    proxy.scrollTo(itemInView)
//                })
//                .toolbarBackground(.visible, for: .navigationBar)
//            }
//            if isPostCreatorShowing {
////                CreatePostForm(community: model.selectedCommunity, isShowing: $isPostCreatorShowing)
//            }
//        }
//    }
//}
//
//struct UserActionsMenu: View {
//    @EnvironmentObject var model: Model
//    @Binding var isPostCreatorShowing: Bool
//
//    var body: some View {
//        Menu {
//            Button(action: { isPostCreatorShowing = true }) {
//                Label("Create Post", systemImage: "plus")
//            }
//        } label: {
//            Label("Actions", systemImage: "ellipsis")
//        }
//    }
//}
//
//struct UserSortMenu: View {
//    @EnvironmentObject var model: Model
//
//    var body: some View {
//        Menu {
//            Button(action: {sortCommunity(sortBy: nil, sortTime: nil)}) {
//                Label("Hot", systemImage: ViewModelAttributes.sortModifierIcons["hot"]!)
//            }
//            Menu {
//                Button("Hour", action: { sortCommunity(sortBy: "top", sortTime: "hour") })
//                Button("Day", action: { sortCommunity(sortBy: "top", sortTime: "day") })
//                Button("Week", action: { sortCommunity(sortBy: "top", sortTime: "week") })
//                Button("Month", action: { sortCommunity(sortBy: "top", sortTime: "month") })
//                Button("Year", action: { sortCommunity(sortBy: "top", sortTime: "year") })
//                Button("All Time", action: { sortCommunity(sortBy: "top", sortTime: "all") })
//            } label: {
//                Label("Top", systemImage: ViewModelAttributes.sortModifierIcons["top"]!)
//            }
//            Button(action: { sortCommunity(sortBy: "new", sortTime: nil) }) {
//                Label("New", systemImage: ViewModelAttributes.sortModifierIcons["new"]!)
//            }
//            Menu {
//                Button("Hour", action: { sortCommunity(sortBy: "controversial", sortTime: "hour") })
//                Button("Day", action: { sortCommunity(sortBy: "controversial", sortTime: "day") })
//                Button("Week", action: { sortCommunity(sortBy: "controversial", sortTime: "week") })
//                Button("Month", action: { sortCommunity(sortBy: "controversial", sortTime: "month") })
//                Button("Year", action: { sortCommunity(sortBy: "controversial", sortTime: "year") })
//                Button("All Time", action: { sortCommunity(sortBy: "controversial", sortTime: "all") })
//            } label: {
//                Label("Controversial", systemImage: ViewModelAttributes.sortModifierIcons["controversial"]!)
//            }
//        } label: {
//            Label("Sort by", systemImage: model.selectedSortingIcon)
//        }
//    }
//
//    func sortCommunity(sortBy: String?, sortTime: String?) {
//        model.loadCommunity(community: model.selectedCommunity,
//                            sortBy: sortBy, sortTime: sortTime)
//    }
//}
