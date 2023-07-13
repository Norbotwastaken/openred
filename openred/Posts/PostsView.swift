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
//    @EnvironmentObject var popupViewModel: PopupViewModel
    @Binding var itemInView: String
//    @State var showComments = false
//    @State var commentInView = ""
    @State var isPostCreatorShowing: Bool = false
    
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
                                NavigationLink(destination: CommentsView(post: post), label: { EmptyView() })
                                .opacity(0))
                    }
                }
                .listStyle(PlainListStyle())
                .navigationTitle(model.title)
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarHidden(isPostCreatorShowing)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        HStack {
                            SortMenu()
                            ActionsMenu(isPostCreatorShowing: $isPostCreatorShowing)
                        }
                    }
                }
                .onAppear(perform: {
                    proxy.scrollTo(itemInView)
                })
                .toolbarBackground(.visible, for: .navigationBar)
            }
            if isPostCreatorShowing {
                CreatePostForm(communityCode: model.selectedCommunityCode, isShowing: $isPostCreatorShowing)
            }
        }
    }
}

struct ActionsMenu: View {
    @EnvironmentObject var model: Model
    @Binding var isPostCreatorShowing: Bool
    
    var body: some View {
        Menu {
            Button(action: { isPostCreatorShowing = true }) {
                Label("Create Post", systemImage: "plus")
            }
        } label: {
            Label("Actions", systemImage: "ellipsis")
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

struct CreatePostForm: View {
    @EnvironmentObject var postCreateModel: PostCreateModel
    @FocusState private var isFieldFocused: Bool
    @State private var loading: Bool = false
    var communityCode: String
    @Binding var isShowing: Bool
    @State private var title: String = ""
    @State private var link: String = "https://"
    @State private var text: String = ""
    var types = ["Link", "Text"]
    @State private var type = "Link"
    @State private var enableReplies = true
    @State private var showingExitAlert = false
    @State private var showingFailedAlert = false
    @State private var awaitingResponse: Bool = false
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color(UIColor.systemBackground))
                .ignoresSafeArea()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onAppear {
                    isFieldFocused = true
                    postCreateModel.openCreatePage(communityCode: communityCode)
                }
            VStack(spacing: 5) {
                HStack {
                    Image(systemName: "xmark")
                        .font(.system(size: 25))
                        .foregroundColor(Color(UIColor.systemBlue))
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .padding(EdgeInsets(top: 5, leading: 15, bottom: 0, trailing: 0))
                        .alert("Unsaved changes", isPresented: $showingExitAlert) {
                            Button("Exit", role: .destructive) { isShowing = false }
                            Button("Cancel", role: .cancel) {}
                        } message: {
                            Text("If you exit all changes will be lost.")
                        }
                        .onTapGesture {
                            if title == "" && link == "" && text == "" {
                                isShowing = false
                            } else {
                                showingExitAlert = true
                            }
                        }
                    Text("Submit post")
                        .font(.system(size: 20))
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity, alignment: .top)
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(Color(UIColor.systemBlue))
                        .font(.system(size: 25))
                        .frame(maxWidth: .infinity, alignment: .topTrailing)
                        .padding(EdgeInsets(top: 5, leading: 0, bottom: 0, trailing: 15))
                        .onTapGesture {
                            postCreateModel.post(isLink: type == "Link",title: title,
                                                 text: text, link: link, sendReplies: enableReplies)
                            awaitingResponse = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                if postCreateModel.submissionState == .failed {
                                    awaitingResponse = false
                                    showingFailedAlert = true
                                } else {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                                        awaitingResponse = false
                                        if postCreateModel.submissionState == .success {
                                            isShowing = false
                                        } else if postCreateModel.submissionState == .failed {
                                            showingFailedAlert = true
                                        }
                                    }
                                }
                            }
                        }
                        .alert("Failed to create post", isPresented: $showingFailedAlert) {
                            Button("OK", role: .cancel) { showingFailedAlert = false }
                        }
                }
                .frame(maxWidth: .infinity)
                VStack {
                    Picker("Post type", selection: $type) {
                        ForEach(types, id: \.self) {
                            Text($0)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(EdgeInsets(top: 20, leading: 0, bottom: 0, trailing: 0))
                    .frame(alignment: .top)
                    TextField("Title", text: $title, axis: .vertical)
                        .focused($isFieldFocused)
                        .padding(EdgeInsets(top: 20, leading: 0, bottom: 0, trailing: 0))
                        .frame(maxHeight: 80, alignment: .topLeading)
                    if type == "Link" {
                        TextField("Link", text: $link, axis: .vertical)
                            .focused($isFieldFocused)
                            .padding(EdgeInsets(top: 20, leading: 0, bottom: 0, trailing: 0))
                            .frame(maxHeight: 60, alignment: .topLeading)
                    } else {
                        TextField("Text", text: $text, axis: .vertical)
                            .focused($isFieldFocused)
                            .padding(EdgeInsets(top: 20, leading: 0, bottom: 0, trailing: 0))
                            .frame(maxHeight: 150, alignment: .topLeading)
                    }
                    Toggle("Send replies to my inbox", isOn: $enableReplies)
                        .tint(Color(UIColor.systemBlue))
                        .padding(EdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0))
                        .frame(alignment: .bottom)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            if awaitingResponse {
                Rectangle()
                    .fill(.black)
                    .opacity(0.6)
                    .ignoresSafeArea()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                ProgressView()
            }
        }
    }
}
