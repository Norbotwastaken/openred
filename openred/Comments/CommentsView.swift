//
//  CommentsView.swift
//  openred
//
//  Created by Norbert Antal on 6/18/23.
//

import SwiftUI
import WebKit

struct CommentsViewEnclosure: View {
    @EnvironmentObject var settingsModel: SettingsModel
    @EnvironmentObject var commentsModel: CommentsModel
    @Binding var restorePostsScroll: Bool
    var link: String
    @State var scrolledCommentID: String?
    
    var body: some View {
        //        if settingsModel.swipeBack {
        //            CommentsView(restorePostsScroll: $restorePostsScroll, link: link)
        //                .lazyPop()
        //        } else {
        ZStack {
            if commentsModel.pages[link]?.post == nil {
                ProgressView()
                    .padding(EdgeInsets(top: 80, leading: 0, bottom: 0, trailing: 0))
                    .frame(maxHeight: .infinity, alignment: .top)
            }
            if commentsModel.pages[link]?.post != nil {
//                if #available(iOS 17, *) {
//                    ScrollViewReader { proxy in
//                        CommentsView(link: link, proxy: proxy, restorePostsScroll: $restorePostsScroll,
//                                     scrolledCommentID: $scrolledCommentID)
//                    }
//                    .scrollPosition(id: $scrolledCommentID)
//                } else {
                    ScrollViewReader { proxy in
                        CommentsView(link: link, proxy: proxy, restorePostsScroll: $restorePostsScroll,
                                     scrolledCommentID: $scrolledCommentID)
                    }
//                }
            }
        }
        .onAppear {
            commentsModel.loadComments(linkToThread: link)
            restorePostsScroll = false
        }
    }
}

struct CommentsView: View {
    @EnvironmentObject var model: Model
    @EnvironmentObject var commentsModel: CommentsModel
    @EnvironmentObject var overlayModel: MessageOverlayModel
    
    var link: String
    var proxy: ScrollViewProxy
    @Binding var restorePostsScroll: Bool
    @Binding var scrolledCommentID: String?
    
    @State var commentToEdit: Comment?
    @State var isEditorShowing: Bool = false
    @State var editorParentComment: Comment?
    @State var scrollTarget: String?
    
    @State var isPresented: Bool = false
    @State var isUserPresented: Bool = false
    @State var restoreScrollPlaceholder: Bool = true
    @State var newTarget: CommunityOrUser = CommunityOrUser(community: Community("")) // placeholder value
    @State var loadPosts: Bool = true
    @State var itemInView: String = ""
    @State var selectedSort: String?
    @State var showingSaveDialog = false
    @State var showingDeleteDialog = false
    @State var showingNsfwDialog = false
    @State var showingSpoilerDialog = false
    @State var restorePostsPlaceholder: Bool = false
    
    @State var destinationLink: URL?
    @State var isInternalPresented: Bool = false
    @State var internalIsPost: Bool = false
    @State var internalCommunityTarget: CommunityOrUser = CommunityOrUser(community: Community(""))
    @State var internalLoadPosts: Bool = true
    @State var internalItemInView: String = ""
    
