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
    @EnvironmentObject var settingsModel: SettingsModel
    @Environment(\.presentationMode) var presentation
    @Binding var itemInView: String
    @Binding var restoreScroll: Bool
    @Binding var target: CommunityOrUser
    @Binding var loadPosts: Bool
    @State var isPostCreatorShowing: Bool = false
    @State var isMessageEditorShowing: Bool = false
    @State var sortBy: String?
    @State var sortTime: String?
    @State var communityCollectionsShowing: Bool = false
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
    
    let coordinator = InterstitialAdCoordinator()
    let adViewControllerRepresentable = AdViewControllerRepresentable()
    var adViewControllerRepresentableView: some View {
      adViewControllerRepresentable
        .frame(width: .zero, height: .zero)
    }
    
    var body: some View {
        ZStack {
            Spacer()
                .padding()
                .frame(maxHeight: .infinity, alignment: .top)
                .task {
                    if coordinator.userSessionManager == nil {
                        coordinator.userSessionManager = self.settingsModel.userSessionManager
                    }
                    if loadPosts {
                        model.loadCommunity(community: target)
                        loadPosts = false
                        if settingsModel.shouldPresentAd() && target.isAdFriendly {
                            coordinator.loadAd(show: true, from: adViewControllerRepresentable.viewController)
                        }
                    }
                }
            if model.pages[target.getCode()] != nil {
                if model.pages[target.getCode()]!.interstitialTitle == nil {
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
                                        .listRowInsets(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0))
                                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                            PostSwipeAction(swipeAction: settingsModel.postLeftPrimary, post: item.post!, targetCode: target.getCode())
                                            PostSwipeAction(swipeAction: settingsModel.postLeftSecondary, post: item.post!, targetCode: target.getCode())
                                        }
                                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                            PostSwipeAction(swipeAction: settingsModel.postRightPrimary, post: item.post!, targetCode: target.getCode())
                                            PostSwipeAction(swipeAction: settingsModel.postRightSecondary, post: item.post!, targetCode: target.getCode())
                                        }
                                        .onAppear(perform: {
                                            itemInView = item.id
                                            if (item.isActiveLoadMarker) {
                                                item.deactivateLoadMarker()
                                                model.loadNextPagePosts(target: target.getCode())
                                            }
                                        })
                                        .listRowSeparator(.hidden)
                                        .overlay(
                                            NavigationLink(destination: CommentsView(restorePostsScroll: $restoreScroll,
                                                                                     link: item.post!.linkToThread).id(item.post!.linkToThread),
                                                           label: { EmptyView() }).id(item.post!.linkToThread)
                                            .opacity(0)
                                        )
                                        
                                } else {
                                    PostCommentRow(comment: item.comment!, spoilerBlurActive: item.comment!.spoiler)
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
                                            NavigationLink(destination: CommentsView(restorePostsScroll: $restoreScroll,
                                                                                     link: item.comment!.postLink!),
                                                           label: { EmptyView() }).id(item.comment!.postLink!)
                                            .opacity(0)
                                        )
                                }
                            }
                        }
                        .listStyle(PlainListStyle())
                        .navigationTitle(model.pages[target.getCode()]!.title)
                        .navigationBarTitleDisplayMode(.inline)
                        .navigationBarHidden(isPostCreatorShowing || isMessageEditorShowing)
                        .toolbar {
                            ToolbarItem(placement: .principal) {
                                VStack {
                                    Text(model.pages[target.getCode()]!.title)
                                        .font(.headline)
                                    if model.pages[target.getCode()]!.title != "" {
                                        Text(model.pages[target.getCode()]!.selectedSortingDisplayLabel)
                                            .font(.subheadline)
                                            .font(.system(size: 10))
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            ToolbarItem(placement: .navigationBarTrailing) {
                                HStack {
                                    SortMenu(target: $target, currentSortBy: $sortBy, currentSortTime: $sortTime)
                                    if (target.isUser || !target.isMultiCommunity) && model.userName != nil {
                                        ActionsMenu(isPostCreatorShowing: $isPostCreatorShowing, isMessageEditorShowing: $isMessageEditorShowing,
                                                    communityCollectionsShowing: $communityCollectionsShowing, target: $target)
                                    }
                                }
                            }
                        }
                        .onAppear(perform: {
                            if (restoreScroll && model.pages[target.getCode()]!.items.filter{ $0.id == itemInView }.first != nil) {
                                proxy.scrollTo(itemInView)
                            }
                        })
                        .toolbarBackground(.visible, for: .navigationBar)
                        .refreshable {
                            model.loadCommunity(community: target, sortBy: sortBy, sortTime: sortTime)
                        }
                        .popover(isPresented: $communityCollectionsShowing) {
                            CommunityCollectionView(target: target, communityCollectionsShowing: $communityCollectionsShowing)
                        }
                    }
                    if isPostCreatorShowing {
                        CreatePostForm(community: model.pages[target.getCode()]!.selectedCommunity.community!, isShowing: $isPostCreatorShowing)
                    }
                    if isMessageEditorShowing && target.isUser {
                        MessageEditor(isShowing: $isMessageEditorShowing, replyToMessage: Binding.constant(nil), userName: target.user!.name)
                    }
                } else {
                    VStack(spacing: 20) {
                        Text(model.pages[target.getCode()]!.interstitialTitle!)
                            .font(.title)
                            .fontWeight(.semibold)
                            .padding(EdgeInsets(top: 15, leading: 20, bottom: 0, trailing: 20))
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                        if model.pages[target.getCode()]!.interstitialNsfw {
                            Text("You must be at least eighteen years old to view this content. Are you over eighteen and willing to see adult content?")
                                .padding(EdgeInsets(top: 0, leading: 20, bottom: 10, trailing: 20))
                            HStack(spacing: 20) {
                                Button(action: {
                                    self.presentation.wrappedValue.dismiss()
                                }) {
                                    Text("No thank you")
                                        .padding()
                                        .background(Color.themeColor)
                                        .foregroundColor(.primary)
                                        .clipShape(Capsule())
                                }
                                Button(action: {
                                    model.unlockNsfw(target: target)
                                }) {
                                    Text("Continue")
                                        .padding()
                                        .background(.secondary)
                                        .clipShape(Capsule())
                                }
                            }
                        } else {
                            Button(action: {
                                self.presentation.wrappedValue.dismiss()
                            }) {
                                Text("Go back")
                                    .padding()
                                    .background(Color.themeColor)
                                    .foregroundColor(.primary)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .padding(EdgeInsets(top: 50, leading: 0, bottom: 0, trailing: 0))
                }
            } else {
                ProgressView()
                    .padding(EdgeInsets(top: 80, leading: 0, bottom: 0, trailing: 0))
                    .frame(maxHeight: .infinity, alignment: .top)
            }
        }
        .background(adViewControllerRepresentableView)
    }
}

