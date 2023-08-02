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
    @Binding var restoreScroll: Bool
    @Binding var target: CommunityOrUser
    @Binding var loadPosts: Bool
//    @State var showComments = false
//    @State var commentInView = ""
    @State var isPostCreatorShowing: Bool = false
    var filters: KeyValuePairs<String, String> {
        if model.pages[target.getCode()]!.selectedCommunity.isUser && model.userName == model.pages[target.getCode()]!.selectedCommunity.user!.name {
            return [
                "": "All", "comments": "Comments", "submitted": "Submitted", "gilded": "Gilded",
                "upvoted": "Upvoted", "downvoted": "Downvoted", "hidden": "Hidden", "saved": "Saved"
            ]
        }
        return [
            "": "All", "comments": "Comments", "submitted": "Submitted", "gilded": "Gilded"
        ]
    }
    @State private var filter = ""
    
    var body: some View {
        ZStack {
            Spacer()
                .padding()
                .frame(maxHeight: .infinity, alignment: .top)
                .task {
                    if loadPosts {
                        model.loadCommunity(community: target)
                        loadPosts = false
                    }
                }
            if model.pages[target.getCode()] != nil {
                ScrollViewReader { proxy in
                    List {
                        if model.pages[target.getCode()]!.selectedCommunity.isUser {
                            Picker("Filter By", selection: $filter) {
                                ForEach(filters, id: \.key) { key, value in
                                    Text(value)
                                }
                            }.onChange(of: filter) { _ in
                                model.loadCommunity(community: model.pages[target.getCode()]!.selectedCommunity, filter: filter)
                            }
                            .foregroundColor(.secondary)
                            .listRowSeparator(.hidden)
                        }
                        ForEach(model.pages[target.getCode()]!.items) { item in
                            if !item.isComment {
                                PostRow(post: item.post!, target: $target)
                                    .contextMenu{ PostRowMenu(post: item.post!, target: $target) }
                                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                        Button { model.toggleUpvotePost(target: target.getCode(), post: item.post!) } label: {
                                            Image(systemName: "arrow.up")
                                        }
                                        .tint(.upvoteOrange)
                                        Button { model.toggleDownvotePost(target: target.getCode(), post: item.post!) } label: {
                                            Image(systemName: "arrow.down")
                                        }
                                        .tint(.downvoteBlue)
                                    }
                                    .onAppear(perform: {
                                        itemInView = item.id
                                        if (item.isActiveLoadMarker) {
                                            item.deactivateLoadMarker()
                                            model.loadNextPagePosts(target: target.getCode())
                                        }
                                    })
                                    .listRowInsets(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0))
                                    .listRowSeparator(.hidden)
                                    .overlay(
                                        NavigationLink(destination: CommentsView(post: item.post!, restorePostsScroll: $restoreScroll, postsTarget: $target),
                                                       label: { EmptyView() })
                                        .opacity(0)
                                    )
                            } else {
                                PostCommentRow(comment: item.comment!)
                                    .onAppear(perform: {
                                        itemInView = item.id
                                        if (item.isActiveLoadMarker) {
                                            item.deactivateLoadMarker()
                                            model.loadNextPagePosts(target: target.getCode())
                                        }
                                    })
                                    .listRowInsets(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0))
                                    .listRowSeparator(.hidden)
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                    .navigationTitle(model.pages[target.getCode()]!.title)
                    .navigationBarTitleDisplayMode(.inline)
//                    .navigationBarBackButtonHidden(true)
                    .navigationBarHidden(isPostCreatorShowing)
                    .toolbar {
//                        ToolbarItem(placement: .navigationBarLeading) {
//                            Button {
//                                model.dismissPage(target: target)
//                                dismiss()
//                            } label: {
//                                HStack {
//                                    Image(systemName: "chevron.backward")
//                                    Text("Back")
//                                }
//                            }
//                        }
                        ToolbarItem(placement: .navigationBarTrailing) {
                            HStack {
                                SortMenu(target: $target)
                                ActionsMenu(isPostCreatorShowing: $isPostCreatorShowing, target: $target)
                            }
                        }
                    }
                    .onAppear(perform: {
                        if restoreScroll {
                            proxy.scrollTo(itemInView)
                        }
                    })
                    .toolbarBackground(.visible, for: .navigationBar)
                }
                if isPostCreatorShowing {
                    CreatePostForm(community: model.pages[target.getCode()]!.selectedCommunity.community!, isShowing: $isPostCreatorShowing)
                }
            }
        }
    }
}

