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
    
    var body: some View {
        ZStack {
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
                            PostRowContent(post: commentsModel.pages[link]!.post!, isPostOpen: true)
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
                                        editorParentComment = nil
                                        isEditorShowing = true
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
                    .navigationTitle(commentsModel.pages[link]!.commentCount + " comments")
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationBarHidden(isEditorShowing)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            HStack {
                                CommentSortMenu(selectedSort: $selectedSort, postLink: link)
                                Button {
                                    // Perform an action
                                    print("Add Item Tapped")
                                } label: {
                                    Image(systemName: "ellipsis")
                                }
                            }
                        }
                    }
                    .onChange(of: scrollTarget) { target in
                        if let target = target {
                            scrollTarget = nil
                            
                            //                        withAnimation {
                            proxy.scrollTo(target, anchor: .top)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                proxy.scrollTo(target, anchor: .top)
                            }
                            //                        }
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
    
    var body: some View {
        VStack {
//            Divider()
            HStack(spacing: 6) {
//            HStack() {
                if comment.depth > 0 && !comment.isCollapsed {
                    Rectangle()
                        .frame(maxWidth: 2, maxHeight: .infinity, alignment: .leading)
                        .padding(EdgeInsets(top: 20, leading: 0, bottom: 0, trailing: 0))
                        .foregroundColor(indentColor[comment.depth - 1])
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
                                           isEditorShowing: $isEditorShowing, postLink: postLink)
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
                            Text(comment.content ?? "")
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .font(.system(size: 15))
                                .environment(\.openURL, OpenURLAction { url in
                                    if url.isImage {
                                        popupViewModel.fullImageLink = String(htmlEncodedString: url.absoluteString)
                                        popupViewModel.contentType = .image
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
                comment.isCollapsed.toggle()
                commentsModel.pages[postLink]!.commentsCollapsed[comment.id]!.toggle()
                scrollTarget = comment.id
            }
            .contextMenu{ CommentActions(comment: comment, editorParentComment: $editorParentComment,
                                         isEditorShowing: $isEditorShowing, postLink: postLink) }
            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                Button { commentsModel.toggleUpvoteComment(link: postLink, comment: comment) } label: {
                    Image(systemName: "arrow.up")
                }
                .tint(.upvoteOrange)
                Button { commentsModel.toggleDownvoteComment(link: postLink, comment: comment) } label: {
                    Image(systemName: "arrow.down")
                }
                .tint(.downvoteBlue)
            }
        }
    }
    
    var indentSize: CGFloat {
        var indent = 5 * (CGFloat(integerLiteral: comment.depth) + 1)
        if comment.isCollapsed && comment.depth > 0 {
            indent = indent + 8.5
        }
        return indent
    }
    
    var indentColor: [Color] = [
        Color(red: 192 / 255, green: 57 / 255, blue: 43 / 255),
        Color(red: 230 / 255, green: 126 / 255, blue: 34 / 255),
        Color(red: 241 / 255, green: 196 / 255, blue: 15 / 255),
        Color(red: 39 / 255, green: 174 / 255, blue: 96 / 255),
        Color(red: 52 / 255, green: 152 / 255, blue: 219 / 255),
        Color(red: 13 / 255, green: 71 / 255, blue: 161 / 255),
        Color(red: 142 / 255, green: 68 / 255, blue: 173 / 255),
        // start again
        Color(red: 192 / 255, green: 57 / 255, blue: 43 / 255),
        Color(red: 230 / 255, green: 126 / 255, blue: 34 / 255),
        Color(red: 241 / 255, green: 196 / 255, blue: 15 / 255),
        Color(red: 39 / 255, green: 174 / 255, blue: 96 / 255),
        Color(red: 52 / 255, green: 152 / 255, blue: 219 / 255),
        Color(red: 13 / 255, green: 71 / 255, blue: 161 / 255),
        Color(red: 142 / 255, green: 68 / 255, blue: 173 / 255)
    ]
}

struct CommentActions: View {
    @EnvironmentObject var commentsModel: CommentsModel
    @EnvironmentObject var model: Model
    @EnvironmentObject var overlayModel: MessageOverlayModel
    @ObservedObject var comment: Comment
    @Binding var editorParentComment: Comment?
    @Binding var isEditorShowing: Bool
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
            
            if comment.user != nil {
                NavigationLink(destination: PostsView(itemInView: $itemInView, restoreScroll: $restoreScrollPlaceholder, target: $newTarget, loadPosts: $loadPosts)) {
                    Button(action: {}) {
                        Label("User Profile", systemImage: "person")
                    }
                }
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
