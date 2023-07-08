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
    @EnvironmentObject var popupViewModel: PopupViewModel
    @ObservedObject var post: Post
//    @Binding var commentInView: String
    
    var body: some View {
        ZStack {
            ScrollViewReader { proxy in
                List {
                    VStack {
                        VStack {
                            Text(post.title)
                                .font(.headline) +
                            Text(post.flair != nil ? "  [" + post.flair! + "]" : "")
                                .foregroundColor(.secondary)
                                .font(.system(size: 12))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                        .listRowInsets(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0))
                        .listRowSeparator(.hidden)
                        
                        PostRowContent(post: post, isPostOpen: true)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: post.contentType == .text ? .leading : .center)
                        
                        HStack {
                            Image(systemName: "arrow.up")
                                .foregroundColor(post.isUpvoted ? .upvoteOrange : .secondary)
                                .onTapGesture {
                                    if model.toggleUpvotePost(post: post) == false {
                                        // show login popup
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .center)
                            Image(systemName: "arrow.down")
                                .foregroundColor(post.isDownvoted ? .downvoteBlue : .secondary)
                                .onTapGesture {
                                    if model.toggleDownvotePost(post: post) == false {
                                        // show login popup
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(EdgeInsets(top: 5, leading: 0, bottom: 8, trailing: 0))
                        .font(.system(size: 28))
                        .listRowSeparator(.hidden)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    ForEach(commentsModel.comments) { comment in
                        CommentView(comment: comment)
//                            .onAppear {
//                                commentInView = comment.id
//                            }
                            .listRowInsets(EdgeInsets(top: 16, leading: 0, bottom: 20, trailing: 0))
                            .padding(EdgeInsets(top: 8, leading: 0, bottom: 0, trailing: 0))
                            .listRowSeparator(.hidden)
                    }
                }
                .listStyle(PlainListStyle())
                .navigationTitle(commentsModel.commentCount + " comments")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        HStack {
                            CommentSortMenu()
                            Button {
                                // Perform an action
                                print("Add Item Tapped")
                            } label: {
                                Image(systemName: "ellipsis")
                            }
                        }
                    }
                }
//                .onAppear(perform: {
//                    proxy.scrollTo(commentInView)
//                })
            }
        }
        .onAppear {
            commentsModel.loadComments(linkToThread: post.linkToThread)
        }
    }
}

struct CommentView: View {
    @EnvironmentObject var commentsModel: CommentsModel
    @ObservedObject var comment: Comment
    
    var body: some View {
        VStack {
            HStack(spacing: 10) {
                if comment.depth > 0 && !comment.isHidden {
                    Rectangle()
                        .frame(maxWidth: 2, maxHeight: .infinity, alignment: .leading)
                        .padding(EdgeInsets(top: 20, leading: 0, bottom: 0, trailing: 0))
                        .foregroundColor(indentColor[comment.depth - 1])
                        .opacity(0.8)
                }
                VStack {
                    HStack(spacing: 10) {
                        Text(comment.user ?? "deleted")
                        //                        if comment.score != nil {
                        HStack(spacing: 2) {
                            Image(systemName: "arrow.up")
                                .foregroundColor(comment.isUpvoted ? .upvoteOrange : comment.isDownvoted ? .downvoteBlue : .secondary)
                            Text(String(comment.score))
                        }
                        //                        }
//                        CommentActionsMenu(comment: comment)
                        Menu {
                            CommentActions(comment: comment)
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
                    }
                    .foregroundColor(.secondary)
                    .font(.system(size: 14))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    if !comment.isHidden {
                        Text(comment.content ?? "comment not found")
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .font(.system(size: 15))
                            .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                    }
                }
            }
            .background(Color(UIColor.systemBackground))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding(EdgeInsets(top: 0, leading: 5 * (CGFloat(integerLiteral:comment.depth) + 1), bottom: 0, trailing: 10))
            .onTapGesture {
                comment.isHidden.toggle()
            }
//            TODO: swipe actions and context menu are a mess
//            .contextMenu{ CommentActions(comment: comment) }
//            .swipeActions(edge: .leading, allowsFullSwipe: true) {
//                Button { commentsModel.toggleUpvoteComment(comment: comment) } label: {
//                    Image(systemName: "arrow.up")
//                }
//                .tint(.upvoteOrange)
//                Button { commentsModel.toggleDownvoteComment(comment: comment) } label: {
//                    Image(systemName: "arrow.down")
//                }
//                .tint(.downvoteBlue)
//            }
            if !comment.isHidden {
                ForEach(comment.replies) { reply in
                    CommentView(comment: reply)
                        .padding(EdgeInsets(top: 8, leading: 0, bottom: 0, trailing: 0))
                    //                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 20, trailing: 0))
                }
            }
        }
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
    @ObservedObject var comment: Comment
    
    var body: some View {
        Group {
            Button(action: { commentsModel.toggleUpvoteComment(comment: comment) }) {
                Label("Upvote", systemImage: "arrow.up")
            }
            Button(action: { commentsModel.toggleDownvoteComment(comment: comment) }) {
                Label("Downvote", systemImage: "arrow.down")
            }
            Button(action: { commentsModel.toggleSaveComment(comment: comment) }) {
                Label(comment.isSaved ? "Undo Save" : "Save", systemImage: comment.isSaved ? "bookmark.slash" : "bookmark")
            }
        }
    }
}

struct CommentSortMenu: View {
    @EnvironmentObject var commentsModel: CommentsModel
    
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
            Label("Sort by", systemImage: commentsModel.selectedSortingIcon)
        }
    }
    
    func sortCommunity(sortModifier: String) {
        commentsModel.loadComments(linkToThread: commentsModel.currentLink, sortBy: sortModifier)
    }
}

struct CommentEditor: View {
    @EnvironmentObject var commentsModel: CommentsModel
    @State private var content: String = ""
    @FocusState private var isFieldFocused: Bool
    
    var body: some View {
        ZStack {
            TextField("Write...", text: $content)
                .textFieldStyle(.roundedBorder)
                .focused($isFieldFocused)
        }
    }
}
