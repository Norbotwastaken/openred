//
//  CommentsView.swift
//  openred
//
//  Created by Norbert Antal on 6/18/23.
//

import SwiftUI
import RichText
import WebKit

struct CommentsView: View {
    @EnvironmentObject var model: Model
    @EnvironmentObject var commentsModel: CommentsModel
    @EnvironmentObject var popupViewModel: PopupViewModel
    var post: Post
    @Binding var commentInView: String
    
    var body: some View {
        ZStack {
            ScrollViewReader { proxy in
                List {
                    VStack {
                        Text(post.title)
                            .font(.headline) +
                        Text(post.flair != nil ? "  [" + post.flair! + "]" : "")
                            .foregroundColor(.secondary)
                            .font(.system(size: 12))
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(EdgeInsets(top: 8, leading: 10, bottom: 0, trailing: 10))
                    .listRowInsets(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0))
                    .listRowSeparator(.hidden)
                    HStack {
                        Image(systemName: "arrow.up")
                            .foregroundColor(post.isUpvoted ? .orange : .secondary)
                            .onTapGesture {
                                if model.toggleUpvotePost(post: post) == false {
                                    // show login popup
                                }
                            }
                        Image(systemName: "arrow.down")
                            .foregroundColor(post.isDownvoted ? .blue : .secondary)
                            .onTapGesture {
                                if model.toggleDownvotePost(post: post) == false {
                                    // show login popup
                                }
                            }
                    }
                    .font(.system(size: 22))
//                    VStack(alignment: .leading) {
                    ForEach(commentsModel.comments) { comment in
                            //                        VStack(alignment: .leading) {
                            CommentView(comment: comment)
//                        Text("some comment")
                                .onAppear {
                                    commentInView = comment.id
                                }
                                .listRowInsets(EdgeInsets())
                                .listRowSeparator(.hidden)
                        }
//                    }
                }
                .listStyle(PlainListStyle())
                .navigationTitle(commentsModel.commentCount + " comments")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        HStack {
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
            commentsModel.openCommentsPage(linkToThread: post.linkToThread)
        }
    }
}

struct CommentView: View {
    @EnvironmentObject var commentsModel: CommentsModel
    var comment: Comment
    @State private var size: CGSize = .zero
    @State private var isLoaded: Bool = false
    
    var body: some View {
        if !isHidden {
            HStack(spacing: 10) {
                if comment.depth > 0 && !commentsModel.commentsCollapsed[comment.id]! {
                    Rectangle()
                        .frame(maxWidth: 2, maxHeight: .infinity, alignment: .leading)
//                        .padding(EdgeInsets(top: 3, leading: 0, bottom: 3, trailing: 0))
                        .foregroundColor(Color.green)
                }
                VStack {
                    HStack(spacing: 10) {
                        Text(comment.user ?? "deleted")
                        if comment.score != nil {
                            HStack(spacing: 2) {
                                Image(systemName: "arrow.up")
                                Text(comment.score!)
                            }
                            .foregroundColor(comment.isUpvoted ? .orange : comment.isDownvoted ? .blue : .secondary)
                        }
                    }
                    .foregroundColor(.secondary)
                    .font(.system(size: 14))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    if !(commentsModel.commentsCollapsed[comment.id] ?? true) {
                        ZStack {
                            if (!isLoaded) {
                                Spacer().frame(height: 40)
                                    .onAppear{ isLoaded = true }
                            } else {
                                RichText(html: comment.content!)
                                    .placeholder{ Spacer().frame(height: 40) }
                            }
                        }
                        .font(.system(size: 14))
                        .padding(EdgeInsets(top: 5, leading: 0, bottom: 0, trailing: 0))
                    }
                }
            }
            .background(Color(UIColor.systemBackground))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding(EdgeInsets(top: 0, leading: 10 * CGFloat(integerLiteral:comment.depth), bottom: 0, trailing: 0))
            .onTapGesture {
                commentsModel.commentsCollapsed[comment.id]?.toggle()
            }
            .swipeActions(edge: .leading) {
                Button { commentsModel.toggleUpvoteComment(comment: comment) } label: {
                    Image(systemName: "arrow.up")
                }
                .tint(.orange)
            }
            .swipeActions(edge: .trailing) {
                Button { commentsModel.toggleDownvoteComment(comment: comment) } label: {
                    Image(systemName: "arrow.down")
                }
                .tint(.blue)
            }
            Rectangle()
                .fill(Color(UIColor.systemGray5)
                    .shadow(.inner(radius: 2, y: 1)).opacity(0.5))
                .frame(maxWidth: .infinity, maxHeight: 5)
        }
    }
    
    var isHidden: Bool {
        for parentId in comment.allParents {
            if commentsModel.commentsCollapsed[parentId] == true {
                return true
            }
        }
        return false
    }
    
//    var scoreColor: Color {
//        if comment.isUpvoted {
//            return .orange
//        }
//        if comment.isDownvoted {
//            return .blue
//        }
//        return .secondary
//    }
}
