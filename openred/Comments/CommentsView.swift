//
//  CommentsView.swift
//  openred
//
//  Created by Norbert Antal on 6/18/23.
//

import SwiftUI
import WebKit

struct CommentsView: View {
    @EnvironmentObject var model: Model
    @EnvironmentObject var commentsModel: CommentsModel
    @EnvironmentObject var overlayModel: MessageOverlayModel
    @Environment(\.dismiss) var dismiss
//    @EnvironmentObject var popupViewModel: PopupViewModel
//    @ObservedObject var post: Post
//    @Binding var commentInView: String
    @Binding var restorePostsScroll: Bool
//    @Binding var postsTarget: CommunityOrUser
    var link: String
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
    @State var crosspostRestorePostsPlaceholder: Bool = false
    
    var body: some View {
        ZStack {
            if commentsModel.pages[link]?.post == nil {
                ProgressView()
                    .padding(EdgeInsets(top: 80, leading: 0, bottom: 0, trailing: 0))
                    .frame(maxHeight: .infinity, alignment: .top)
            }
            if commentsModel.pages[link]?.post != nil {
                ScrollViewReader { proxy in
                    List {
                        VStack {
                            VStack {
                                Text(commentsModel.pages[link]!.post!.title)
                                    .font(.headline) +
                                Text(commentsModel.pages[link]!.post!.flair != nil ? "  [" + commentsModel.pages[link]!.post!.flair! + "]" : "")
                                    .foregroundColor(.secondary)
                                    .font(.system(size: 12))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(EdgeInsets(top: 8, leading: 10, bottom: 0, trailing: 10))
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
                                            PostsView(itemInView: $itemInView, restoreScroll: $restoreScrollPlaceholder, target: $newTarget, loadPosts: $loadPosts)
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
                                            PostsView(itemInView: $itemInView, restoreScroll: $restoreScrollPlaceholder, target: $newTarget, loadPosts: $loadPosts)
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
                                    .foregroundColor(commentsModel.pages[link]!.post!.isUpvoted ? .upvoteOrange : Color(UIColor.systemBlue))
                                    .fontWeight(commentsModel.pages[link]!.post!.isUpvoted ? .semibold : .regular)
                                    .onTapGesture {
                                        if commentsModel.toggleUpvotePost(link: link, post: commentsModel.pages[link]!.post!) == false {
                                            // show login popup
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .center)
                                Image(systemName: "arrow.down")
                                    .fontWeight(commentsModel.pages[link]!.post!.isDownvoted ? .semibold : .regular)
                                    .foregroundColor(commentsModel.pages[link]!.post!.isDownvoted ? .downvoteBlue : Color(UIColor.systemBlue))
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
                                //                                .foregroundColor(.secondary)
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
                            .foregroundColor(Color(UIColor.systemBlue))
                            //                        .listRowSeparator(.hidden)
                            Divider()
                        }
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                        .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                        ForEach(commentsModel.pages[link]!.flatCommentsList) { comment in
                            if !commentsModel.pages[link]!.anyParentsCollapsed(comment: comment) {
                                CommentView(comment: comment, postLink: link, editorParentComment: $editorParentComment,
                                            isEditorShowing: $isEditorShowing, scrollTarget: $scrollTarget)
                                //                            .onAppear {
                                //                                commentInView = comment.id
                                //                            }
                                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                                    .padding(EdgeInsets(top: 8, leading: 0, bottom: 12, trailing: 0))
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                    .navigationTitle(commentsModel.pages[link]!.post!.commentCount + " comments")
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationBarHidden(isEditorShowing)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
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
                            .alert(commentsModel.pages[link]!.post!.nsfw ? "Remove NSFW mark?" : "Mark post as NSFW?", isPresented: $showingNsfwDialog) {
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
                            .alert(commentsModel.pages[link]!.post!.spoiler ? "Remove spoiler mark?" : "Mark post as spoiler?", isPresented: $showingSpoilerDialog) {
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
                    //                .onAppear(perform: {
                    //                    proxy.scrollTo(commentInView)
                    //                })
                }
                if isEditorShowing {
                    CommentEditor(isShowing: $isEditorShowing, parentComment: $editorParentComment, postLink: link)
                }
            }
        }
        .onAppear {
            commentsModel.loadComments(linkToThread: link)
            restorePostsScroll = false
        }
    }
}

struct CommentView: View {
    @EnvironmentObject var commentsModel: CommentsModel
    @EnvironmentObject var popupViewModel: PopupViewModel
    @ObservedObject var comment: Comment
    var postLink: String
    @Binding var editorParentComment: Comment?
    @Binding var isEditorShowing: Bool
    @Binding var scrollTarget: String?
    @State var showSafari: Bool = false
    @State var safariLink: URL?
    @State var isInternalPresented: Bool = false
    @State var internalIsPost: Bool = false
//    @State var internalPostTarget:
    
    @State var internalRestoreScrollPlaceholder: Bool = true
    @State var internalCommunityTarget: CommunityOrUser = CommunityOrUser(community: Community(""))
    @State var internalLoadPosts: Bool = true
    @State var internalItemInView: String = ""
    @State private var showingDeleteAlert = false
    
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
                            CommentActions(comment: comment, editorParentComment: $editorParentComment,
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
                                        SFSafariViewWrapper(url: safariLink!)
                                    })
                            }
                            VStack {
                                Text(comment.content ?? "")
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
                                            safariLink = url
                                            isInternalPresented = true
                                        } else if url.isCommunity {
                                            internalCommunityTarget = CommunityOrUser(explicitURL: url)
                                            internalIsPost = false
                                            isInternalPresented = true
                                        } else {
                                            safariLink = url
                                            showSafari = true
                                        }
                                        return .handled
                                    })
                                    .navigationDestination(isPresented: $isInternalPresented) {
                                        if !internalIsPost { // internal is community
                                            PostsView(itemInView: $internalItemInView, restoreScroll: $internalRestoreScrollPlaceholder,
                                                      target: $internalCommunityTarget, loadPosts: $internalLoadPosts)
                                        } else {
                                            CommentsView(restorePostsScroll: $internalRestoreScrollPlaceholder, link: safariLink!.path)
                                        }
                                    }
                                if comment.media_metadata != nil {
                                    CommentGifView(comment: comment)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }
//                            .padding(EdgeInsets(top: 6, leading: 0, bottom: 0, trailing: 0))
                    }
                }
//                .padding(EdgeInsets(top: 0, leading: comment.isCollapsed ? 5 * (CGFloat(integerLiteral: comment.depth) + 1) : 0, bottom: 0, trailing: 0))
            }
            .background(Color(UIColor.systemBackground))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding(EdgeInsets(top: 0, leading: indentSize, bottom: 0, trailing: 10))
            .onTapGesture {
                commentsModel.collapseComment(link: postLink, comment: comment)
                scrollTarget = comment.id
            }
            .contextMenu{ CommentActions(comment: comment, editorParentComment: $editorParentComment,
                                         isEditorShowing: $isEditorShowing, showingDeleteAlert: $showingDeleteAlert, postLink: postLink) }
            .swipeActions(edge: commentsModel.reverseSwipeControls ? .trailing : .leading, allowsFullSwipe: true) {
                Button { commentsModel.toggleUpvoteComment(link: postLink, comment: comment) } label: {
                    Image(systemName: "arrow.up")
                }
                .tint(.upvoteOrange)
                Button { commentsModel.toggleDownvoteComment(link: postLink, comment: comment) } label: {
                    Image(systemName: "arrow.down")
                }
                .tint(.downvoteBlue)
            }
            .swipeActions(edge: commentsModel.reverseSwipeControls ? .leading : .trailing, allowsFullSwipe: true) {
                Button {
                    scrollTarget = commentsModel.collapseCommentThread(link: postLink, comment: comment)
                } label: {
                    Image(systemName: "arrow.up.to.line")
                }
                .tint(Color(UIColor.systemBlue))
            }
        }
        .alert("Delete comment", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { showingDeleteAlert = false }
            Button("Delete", role: .destructive) {
                commentsModel.deleteComment(link: postLink, comment: comment)
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
    
//    var color: [Color] {
//        let defaultTheme = [
//            Color(red: 192 / 255, green: 57 / 255, blue: 43 / 255),
//            Color(red: 230 / 255, green: 126 / 255, blue: 34 / 255),
//            Color(red: 241 / 255, green: 196 / 255, blue: 15 / 255),
//            Color(red: 39 / 255, green: 174 / 255, blue: 96 / 255),
//            Color(red: 52 / 255, green: 152 / 255, blue: 219 / 255),
//            Color(red: 13 / 255, green: 71 / 255, blue: 161 / 255),
//            Color(red: 142 / 255, green: 68 / 255, blue: 173 / 255)
//        ]
//        let fieldsTheme = [
//            Color(red: 63 / 255, green: 153 / 255, blue: 252 / 255),
//            Color(red: 0 / 255, green: 87 / 255, blue: 183 / 255),
//            Color(red: 225 / 255, green: 221 / 255, blue: 0 / 255),
//            Color(red: 240 / 255, green: 164 / 255, blue: 65 / 255),
//            Color(red: 88 / 255, green: 135 / 255, blue: 43 / 255),
//            Color(red: 0 / 255, green: 66 / 255, blue: 37 / 255),
//            Color(red: 2 / 255, green: 60 / 255, blue: 110 / 255)
//        ]
//        let vibrantTheme = [
//            Color(red: 1, green: 0, blue: 24 / 255),
//            Color(red: 1, green: 165 / 255, blue: 44 / 255),
//            Color(red: 1, green: 1, blue: 65 / 255),
//            Color(red: 0, green: 128 / 255, blue: 24 / 255),
//            Color(red: 0, green: 0, blue: 249 / 255),
//            Color(red: 134 / 255, green: 0, blue: 125 / 255),
//            Color(red: 91 / 255, green: 206 / 255, blue: 250 / 255),
//            Color(red: 245 / 255, green: 169 / 255, blue: 184 / 255)
//        ]
//        let vibrant2Theme = [
//            Color(red: 91 / 255, green: 206 / 255, blue: 250 / 255),
//            Color(red: 245 / 255, green: 169 / 255, blue: 184 / 255),
//            Color(red: 1, green: 1, blue: 1),
//            Color(red: 245 / 255, green: 169 / 255, blue: 184 / 255),
//            Color(red: 91 / 255, green: 206 / 255, blue: 250 / 255),
//            Color(red: 245 / 255, green: 169 / 255, blue: 184 / 255),
//            Color(red: 1, green: 1, blue: 1),
//            Color(red: 245 / 255, green: 169 / 255, blue: 184 / 255),
//        ]
//        let amphibianTheme = [
//            Color(red: 116 / 255, green: 237 / 255, blue: 202 / 255),
//            Color(red: 79 / 255, green: 224 / 255, blue: 182 / 255),
//            Color(red: 61 / 255, green: 245 / 255, blue: 242 / 255),
//            Color(red: 21 / 255, green: 205 / 255, blue: 202 / 255),
//            Color(red: 79 / 255, green: 175 / 255, blue: 226 / 255),
//            Color(red: 79 / 255, green: 128 / 255, blue: 226 / 255),
//            Color(red: 62 / 255, green: 84 / 255, blue: 221 / 255)
//        ]
//        var themes: [String:[Color]] = [:]
//        themes["default"] = defaultTheme
//        themes["amphibian"] = amphibianTheme
//        themes["fields"] = fieldsTheme
//        themes["vibrant"] = vibrantTheme
//        themes["vibrant_2"] = vibrant2Theme
//        for key in themes.keys {
//            var theme = themes[key]!
//            theme.append(contentsOf: theme)
//            themes[key] = theme
//        }
//        return themes[commentsModel.commentTheme]!
//    }
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
                isEditorShowing = true
            }) {
                Label("Reply", systemImage: "arrow.uturn.left")
            }
            
            if comment.user?.lowercased() == model.userName?.lowercased() {
                Button(action: {
                    showingDeleteAlert = true
                }) {
                    Label("Delete comment", systemImage: "trash")
                }
            }
            
            if comment.user != nil {
                NavigationLink(destination: PostsView(itemInView: $itemInView, restoreScroll: $restoreScrollPlaceholder, target: $newTarget, loadPosts: $loadPosts)) {
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
                        .foregroundColor(Color(UIColor.systemBlue))
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
                        .foregroundColor(Color(UIColor.systemBlue))
                        .font(.system(size: 25))
                        .frame(maxWidth: .infinity, alignment: .topTrailing)
                        .padding(EdgeInsets(top: 5, leading: 0, bottom: 0, trailing: 15))
                        .onTapGesture {
                            if content != "" {
                                commentsModel.sendReply(link: postLink, parent: parentComment, content: content)
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
//                        var content = parentComment!.content!.count > 350 ?
//                        String(parentComment!.content!.prefix(350)) + "..." : parentComment!.content!
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
                Button(action: { showingDeleteDialog = true }) {
                    Label("Delete post", systemImage: "xmark")
                }
            }
        } label: {
            Label("Actions", systemImage: "ellipsis")
        }
    }
}