    var body: some View {
        ZStack {
            List {
                VStack {
                    VStack {
                        HStack {
                            Text(commentsModel.pages[link]!.post!.title)
                                .font(.headline) +
                            Text(commentsModel.pages[link]!.post!.flair != nil ? "  [" + commentsModel.pages[link]!.post!.flair! + "]" : "")
                                .foregroundColor(.secondary)
                                .font(.system(size: 12))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        HStack {
                            if commentsModel.pages[link]!.post!.nsfw {
                                Text("NSFW")
                                    .foregroundColor(.white)
                                    .font(.system(size: 14 + CGFloat(model.textSizeInrease)))
                                    .fontWeight(.semibold)
                                    .padding(EdgeInsets(top: 3, leading: 4, bottom: 0, trailing: 4))
                                    .background(Color.nsfwPink)
                                    .cornerRadius(5)
                                    .frame(alignment: .leading)
                            }
                            if commentsModel.pages[link]!.post!.spoiler {
                                Text("Spoiler".uppercased())
                                    .foregroundColor(.white)
                                    .font(.system(size: 14 + CGFloat(model.textSizeInrease)))
                                    .fontWeight(.semibold)
                                    .padding(EdgeInsets(top: 3, leading: 4, bottom: 0, trailing: 4))
                                    .background(Color(UIColor.systemGray))
                                    .cornerRadius(5)
                                    .frame(alignment: .leading)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(EdgeInsets(top: 8, leading: 10, bottom: 3, trailing: 10))
                    PostRowContent(post: commentsModel.pages[link]!.post!, isPostOpen: true, enableCrosspostLink: true)
                        .padding(EdgeInsets(top: 0, leading: commentsModel.pages[link]!.post!.contentType == .text ? 10 : 0, bottom: 0, trailing: commentsModel.pages[link]!.post!.contentType == .text ? 10 : 0))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: commentsModel.pages[link]!.post!.contentType == .text ? .leading : .center)
                    VStack(spacing: 6) {
                        HStack(spacing: 3) {
                            if commentsModel.pages[link]!.post!.stickied {
                                Image(systemName: "megaphone.fill")
                                    .foregroundColor(Color(UIColor.systemGreen))
                                    .font(.system(size: 12))
                            }
                            Text("in")
                                .foregroundStyle(.secondary)
                                .frame(alignment: .leading)
                            Text(commentsModel.pages[link]!.post!.community!)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .frame(alignment: .leading)
                                .navigationDestination(isPresented: $isPresented) {
                                    PostsViewEnclosure(itemInView: $itemInView, restoreScroll: $restoreScrollPlaceholder, target: $newTarget, loadPosts: $loadPosts)
                                }
                                .onTapGesture {
                                    newTarget = CommunityOrUser(community: Community(commentsModel.pages[link]!.post!.community!), user: nil)
                                    isPresented = true
                                }
                            Text("by")
                                .foregroundStyle(.secondary)
                                .frame(alignment: .leading)
                            Text(commentsModel.pages[link]!.post!.userName!)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .frame(alignment: .leading)
                                .navigationDestination(isPresented: $isUserPresented) {
                                    PostsViewEnclosure(itemInView: $itemInView, restoreScroll: $restoreScrollPlaceholder, target: $newTarget, loadPosts: $loadPosts)
                                }
                                .onTapGesture {
                                    newTarget = CommunityOrUser(community: nil, user: User(commentsModel.pages[link]!.post!.userName!))
                                    isUserPresented = true
                                }
                            
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 5))
                        HStack {
                            HStack(spacing: 3) {
                                Image(systemName: "arrow.up")
                                Text(formatScore(score: commentsModel.pages[link]!.post!.score))
                            }
                            HStack(spacing: 3) {
                                Image(systemName: "face.smiling.inverse")
                                Text("\(Int(round(commentsModel.pages[link]!.post!.upvoteRatio * 100)))%")
                            }
                            HStack(spacing: 3) {
                                Image(systemName: "text.bubble")
                                Text(formatScore(score: commentsModel.pages[link]!.post!.commentCount))
                            }
                            HStack(spacing: 3) {
                                Image(systemName: "clock")
                                Text(commentsModel.pages[link]!.post!.displayAge)
                            }
                            HStack(spacing: 3) {
                                ForEach(commentsModel.pages[link]!.post!.awardLinks.indices) { i in
                                    if i < 5 {
                                        AsyncImage(url: URL(string: commentsModel.pages[link]!.post!.awardLinks[i])) { image in
                                            image.image?
                                                .resizable()
                                                .scaledToFill()
                                                .frame(maxWidth: 15, maxHeight: 15)
                                        }
                                    }
                                }
                                if commentsModel.pages[link]!.post!.awardCount > 1 {
                                    Text(String(commentsModel.pages[link]!.post!.awardCount))
                                }
                            }
                        }
                        .foregroundStyle(.secondary)
                        .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 5))
                        .frame(maxWidth: .infinity, maxHeight: 15, alignment: .leading)
                    }
                    .font(.system(size: 14))
                    .padding(EdgeInsets(top: 8, leading: 0, bottom:  8, trailing: 0))
                    Divider()
                    HStack {
                        Image(systemName: "arrow.up")
                            .foregroundColor(commentsModel.pages[link]!.post!.isUpvoted ? .upvoteOrange : Color.secondary)
                            .fontWeight(commentsModel.pages[link]!.post!.isUpvoted ? .semibold : .regular)
                            .onTapGesture {
                                if commentsModel.toggleUpvotePost(link: link, post: commentsModel.pages[link]!.post!) == false {
                                    // show login popup
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                        Image(systemName: "arrow.down")
                            .fontWeight(commentsModel.pages[link]!.post!.isDownvoted ? .semibold : .regular)
                            .foregroundColor(commentsModel.pages[link]!.post!.isDownvoted ? .downvoteBlue : Color.secondary)
                            .onTapGesture {
                                if commentsModel.toggleDownvotePost(link: link, post: commentsModel.pages[link]!.post!) == false {
                                    // show login popup
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                        Image(systemName: commentsModel.pages[link]!.post!.isSaved ? "bookmark.slash" : "bookmark")
                        //                            Image(systemName: "bookmark")
                        //                                .fontWeight(post.isSaved ? .semibold : .regular)
                        //                                .foregroundColor(.secondary)
                            .onTapGesture {
                                if commentsModel.toggleSavePost(link: link, post: commentsModel.pages[link]!.post!) {
                                    overlayModel.show(commentsModel.pages[link]!.post!.isSaved ? "Post saved" : "Removed from saved")
                                    // show login popup
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                        Image(systemName: "arrow.uturn.left")
                            .onTapGesture {
                                if model.userName != nil {
                                    editorParentComment = nil
                                    isEditorShowing = true
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                    .font(.system(size: 28))
                    .foregroundColor(Color.secondary)
                    Divider()
                }
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                ForEach(commentsModel.pages[link]!.flatCommentsList) { comment in
                    if !commentsModel.pages[link]!.anyParentsCollapsed(comment: comment) {
                        CommentView(comment: comment, postLink: link, editorParentComment: $editorParentComment,
                                    commentToEdit: $commentToEdit, isEditorShowing: $isEditorShowing, scrollTarget: $scrollTarget,
                                    destinationLink: $destinationLink, isInternalPresented: $isInternalPresented, internalIsPost: $internalIsPost,
                                    internalCommunityTarget: $internalCommunityTarget,
                                    internalLoadPosts: $internalLoadPosts, internalItemInView: $internalItemInView, spoilerBlurActive: comment.spoiler)
                        //                            .onAppear {
                        //                                commentInView = comment.id
                        //                            }
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                        .padding(EdgeInsets(top: 8, leading: 0, bottom: 12, trailing: 0))
                    }
                }
            }
            .listStyle(PlainListStyle())
            //                    .navigationTitle(commentsModel.pages[link]!.post!.commentCount + " comments")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(isEditorShowing)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack {
                        Text(commentsModel.pages[link]!.post!.commentCount + " comments")
                            .font(.headline)
                        Text(commentsModel.pages[link]!.selectedSortingDisplayLabel)
                            .font(.subheadline)
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    CommentsToolbarView(link: link, selectedSort: $selectedSort, showingSaveDialog: $showingSaveDialog, showingDeleteDialog: $showingDeleteDialog,
                                        showingNsfwDialog: $showingNsfwDialog, showingSpoilerDialog: $showingSpoilerDialog)
                }
            }
            .onChange(of: scrollTarget) { target in
                if let target = target {
                    scrollTarget = nil
                    proxy.scrollTo(target, anchor: .top)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        proxy.scrollTo(target, anchor: .top)
                    }
                }
            }
            .refreshable {
                commentsModel.loadComments(linkToThread: link, sortBy: selectedSort, forceLoad: true)
            }
            .navigationDestination(isPresented: $isInternalPresented) {
                if !internalIsPost { // internal is community
                    PostsViewEnclosure(itemInView: $internalItemInView, restoreScroll: $restorePostsPlaceholder,
                                       target: $internalCommunityTarget, loadPosts: $internalLoadPosts)
                } else {
                    CommentsViewEnclosure(restorePostsScroll: $restorePostsPlaceholder, link: destinationLink!.path)
                }
            }
            //                .onAppear(perform: {
            //                    proxy.scrollTo(commentInView)
            //                })
//            if #available(iOS 17, *) {
//                ZStack {
//                    Circle()
//                        .fill(Color.themeColor)
//                        .frame(width: 40, height: 40, alignment: .bottomTrailing)
//                        .onTapGesture {
//                            if let index = (commentsModel.pages[link]!.comments.firstIndex(where: { $0.id == scrolledCommentID })) {
//                                if index + 1 < commentsModel.pages[link]!.comments.count {
//                                    scrolledCommentID = commentsModel.pages[link]!.comments[index + 1].id
//                                }
//                            }
//                        }
//                    Image(systemName: "chevron.down")
//                        .font(.system(size: 20))
//                        .foregroundColor(.white)
//                }
//                .padding(EdgeInsets(top: 0, leading: 0, bottom: 30, trailing: 30))
//                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
//            }
        }
        if isEditorShowing {
            CommentEditor(commentToEdit: $commentToEdit, isShowing: $isEditorShowing, parentComment: $editorParentComment, postLink: link)
        }
    }
    
}

struct CommentView: View {
    @EnvironmentObject var commentsModel: CommentsModel
    @EnvironmentObject var popupViewModel: PopupViewModel
    @EnvironmentObject var overlayModel: MessageOverlayModel
    @EnvironmentObject var settingsModel: SettingsModel
    @ObservedObject var comment: Comment
    var postLink: String
    @Binding var editorParentComment: Comment?
    @Binding var commentToEdit: Comment?
    @Binding var isEditorShowing: Bool
    @Binding var scrollTarget: String?
    
    @Binding var destinationLink: URL?
    @Binding var isInternalPresented: Bool
    @Binding var internalIsPost: Bool
    @Binding var internalCommunityTarget: CommunityOrUser
    @Binding var internalLoadPosts: Bool
    @Binding var internalItemInView: String
    
    @State var showSafari: Bool = false
    @State private var showingDeleteAlert = false
    @State var spoilerBlurActive: Bool = false
    
    var body: some View {
        VStack {
//            Divider()
            HStack(spacing: 6) {
//            HStack() {
                if comment.depth > 0 && !comment.isCollapsed {
                    Rectangle()
                        .frame(maxWidth: 2, maxHeight: .infinity, alignment: .leading)
                        .padding(EdgeInsets(top: 20, leading: 0, bottom: 0, trailing: 0))
                        .foregroundColor(Themes.themes[commentsModel.commentTheme]!.colors[comment.depth - 1])
                        .opacity(0.8)
                }
                VStack {
                    HStack(spacing: 5) {
                        Text(comment.user ?? "deleted")
                            .lineLimit(1)
                            .padding(EdgeInsets(top: 2, leading: 4, bottom: 2, trailing: 4))
                            .foregroundColor(comment.isOP ? .white : .secondary)
                            .background(comment.isOP ? Color(UIColor.systemBlue) : .clear)
                            .cornerRadius(5)
                        //                        if comment.score != nil {
                        HStack(spacing: 2) {
                            Image(systemName: "arrow.up")
                                .foregroundColor(comment.isUpvoted ? .upvoteOrange : comment.isDownvoted ? .downvoteBlue : .secondary)
                            Text(String(comment.score))
//                            if comment.age != nil {
//                                Image(systemName: "clock").foregroundColor(.secondary)
//                                Text(String(comment.age!))
//                            }
                        }
                        if comment.isMod {
                            Text("MOD")
                                .lineLimit(1)
                                .foregroundColor(Color(UIColor.systemGreen))
                                .font(.system(size: 12))
                                .fontWeight(.semibold)
                        }
                        if comment.flair != nil && comment.flair! != "" {
                            Text(comment.flair!)
                                .lineLimit(1)
                                .foregroundColor(.secondary)
                                .font(.system(size: 12))
                                .padding(EdgeInsets(top: 2, leading: 4, bottom: 2, trailing: 4))
                                .background(Color(UIColor.systemGray6))
                                .cornerRadius(5)
                        }
                        //                        }
//                        CommentActionsMenu(comment: comment)
                        Spacer()
                        if comment.stickied {
                            Image(systemName: "pin.fill")
                                .foregroundColor(Color(UIColor.systemGreen))
                                .font(.system(size: 12))
                        }
                        Menu {
                            CommentActions(comment: comment, editorParentComment: $editorParentComment, commentToEdit: $commentToEdit,
                                           isEditorShowing: $isEditorShowing, showingDeleteAlert: $showingDeleteAlert, postLink: postLink)
                        } label: {
                            ZStack {
                                Spacer()
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                Image(systemName: "ellipsis")
                            }
                            .frame(width: 20, height: 15)
                        }
                        .frame(alignment: .trailing)
                        .onTapGesture {
                            // catch tap
                        }
                        if comment.age != nil {
                            Image(systemName: "clock").foregroundColor(.secondary)
                                .frame(alignment: .trailing)
                            Text(String(comment.age!))
                                .frame(alignment: .trailing)
                        }
                    }
                    .foregroundColor(.secondary)
                    .font(.system(size: 14))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    if !comment.isCollapsed {
                        ZStack {
                            if showSafari {
                                Spacer()
                                    .fullScreenCover(isPresented: $showSafari, content: {
                                        SFSafariViewWrapper(url: destinationLink!)
                                    })
                            }
                            ZStack {
                                VStack {
                                    Text(comment.content ?? "")
                                        .tint(Color(UIColor.systemBlue))
                                        .fixedSize(horizontal: false, vertical: true)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .font(.system(size: 15 + CGFloat(commentsModel.textSizeInrease)))
                                        .environment(\.openURL, OpenURLAction { url in
                                            if url.isImage {
                                                popupViewModel.fullImageLink = String(htmlEncodedString: url.absoluteString)
                                                popupViewModel.contentType = .image
                                                popupViewModel.isShowing = true
                                            } else if url.isGif {
                                                popupViewModel.videoLink = String(htmlEncodedString: url.absoluteString)
                                                popupViewModel.contentType = .gif
                                                popupViewModel.isShowing = true
                                            } else if url.isPost {
                                                internalIsPost = true
                                                destinationLink = url
                                                isInternalPresented = true
                                            } else if url.isCommunity {
                                                internalCommunityTarget = CommunityOrUser(explicitURL: url)
                                                internalIsPost = false
                                                isInternalPresented = true
                                            } else {
                                                destinationLink = url
                                                if ["http", "https"].contains(url.scheme?.lowercased() ?? "") {
                                                    showSafari = true
                                                }
                                            }
                                            return .handled
                                        })
                                    if comment.media_metadata != nil {
                                        CommentGifView(comment: comment)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                }
                                .blur(radius: spoilerBlurActive ? 8 : 0)
                                if spoilerBlurActive {
                                    Text("SHOW SPOILER")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white)
                                        .fontWeight(.semibold)
                                        .opacity(0.8)
                                        .padding(EdgeInsets(top: 7, leading: 9, bottom: 7, trailing: 9))
                                        .background(Color(UIColor.systemGray).opacity(0.8))
                                        .cornerRadius(5)
                                        .onTapGesture {
                                            spoilerBlurActive = false
                                        }
                                }
                            }
                        }
                    }
                }
            }
            .background(Color(UIColor.systemBackground))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding(EdgeInsets(top: 0, leading: indentSize, bottom: 0, trailing: 10))
            .onTapGesture {
                commentsModel.collapseComment(link: postLink, comment: comment)
                scrollTarget = comment.id
            }
            .contextMenu{ CommentActions(comment: comment, editorParentComment: $editorParentComment, commentToEdit: $commentToEdit,
                                         isEditorShowing: $isEditorShowing, showingDeleteAlert: $showingDeleteAlert, postLink: postLink) }
            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                CommentSwipeAction(swipeAction: settingsModel.commentLeftPrimary, comment: comment, postLink: postLink, scrollTarget: $scrollTarget,
                                   editorParentComment: $editorParentComment, commentToEdit: $commentToEdit, isEditorShowing: $isEditorShowing)
                CommentSwipeAction(swipeAction: settingsModel.commentLeftSecondary, comment: comment, postLink: postLink, scrollTarget: $scrollTarget,
                                   editorParentComment: $editorParentComment, commentToEdit: $commentToEdit, isEditorShowing: $isEditorShowing)
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                CommentSwipeAction(swipeAction: settingsModel.commentRightPrimary, comment: comment, postLink: postLink, scrollTarget: $scrollTarget,
                                   editorParentComment: $editorParentComment, commentToEdit: $commentToEdit, isEditorShowing: $isEditorShowing)
                CommentSwipeAction(swipeAction: settingsModel.commentRightSecondary, comment: comment, postLink: postLink, scrollTarget: $scrollTarget,
                                   editorParentComment: $editorParentComment, commentToEdit: $commentToEdit, isEditorShowing: $isEditorShowing)
            }
        }
        .alert("Delete comment", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { showingDeleteAlert = false }
            Button("Delete", role: .destructive) {
                commentsModel.deleteComment(link: postLink, comment: comment)
                overlayModel.show("Comment successfully deleted")
                showingDeleteAlert = false
            }
        } message: {
            Text("Are you sure you want to delete this comment?")
        }
    }
    
    var indentSize: CGFloat {
        var indent = 5 * (CGFloat(integerLiteral: comment.depth) + 1)
        if comment.isCollapsed && comment.depth > 0 {
            indent = indent + 8.5
        }
        return indent
    }
}

struct CommentSwipeAction: View {
    @EnvironmentObject var commentsModel: CommentsModel
    var swipeAction: SwipeAction
    var comment: Comment
    var postLink: String
    @Binding var scrollTarget: String?
    @Binding var editorParentComment: Comment?
    @Binding var commentToEdit: Comment?
    @Binding var isEditorShowing: Bool
    
    var body: some View {
        switch swipeAction {
        case .upvote:
            Button { commentsModel.toggleUpvoteComment(link: postLink, comment: comment) } label: {
                Image(systemName: "arrow.up")
            }
            .tint(.upvoteOrange)
        case .downvote:
            Button { commentsModel.toggleDownvoteComment(link: postLink, comment: comment) } label: {
                Image(systemName: "arrow.down")
            }
            .tint(.downvoteBlue)
        case .save:
            Button { commentsModel.toggleSaveComment(link: postLink, comment: comment) } label: {
                Image(systemName: comment.isSaved ? "bookmark.slash" : "bookmark")
            }
            .tint(.openRed)
        case .reply:
            Button {
                editorParentComment = comment
                commentToEdit = nil
                isEditorShowing = true
            } label: {
                Image(systemName: "arrow.uturn.left")
            }
            .tint(Color(red: 12/255, green: 154/255, blue: 242/255))
        case .collapse:
            Button {
                scrollTarget = commentsModel.collapseCommentThread(link: postLink, comment: comment)
            } label: {
                Image(systemName: "arrow.up.to.line")
            }
            .tint(Color(UIColor.systemBlue))
        case .noAction: EmptyView()
        default: EmptyView()
        }
    }
}

struct CommentGifView: View {
    var comment: Comment
    @EnvironmentObject var popupViewModel: PopupViewModel
    
    var body: some View {
        ForEach(Array(comment.media_metadata!.elements.keys
            .filter{ comment.media_metadata!.elements[$0]!.e?.lowercased() == "animatedimage" }
            .filter{ !comment.media_metadata!.elements[$0]!.p.isEmpty }
        ), id: \.self) { key in
            ZStack {
                Rectangle()
                    .fill(Color(UIColor.systemGray6))
                    .cornerRadius(10)
                HStack {
                    AsyncImage(url: URL(string: comment.media_metadata!.elements[key]!.p[0].u ?? "")) { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .roundedCorner(10, corners: [.topLeft, .bottomLeft])
                            .frame(maxWidth: 60, maxHeight: 60, alignment: .leading)
                        //                            .blur(radius: post.nsfw ? 20 : 0, opaque: true)
                            .clipped()
                    } placeholder: {
                        ZStack {
                            Rectangle()
                                .fill(Color(UIColor.systemGray5))
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .roundedCorner(10, corners: [.topLeft, .bottomLeft])
                            Image(systemName: "safari")
                                .font(.system(size: 30))
                                .foregroundColor(Color.white)
                                .opacity(0.8)
                        }
                        .frame(maxWidth: 60, maxHeight: 60, alignment: .leading)
                    }
                    VStack(spacing: 5) {
                        Text("Open GIF")
                            .font(.system(size: 16))
                            .foregroundStyle(.secondary)
                            .fontWeight(.semibold)
                            .padding(SwiftUI.EdgeInsets(top: 5, leading: 0, bottom: 0, trailing: 0))
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                        Text(comment.media_metadata!.elements[key]!.ext ?? "")
                            .lineLimit(1)
                            .font(.system(size: 13))
                            .fontWeight(.thin)
                            .fixedSize(horizontal: false, vertical: false)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                            .padding(SwiftUI.EdgeInsets(top: 0, leading: 0, bottom: 5, trailing: 0))
                    }
                    .frame(maxWidth: .infinity, maxHeight: 60, alignment: .topLeading)
                }
                .frame(maxWidth: .infinity, maxHeight: 60, alignment: .leading)
            }
//            .padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
            .onTapGesture {
                if let videoLink = comment.media_metadata!.elements[key]!.s {
                    popupViewModel.videoLink = String(htmlEncodedString: videoLink.gif ?? "")
                    popupViewModel.contentType = .gif
                    popupViewModel.isShowing = true
                }
            }
        }
    }
}

struct CommentActions: View {
    @EnvironmentObject var commentsModel: CommentsModel
    @EnvironmentObject var model: Model
    @EnvironmentObject var overlayModel: MessageOverlayModel
    @ObservedObject var comment: Comment
    @Binding var editorParentComment: Comment?
    @Binding var commentToEdit: Comment?
    @Binding var isEditorShowing: Bool
    @Binding var showingDeleteAlert: Bool
    var postLink: String
    
    @State var restoreScrollPlaceholder: Bool = true
    @State var newTarget: CommunityOrUser = CommunityOrUser(community: Community(""))
    @State var loadPosts: Bool = true
    @State var itemInView: String = ""
    
    var body: some View {
        Group {
            Button(action: { commentsModel.toggleUpvoteComment(link: postLink, comment: comment) }) {
                Label("Upvote", systemImage: "arrow.up")
            }
            Button(action: { commentsModel.toggleDownvoteComment(link: postLink, comment: comment) }) {
                Label("Downvote", systemImage: "arrow.down")
            }
            Button(action: {
                if commentsModel.toggleSaveComment(link: postLink, comment: comment) {
                    overlayModel.show(comment.isSaved ? "Comment saved" : "Removed from saved")
                }
            }) {
                Label(comment.isSaved ? "Undo Save" : "Save", systemImage: comment.isSaved ? "bookmark.slash" : "bookmark")
            }
            Button(action: {
                editorParentComment = comment
                commentToEdit = nil
                isEditorShowing = true
            }) {
                Label("Reply", systemImage: "arrow.uturn.left")
            }
            if comment.user != nil {
                NavigationLink(destination: PostsViewEnclosure(itemInView: $itemInView, restoreScroll: $restoreScrollPlaceholder, target: $newTarget, loadPosts: $loadPosts)) {
                    Button(action: {}) {
                        Label("User Profile", systemImage: "person")
                    }
                }
            }
            Button(action: {
                UIPasteboard.general.string = String(comment.content!.characters[...])
                overlayModel.show("Copied to clipboard", loading: false)
            }) {
                Label("Copy text", systemImage: "list.clipboard")
            }
            if comment.user?.lowercased() == model.userName?.lowercased() {
                Button(action: {
                    editorParentComment = nil
                    commentToEdit = comment
                    isEditorShowing = true
                }) {
                    Label("Edit comment", systemImage: "pencil.line")
                }
                Button(role: .destructive, action: { showingDeleteAlert = true }, label: {
                    Label("Delete comment", systemImage: "trash")
                })
            }
        }
        .onAppear { newTarget = CommunityOrUser(community: nil, user: User(comment.user!)) }
    }
}

struct CommentSortMenu: View {
    @EnvironmentObject var commentsModel: CommentsModel
    @Binding var selectedSort: String?
    var postLink: String
    
    var body: some View {
        Menu {
            Button(action: {sortCommunity(sortModifier: "confidence")}) {
                Label("Hot", systemImage: CommentsModelAttributes.sortModifierIcons[""]!)
            }
            Button(action: {sortCommunity(sortModifier: "top")}) {
                Label("Top", systemImage: CommentsModelAttributes.sortModifierIcons["top"]!)
            }
            Button(action: {sortCommunity(sortModifier: "new" )}) {
                Label("New", systemImage: CommentsModelAttributes.sortModifierIcons["new"]!)
            }
            Button(action: {sortCommunity(sortModifier: "controversial" )}) {
                Label("Controversial", systemImage: CommentsModelAttributes.sortModifierIcons["controversial"]!)
            }
            Button(action: {sortCommunity(sortModifier: "old" )}) {
                Label("Old", systemImage: CommentsModelAttributes.sortModifierIcons["old"]!)
            }
            Button(action: {sortCommunity(sortModifier: "qa" )}) {
                Label("Q&A", systemImage: CommentsModelAttributes.sortModifierIcons["qa"]!)
            }
        } label: {
            Label("Sort by", systemImage: commentsModel.selectedSortingIcon(link: postLink))
        }
    }
    
    func sortCommunity(sortModifier: String) {
        selectedSort = sortModifier
        commentsModel.loadComments(linkToThread: postLink, sortBy: sortModifier)
    }
}

struct CommentEditor: View {
    @EnvironmentObject var commentsModel: CommentsModel
    @Binding var commentToEdit: Comment?
    @Binding var isShowing: Bool
    @Binding var parentComment: Comment?
    var postLink: String
    @State private var content: String = ""
    @FocusState private var isFieldFocused: Bool
    @State private var loading: Bool = false
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color(UIColor.systemBackground))
                .ignoresSafeArea()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onAppear { isFieldFocused = true }
            VStack(spacing: 30) {
                HStack {
                    Image(systemName: "xmark")
                        .font(.system(size: 25))
                        .foregroundColor(Color.themeColor)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .padding(EdgeInsets(top: 5, leading: 15, bottom: 0, trailing: 0))
                        .onTapGesture {
                            isShowing = false
                        }
                    Text("Reply")
                        .font(.system(size: 20))
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity, alignment: .top)
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(Color.themeColor)
                        .font(.system(size: 25))
                        .frame(maxWidth: .infinity, alignment: .topTrailing)
                        .padding(EdgeInsets(top: 5, leading: 0, bottom: 0, trailing: 15))
                        .onTapGesture {
                            if content != "" {
                                if commentToEdit != nil {
                                    commentsModel.editComment(link: postLink, comment: commentToEdit!, content: content)
                                } else {
                                    commentsModel.sendReply(link: postLink, parent: parentComment, content: content)
                                }
                                loading = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                    isShowing = false
                                }
                            }
                        }
                }
                .frame(maxWidth: .infinity)
                VStack {
                    if parentComment != nil {
                        ScrollView {
                            Group {
                                Text(parentComment!.user!).bold() +
                                Text("\n" + parentComment!.content!)
                            }
                            .font(.system(size: 15))
                            .padding(EdgeInsets(top: 6, leading: 6, bottom: 6, trailing: 6))
                            .foregroundStyle(.opacity(0.8))
                            .background(Color(UIColor.systemGray5))
                            .cornerRadius(10)
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                        }
                        .frame(maxWidth: .infinity, maxHeight: 200, alignment: .topLeading)
                    }
                    TextField("Add a comment", text: $content, axis: .vertical)
                    //                .textFieldStyle(.roundedBorder)
                        .focused($isFieldFocused)
                        .padding(EdgeInsets(top: 20, leading: 0, bottom: 0, trailing: 0))
                        .frame(maxHeight: .infinity, alignment: .topLeading)
                    
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            if loading {
                Rectangle()
                    .fill(.black)
                    .opacity(0.6)
                    .ignoresSafeArea()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                ProgressView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear() {
            if commentToEdit != nil {
                content = commentToEdit!.rawContent ?? ""
            }
        }
    }
}

struct CommentActionsMenu: View {
    @EnvironmentObject var commentsModel: CommentsModel
    @EnvironmentObject var overlayModel: MessageOverlayModel
    @Binding var showingSaveDialog: Bool
    @Binding var showingDeleteDialog: Bool
    @Binding var showingNsfwDialog: Bool
    @Binding var showingSpoilerDialog: Bool
    var link: String
    
    var body: some View {
        if commentsModel.pages[link]?.post != nil {
            Menu {
                ShareLink(item: URL(string: "https://reddit.com\(link.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)!)")!) {
                    Label("Share post", systemImage: "square.and.arrow.up")
                }
                if commentsModel.pages[link]!.post!.contentType == .image {
                    ShareLink(item: URL(string: commentsModel.pages[link]!.post!.imageLink!)!) {
                        Label("Share image", systemImage: "square.and.arrow.up.circle")
                    }
                    Button(action: { showingSaveDialog = true }) {
                        Label("Download image", systemImage: "arrow.down.square")
                    }
                } else if commentsModel.pages[link]!.post!.contentType == .text {
                    Button(action: {
                        UIPasteboard.general.string = String(commentsModel.pages[link]!.post!.text!.characters[...])
                        overlayModel.show("Copied to clipboard")
                    }) {
                        Label("Copy text", systemImage: "list.clipboard")
                    }
                } else if commentsModel.pages[link]!.post!.contentType == .gallery {
                    Button(action: { showingSaveDialog = true }) {
                        Label("Download image", systemImage: "arrow.down.square")
                    }
                } else if commentsModel.pages[link]!.post!.contentType == .link
                            && commentsModel.pages[link]!.post!.externalLink != "" {
                    ShareLink(item: URL(string: commentsModel.pages[link]!.post!.externalLink!)!) {
                        Label("Share link", systemImage: "square.and.arrow.up.circle")
                    }
                    Button(action: {
                        UIPasteboard.general.string = commentsModel.pages[link]!.post!.externalLink!
                        overlayModel.show("Copied to clipboard")
                    }) {
                        Label("Copy link", systemImage: "list.clipboard")
                    }
                }
                if commentsModel.pages[link]!.post!.userName == commentsModel.userSessionManager.userName {
                    Button(action: { showingNsfwDialog = true }) {
                        Label(commentsModel.pages[link]!.post!.nsfw ? "Remove NSFW mark" : "Mark as NSFW", systemImage: "18.circle")
                    }
                    Button(action: { showingSpoilerDialog = true }) {
                        Label(commentsModel.pages[link]!.post!.spoiler ? "Remove spoiler mark" : "Mark as spoiler", systemImage: "car.side.rear.open")
                    }
                    Button(role: .destructive, action: { showingDeleteDialog = true }, label: {
                        Label("Delete post", systemImage: "trash")
                    })
                }
            } label: {
                Label("Actions", systemImage: "ellipsis")
            }
        }
    }
}

struct CommentsToolbarView: View {
    @EnvironmentObject var commentsModel: CommentsModel
    @EnvironmentObject var overlayModel: MessageOverlayModel
    var link: String
    @Binding var selectedSort: String?
    @Binding var showingSaveDialog: Bool
    @Binding var showingDeleteDialog: Bool
    @Binding var showingNsfwDialog: Bool
    @Binding var showingSpoilerDialog: Bool
    
    var body: some View {
        if commentsModel.pages[link]?.post != nil {
            HStack {
                CommentSortMenu(selectedSort: $selectedSort, postLink: link)
                CommentActionsMenu(showingSaveDialog: $showingSaveDialog,
                                   showingDeleteDialog: $showingDeleteDialog, showingNsfwDialog: $showingNsfwDialog,
                                   showingSpoilerDialog: $showingSpoilerDialog, link: link)
            }
            .alert("Save image to library?", isPresented: $showingSaveDialog) {
                if commentsModel.pages[link]!.post!.contentType == .image {
                    SaveImageAlert(showingSaveDialog: $showingSaveDialog, link: commentsModel.pages[link]!.post!.imageLink)
                } else if commentsModel.pages[link]!.post!.contentType == .gallery {
                    SaveImageAlert(showingSaveDialog: $showingSaveDialog, link: commentsModel.pages[link]!.post!.gallery!.items[0].fullLink,
                                   links: commentsModel.pages[link]!.post!.gallery!.items.map{ $0.fullLink })
                }
            }
            .alert("Delete post?", isPresented: $showingDeleteDialog) {
                Button("Cancel", role: .cancel) { showingDeleteDialog = false }
                Button("Delete", role: .destructive) {
                    if commentsModel.deletePost(link: link) {
                        overlayModel.show("Post successfully deleted")
                    }
                    showingDeleteDialog = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        commentsModel.loadComments(linkToThread: link, sortBy: selectedSort, forceLoad: true)
                    }
                }
            } message: {
                Text("Are you sure you want to delete your post?")
            }
            .alert(commentsModel.pages[link]!.post!.nsfw ? "Remove NSFW mark" : "Mark post as NSFW", isPresented: $showingNsfwDialog) {
                Button("Cancel", role: .cancel) { showingNsfwDialog = false }
                Button("Continue") {
                    if commentsModel.togglePostNsfw(link: link) {
                        overlayModel.show("Post updated")
                    }
                    showingNsfwDialog = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        commentsModel.loadComments(linkToThread: link, sortBy: selectedSort, forceLoad: true)
                    }
                }.keyboardShortcut(.defaultAction)
            } message: {
                Text(commentsModel.pages[link]!.post!.nsfw ? "Are you sure you want to mark your post as safe for work?"
                     : "Are you sure you want to mark your post as NSFW?")
            }
            .alert(commentsModel.pages[link]!.post!.spoiler ? "Remove spoiler mark" : "Mark post as spoiler", isPresented: $showingSpoilerDialog) {
                Button("Cancel", role: .cancel) { showingSpoilerDialog = false }
                Button("Continue") {
                    if commentsModel.togglePostSpoiler(link: link) {
                        overlayModel.show("Post updated")
                    }
                    showingSpoilerDialog = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        commentsModel.loadComments(linkToThread: link, sortBy: selectedSort, forceLoad: true)
                    }
                }.keyboardShortcut(.defaultAction)
            } message: {
                Text(commentsModel.pages[link]!.post!.spoiler ? "Are you sure you want to mark your post as spoiler free?"
                     : "Are you sure you want to mark your post for spoilers?")
            }
        }
    }
}