struct ActionsMenu: View {
    @EnvironmentObject var model: Model
    @Binding var isPostCreatorShowing: Bool
    @Binding var target: CommunityOrUser
    
    var body: some View {
        Menu {
            if !target.isUser && !target.isMultiCommunity {
                Button(action: { isPostCreatorShowing = true }) {
                    Label("Create Post", systemImage: "plus")
                }
                NavigationLink(destination: CommunityAboutView(community: model.pages[target.getCode()]!.selectedCommunity.community!)) {
                    Button(action: { }) {
                        Label("About this community", systemImage: "questionmark.circle")
                    }
                }
                Button(action: { model.toggleSubscribe(target: target) }) {
                    if model.subscribedCommunities.contains(where: { c in c.id.lowercased() == target.id.lowercased() }) {
                        Label("Unsubscribe", systemImage: "heart.slash")
                    } else {
                        Label("Subscribe", systemImage: "heart")
                    }
                }
            } else if target.isUser {
                NavigationLink(destination: UserAboutView(user: model.pages[target.getCode()]!.selectedCommunity.user!)) {
                    Button(action: { }) {
                        Label("About user", systemImage: "person")
                    }
                }
                if model.pages[target.getCode()]!.selectedCommunity.user!.about != nil {
                    Button(action: { model.toggleFriend(target: target) }) {
                        if model.pages[target.getCode()]!.selectedCommunity.user!.about!.is_friend {
                            Label("Remove from friends", systemImage: "heart.slash")
                        } else {
                            Label("Add as friend", systemImage: "heart")
                        }
                    }
                    if !model.pages[target.getCode()]!.selectedCommunity.user!.about!.is_blocked {
                        Button(action: { model.blockUser(target: target) }) {
                            Label("Block user", systemImage: "xmark")
                        }
                    }
                }
            }
        } label: {
            Label("Actions", systemImage: "ellipsis")
        }
    }
}

struct SortMenu: View {
    @EnvironmentObject var model: Model
    @Binding var target: CommunityOrUser
    
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
            if !target.isUser {
                Button(action: { sortCommunity(sortBy: "rising", sortTime: nil) }) {
                    Label("Rising", systemImage: ViewModelAttributes.sortModifierIcons["rising"]!)
                }
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
            Label("Sort by", systemImage: model.selectedSortingIcon(target: target.getCode()))
        }
    }
    
    func sortCommunity(sortBy: String?, sortTime: String?) {
        model.loadCommunity(community: model.pages[target.getCode()]!.selectedCommunity, sortBy: sortBy, sortTime: sortTime)
    }
}