struct CommunityCollectionView: View {
    @EnvironmentObject var model: Model
    @EnvironmentObject var overlayModel: MessageOverlayModel
    var target: CommunityOrUser? = nil
    @Binding var communityCollectionsShowing: Bool
    @State var newCollectionAlertShowing: Bool = false
    @State var deleteCollectionAlertShowing: Bool = false
    @State var removeFromCollectionAlertShowing: Bool = false
    @State var newCollectionName: String = ""
    @State var currentCollection: String = ""
    @State var currentCommunity: String = ""
    
    var body: some View {
        VStack(spacing: 5) {
            HStack {
                Image(systemName: "xmark")
                    .font(.system(size: 25))
                    .foregroundColor(Color.themeColor)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .padding(EdgeInsets(top: 5, leading: 15, bottom: 0, trailing: 0))
                    .onTapGesture {
                        communityCollectionsShowing = false
                    }
                Text("Collections")
                    .font(.system(size: 20))
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, alignment: .top)
                Spacer()
                    .frame(maxWidth: .infinity, alignment: .topTrailing)
//                Image(systemName: "paperplane.fill")
//                    .foregroundColor(Color.themeColor)
//                    .font(.system(size: 25))
//                    .frame(maxWidth: .infinity, alignment: .topTrailing)
//                    .padding(EdgeInsets(top: 5, leading: 0, bottom: 0, trailing: 15))
//                    .onTapGesture {
//
//                    }
            }
            .padding(EdgeInsets(top: 10, leading: 5, bottom: 0, trailing: 5))
            .frame(maxWidth: .infinity)
            VStack {
                if model.communityCollections.isEmpty {
                    VStack {
                        Text("Create collections to browse multiple communities in a single page.")
                            .foregroundColor(.secondary)
                            .padding(EdgeInsets(top: 10, leading: 30, bottom: 10, trailing: 30))
                        Text("Add New Collection")
                            .font(.system(size: 18))
                            .fontWeight(.semibold)
                            .padding(EdgeInsets(top: 10, leading: 30, bottom: 10, trailing: 30))
                            .foregroundColor(.white)
                            .background(Color.openRed)
                            .cornerRadius(8)
                            .padding()
                            .onTapGesture { newCollectionAlertShowing = true }
                    }
                    .frame(maxHeight: .infinity, alignment: .center)
                } else {
                    List(model.communityCollections, children: \.communities) { collection in
                        HStack {
                            Text(collection.name)
                                .lineLimit(1)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            if collection.parentCollection == nil && target != nil && !collection.containtsCommunity(target!.community!.name) {
                                Text("+ Add \(target!.community!.name)")
                                    .font(.system(size: 13))
                                    .fontWeight(.semibold)
                                    .lineLimit(1)
                                    .padding(EdgeInsets(top: 3, leading: 8, bottom: 3, trailing: 8))
                                    .foregroundColor(.white)
                                    .background(Color.openRed)
                                    .cornerRadius(4)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                                    .onTapGesture {
                                        model.userSessionManager.addToCommunityCollection(collectionName: collection.name,
                                                                                          communityName: target!.community!.name)
                                        overlayModel.show("Added to \(collection.name)")
                                    }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button {
                                if collection.communities != nil {
                                    currentCollection = collection.name
                                    deleteCollectionAlertShowing = true
                                } else {
                                    currentCollection = collection.parentCollection ?? ""
                                    currentCommunity = collection.name
                                    removeFromCollectionAlertShowing = true
                                }
                            } label: {
                                Image(systemName: "xmark")
                            }
                            .tint(Color(UIColor.systemRed))
                        }
                    }
                    VStack {
                        if target == nil {
                            Label("Swipe to remove items from the list.", systemImage: "hand.draw")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .padding(EdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10))
                        }
                        Text("Add New Collection")
                            .font(.system(size: 18))
                            .fontWeight(.semibold)
                            .padding(EdgeInsets(top: 10, leading: 30, bottom: 10, trailing: 30))
                            .foregroundColor(.white)
                            .background(Color.openRed)
                            .cornerRadius(8)
                            .padding()
                            .onTapGesture { newCollectionAlertShowing = true }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
            .alert("New Collection", isPresented: $newCollectionAlertShowing) {
                TextField("Collection name", text: $newCollectionName)
                Button("Cancel", role: .cancel) {
                    newCollectionAlertShowing = false
                }
                Button("Done", action: {
                    model.userSessionManager.createCommunityCollection(collectionName: newCollectionName)
                    newCollectionAlertShowing = false
                }).keyboardShortcut(.defaultAction)
            } message: {
                Text("Enter the name of your collection.")
            }
            .alert("Delete Collection", isPresented: $deleteCollectionAlertShowing) {
                Button("Cancel", role: .cancel) {
                    deleteCollectionAlertShowing = false
                }
                Button("Delete", role: .destructive) {
                    model.userSessionManager.deleteCommunityCollection(collectionName: currentCollection)
                    deleteCollectionAlertShowing = false
                }
            } message: {
                Text("Are you sure you want to delete \(currentCollection)?")
            }
            .alert("Remove from collection", isPresented: $removeFromCollectionAlertShowing) {
                Button("Cancel", role: .cancel) {
                    removeFromCollectionAlertShowing = false
                }
                Button("Delete", role: .destructive) {
                    model.userSessionManager.removeFromCommunityCollection(collectionName: currentCollection,
                                                                           communityName: currentCommunity)
                    removeFromCollectionAlertShowing = false
                }
            } message: {
                Text("Are you sure you want to remove \(currentCommunity) from \(currentCollection)?")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

struct PostSwipeAction: View {
    @EnvironmentObject var model: Model
    @EnvironmentObject var overlayModel: MessageOverlayModel
    var swipeAction: SwipeAction
    var post: Post
    var targetCode: String
    
    var body: some View {
        switch swipeAction {
        case .upvote:
            Button { model.toggleUpvotePost(target: targetCode, post: post) } label: {
                Image(systemName: "arrow.up")
            }
            .tint(.upvoteOrange)
        case .downvote:
            Button { model.toggleDownvotePost(target: targetCode, post: post) } label: {
                Image(systemName: "arrow.down")
            }
            .tint(.downvoteBlue)
        case .save:
            Button {
                if model.toggleSavePost(target: targetCode, post: post) {
                    overlayModel.show(post.isSaved ? "Post saved" : "Removed from saved")
                }
            } label: {
                Image(systemName: post.isSaved ? "bookmark.slash" : "bookmark")
            }
            .tint(.openRed)
        case .noAction: EmptyView()
        default: EmptyView()
        }
    }
}

struct ActionsMenu: View {
    @EnvironmentObject var model: Model
    @EnvironmentObject var overlayModel: MessageOverlayModel
    @EnvironmentObject var messageCreateModel: MessageCreateModel
    @Binding var isPostCreatorShowing: Bool
    @Binding var isMessageEditorShowing: Bool
    @Binding var communityCollectionsShowing: Bool
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
                Button(action: {
                    if model.toggleSubscribe(target: target) {
                        overlayModel.show(model.communities.contains(where: { c in c.id.lowercased() == target.id.lowercased() })
                                          ? "Subscribed to \(target.community!.name)" : "Removed \(target.community!.name) from subscriptions")
                    }
                }) {
                    if model.communities.contains(where: { c in c.id.lowercased() == target.id.lowercased() }) {
                        Label("Unsubscribe", systemImage: "heart.slash")
                    } else {
                        Label("Subscribe", systemImage: "heart")
                    }
                }
                Button(action: { communityCollectionsShowing = true }) {
                    Label("Add to Collection", systemImage: "list.dash")
                }
            } else if target.isUser {
                NavigationLink(destination: UserAboutView(user: model.pages[target.getCode()]!.selectedCommunity.user!)) {
                    Button(action: { }) {
                        Label("About user", systemImage: "person")
                    }
                }
                if model.userName != nil {
                    Button(action: {
                        isMessageEditorShowing = true
                    }) {
                        Label("Private message", systemImage: "envelope")
                    }
                }
                if model.pages[target.getCode()]!.selectedCommunity.user!.about != nil &&
                    target.user!.name.lowercased() != model.userName {
                    Button(action: {
                        if model.toggleFriend(target: target) {
                            overlayModel.show(model.pages[target.getCode()]!.selectedCommunity.user!.about!.is_friend ? "Added as friend" : "Removed from friends")
                        }
                    }) {
                        if model.pages[target.getCode()]!.selectedCommunity.user!.about!.is_friend {
                            Label("Remove from friends", systemImage: "heart.slash")
                        } else {
                            Label("Add as friend", systemImage: "heart")
                        }
                    }
                    if !model.pages[target.getCode()]!.selectedCommunity.user!.about!.is_blocked {
                        Button(action: {
                            if model.blockUser(target: target) {
                                overlayModel.show("User blocked")
                            }
                        }) {
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
    @Binding var currentSortBy: String?
    @Binding var currentSortTime: String?
    
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
        currentSortBy = sortBy
        currentSortTime = sortTime
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
    @State private var showingUnsupportedAlert = false
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color(UIColor.systemBackground))
                .ignoresSafeArea()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onAppear {
                    isFieldFocused = true
                    postCreateModel.openCreatePage(community: community)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        if postCreateModel.requiresCaptcha {
                            showingUnsupportedAlert = true
                        }
                    }
                }
                .alert("Not supported", isPresented: $showingUnsupportedAlert) {
                    Button("OK") {
                        showingUnsupportedAlert = false
                        isShowing = false
                    }.keyboardShortcut(.defaultAction)
                } message: {
                    Text("This action is not supported on your account in OpenRed.")
                }
            VStack(spacing: 5) {
                HStack {
                    Image(systemName: "xmark")
                        .font(.system(size: 25))
                        .foregroundColor(Color.themeColor)
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
                        .foregroundColor(Color.themeColor)
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
                        .tint(Color.themeColor)
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
    @State var showSafari: Bool = false
    @State var safariLink: URL?
    
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
                                Text(formatScore(score: String(community.about!.subscribers ?? 0)))
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
                        ZStack {
                            if showSafari {
                                Spacer()
                                    .fullScreenCover(isPresented: $showSafari, content: {
                                        SFSafariViewWrapper(url: safariLink!)
                                    })
                            }
                            Text(community.about!.description ?? "")
                                .font(.system(size: 18))
                                .padding(EdgeInsets(top: 8, leading: 8, bottom: 0, trailing: 8))
                                .environment(\.openURL, OpenURLAction { url in
                                    safariLink = url
                                    showSafari = true
                                    return .handled
                                })
                        }
                    } else {
                        ForEach(community.rules) { rule in
                            Text(rule.short_name)
                                .padding(EdgeInsets(top: 8, leading: 8, bottom: 0, trailing: 8))
                                .font(.system(size: 18))
                                .frame(maxWidth: .infinity, alignment: .leading)
                            ZStack {
                                if showSafari {
                                    Spacer()
                                        .fullScreenCover(isPresented: $showSafari, content: {
                                            SFSafariViewWrapper(url: safariLink!)
                                        })
                                }
                                Text(rule.description)
                                    .padding(EdgeInsets(top: 8, leading: 8, bottom: 0, trailing: 8))
                                    .font(.system(size: 16))
                                    .foregroundColor(.secondary)
                                    .environment(\.openURL, OpenURLAction { url in
                                        safariLink = url
                                        showSafari = true
                                        return .handled
                                    })
                            }
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