struct CreatePostForm: View {
    @EnvironmentObject var postCreateModel: PostCreateModel
    @FocusState private var isFieldFocused: Bool
    @State private var loading: Bool = false
    var community: Community
    @Binding var isShowing: Bool
    @State private var title: String = ""
    @State private var link: String = "https://"
    @State private var text: String = ""
    var types = ["Link", "Text"]
    @State private var type = "Link"
    @State private var enableReplies = true
    @State private var showingExitAlert = false
    @State private var showingFailedAlert = false
    @State private var showingSuccessAlert = false
    @State private var awaitingResponse: Bool = false
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color(UIColor.systemBackground))
                .ignoresSafeArea()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onAppear {
                    isFieldFocused = true
                    postCreateModel.openCreatePage(community: community)
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
                                            showingSuccessAlert = true
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
                        .alert("Post successfully created", isPresented: $showingSuccessAlert) {
                            Button("OK", role: .cancel) {
                                showingSuccessAlert = false
                                isShowing = false
                                // TODO: redirect to newly created post
                            }
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

struct CommunityAboutView: View {
    @EnvironmentObject var model: Model
    var community: Community
    
    var details = ["About", "Rules"]
    @State private var selectedDetail = "About"
    
    var body: some View {
        if community.about != nil {
            ScrollView {
                VStack(spacing: 10) {
                    Text(community.about!.headerTitle ?? "")
                        .font(.subheadline)
                        .frame(alignment: .leading)
                        .padding(EdgeInsets(top: 0, leading: 10, bottom: 15, trailing: 10))
                        .foregroundColor(.secondary)
                    Picker("View", selection: $selectedDetail) {
                        ForEach(details, id: \.self) {
                            Text($0)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(EdgeInsets(top: 0, leading: 10, bottom: 10, trailing: 10))
                    if selectedDetail == "About" {
                        HStack() {
                            VStack {
                                Text("Subscribers")
                                    .lineLimit(1)
                                    .font(.system(size: 14))
                                    .fontWeight(.bold)
                                Text(formatScore(score: String(community.about!.subscribers)))
                                    .font(.system(size: 28))
                            }
                            .padding(EdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 0))
                            .frame(maxWidth: .infinity)
                            VStack {
                                Text("Active Users")
                                    .lineLimit(1)
                                    .font(.system(size: 14))
                                    .fontWeight(.bold)
                                Text(formatScore(score: String(community.about!.activeUserCount)))
                                    .font(.system(size: 28))
                            }
                            .frame(maxWidth: .infinity)
                            VStack {
                                Text("Community age")
                                    .lineLimit(1)
                                    .font(.system(size: 14))
                                    .fontWeight(.bold)
                                Text(community.about!.created)
                                    .font(.system(size: 28))
                            }
                            .padding(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 10))
                            .frame(maxWidth: .infinity)
                        }
                        Divider()
                        Text(community.about!.description ?? "")
                            .font(.system(size: 18))
                            .padding(EdgeInsets(top: 8, leading: 8, bottom: 0, trailing: 8))
                    } else {
                        ForEach(community.rules) { rule in
                            Text(rule.short_name)
                                .padding(EdgeInsets(top: 8, leading: 8, bottom: 0, trailing: 8))
                                .font(.system(size: 18))
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text(rule.description)
                                .padding(EdgeInsets(top: 8, leading: 8, bottom: 0, trailing: 8))
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                        .frame(height: 50)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .navigationTitle(community.about!.title)
            }
        }
    }
}

struct UserAboutView: View {
    @EnvironmentObject var model: Model
    var user: User
    
    var body: some View {
        if user.about != nil {
            ScrollView {
                VStack {
                    Spacer().frame(height: 20)
//                    if user.about!.icon_img != nil {
//                        HStack {
//                            AsyncImage(url: URL(string: user.about!.icon_img!)) { image in
//                                image.image?
//                                    .resizable()
//                                    .scaledToFill()
//                                    .frame(maxWidth: 80, maxHeight: 80)
//                            }
//                            VStack {
//                                Text(user.name).font(.headline)
//                                Text(user.about!.public_description)
//                                    .foregroundColor(.secondary)
//                                    .font(.system(size: 14))
//                            }
//                        }
//                    }
                    HStack {
                        VStack {
                            Text("Post karma")
                                .lineLimit(1)
                                .font(.system(size: 14))
                                .fontWeight(.bold)
                            Text(String(user.about!.link_karma))
                                .font(.system(size: 24))
                        }
                        .padding(EdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 0))
                        .frame(maxWidth: .infinity)
                        VStack {
                            Text("Comment karma")
                                .lineLimit(1)
                                .font(.system(size: 14))
                                .fontWeight(.bold)
                            Text(String(user.about!.comment_karma))
                                .font(.system(size: 24))
                        }
                        .frame(maxWidth: .infinity)
                    }
                    HStack {
                        VStack {
                            Text("Awarder karma")
                                .lineLimit(1)
                                .font(.system(size: 14))
                                .fontWeight(.bold)
                            Text(String(user.about!.awarder_karma))
                                .font(.system(size: 24))
                        }
                        .padding(EdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 0))
                        .frame(maxWidth: .infinity)
                        VStack {
                            Text("Awardee karma")
                                .lineLimit(1)
                                .font(.system(size: 14))
                                .fontWeight(.bold)
                            Text(String(user.about!.awardee_karma))
                                .font(.system(size: 24))
                        }
                        .frame(maxWidth: .infinity)
                    }
                    Text(user.about!.public_description)
                        .foregroundColor(.secondary)
                        .font(.system(size: 14))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                    ForEach(user.trophies) { trophy in
                        HStack(spacing: 10) {
                            AsyncImage(url: URL(string: trophy.icon_70)) { image in
                                image.image?
                                    .resizable()
                                    .scaledToFill()
                                    .frame(maxWidth: 60, maxHeight: 60)
                            }
                            VStack(spacing: 10) {
                                Text(trophy.name)
                                    .fontWeight(.bold)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                if trophy.description != nil {
                                    Text(trophy.description!)
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(EdgeInsets(top: 15, leading: 10, bottom: 0, trailing: 10))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    Spacer().frame(height: 50)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .navigationTitle(user.name)
            }
        }
    }
}
