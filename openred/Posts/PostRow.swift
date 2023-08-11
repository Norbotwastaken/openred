//
//  PostRow.swift
//  openred
//
//  Created by Norbert Antal on 6/12/23.
//

import Foundation
import SwiftUI

struct PostRow: View {
    @EnvironmentObject var model: Model
    @EnvironmentObject var popupViewModel: PopupViewModel
    var post: Post
    @Binding var target: CommunityOrUser
    
    var body: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading) {
                Text(post.title)
                    .font(.headline) +
                Text(post.flair != nil ? LocalizedStringKey("  [" +  post.flair! + "]") : "")
                    .foregroundColor(.secondary)
                    .font(.system(size: 12))
                if post.nsfw {
                    Text("NSFW")
                        .font(.system(size: 14))
                        .fontWeight(.semibold)
                        .padding(EdgeInsets(top: 3, leading: 4, bottom: 3, trailing: 4))
                        .background(Color(red: 1, green: 0, blue: 93 / 255))
                        .cornerRadius(5)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .padding(EdgeInsets(top: 8, leading: 10, bottom: 4, trailing: 10))
            .disabled(true)
            PostRowContent(post: post)
                .frame(maxWidth: .infinity, maxHeight: 650, alignment: .leading)
            PostRowFooter(post: post, target: $target)
            Rectangle()
                .fill(Color(UIColor.systemGray5)
                    .shadow(.inner(radius: 2, y: 1)).opacity(0.5))
                .frame(maxWidth: .infinity, maxHeight: 5)
        }
    }
}

struct PostCommentRow: View {
    @EnvironmentObject var model: Model
    var comment: Comment
    @State var newTarget: CommunityOrUser = CommunityOrUser(community: Community(""))
    @State var isPresented: Bool = false
    @State var restoreScrollPlaceholder: Bool = true
    @State var loadPosts: Bool = true
    @State var itemInView: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            VStack(spacing: 8) {
                Text(comment.linkTitle ?? "")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if comment.nsfw {
                    Text("NSFW")
                        .font(.system(size: 14))
                        .fontWeight(.semibold)
                        .padding(EdgeInsets(top: 3, leading: 4, bottom: 3, trailing: 4))
                        .background(Color(red: 1, green: 0, blue: 93 / 255))
                        .cornerRadius(5)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                Text("r/" + comment.communityName)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .font(.system(size: 14))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .navigationDestination(isPresented: $isPresented) {
                        PostsView(itemInView: $itemInView, restoreScroll: $restoreScrollPlaceholder, target: $newTarget, loadPosts: $loadPosts)
                    }
                    .onTapGesture {
                        newTarget = CommunityOrUser(community: Community(comment.communityName))
                        isPresented = true
                    }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            VStack(spacing: 8) {
                Text(comment.user ?? "")
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .font(.system(size: 14))
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(comment.content ?? "")
                    .font(.system(size: 15))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            }
            Rectangle()
                .fill(Color(UIColor.systemGray5)
                    .shadow(.inner(radius: 2, y: 1)).opacity(0.5))
                .frame(maxWidth: .infinity, maxHeight: 5)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(EdgeInsets(top: 8, leading: 10, bottom: 0, trailing: 10))
    }
}


struct PostRowFooter: View {
    @EnvironmentObject var model: Model
    @ObservedObject var post: Post
    @Binding var target: CommunityOrUser
    @State var isPresented: Bool = false
    @State var restoreScrollPlaceholder: Bool = true
    @State var newTarget: CommunityOrUser = CommunityOrUser(community: Community("")) // placeholder value
    @State var loadPosts: Bool = true
    @State var itemInView: String = ""
    @State private var showingSaveDialog = false
    
    var body: some View {
        HStack {
            VStack(spacing: 8) {
                HStack(spacing: 5) {
                    if post.stickied {
                        Image(systemName: "megaphone.fill")
                            .foregroundColor(Color(UIColor.systemGreen))
                            .font(.system(size: 12))
                    }
                    Text(model.pages[target.getCode()]!.selectedCommunity.isMultiCommunity ? "r/" + post.community! :
                            post.userName != nil ? "by " + post.userName! : "")
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .frame(alignment: .leading)
                    .navigationDestination(isPresented: $isPresented) {
                        PostsView(itemInView: $itemInView, restoreScroll: $restoreScrollPlaceholder, target: $newTarget, loadPosts: $loadPosts)
                    }
                    .onTapGesture {
                        if model.pages[target.getCode()]!.selectedCommunity.isMultiCommunity {
                            newTarget = CommunityOrUser(community: Community(post.community!))
                            isPresented = true
                        }
                        // TODO: navigate to user turned off, inconsistent behavior
//                        else if post.userName != "[deleted]" {
//                            newTarget = CommunityOrUser(user: User(post.userName!))
//                        }
                    }
                    Spacer().frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 5))
                
                HStack {
                    HStack(spacing: 3) {
                        Image(systemName: "arrow.up")
                        Text(formatScore(score: post.score))
                    }
                    HStack(spacing: 3) {
                        Image(systemName: "text.bubble")
                        Text(formatScore(score: post.commentCount))
                    }
                    HStack(spacing: 3) {
                        Image(systemName: "clock")
                        Text(post.displayAge)
                    }
                    HStack(spacing: 3) {
                        ForEach(post.awardLinks.indices) { i in
                            if i < 3 {
                                AsyncImage(url: URL(string: post.awardLinks[i])) { image in
                                    image.image?
                                        .resizable()
                                        .scaledToFill()
                                        .frame(maxWidth: 15, maxHeight: 15)
                                }
                            }
                        }
                        if post.awardCount > 1 {
                            Text(String(post.awardCount))
                        }
                    }
                }
                .foregroundStyle(.secondary)
                .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 5))
                .frame(maxWidth: .infinity, maxHeight: 15, alignment: .leading)
            }
            .font(.system(size: 14))
            .frame(minWidth: 190, maxWidth: .infinity, alignment: .leading)
            HStack(spacing: 12) {
                Menu {
                    PostRowMenu(post: post, target: $target, showingSaveDialog: $showingSaveDialog)
                } label: {
                    ZStack {
                        Spacer()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        Image(systemName: "ellipsis")
                            .foregroundColor(.secondary)
                    }
                    .frame(width: 20, height: 20)
                }
                .alert("Save image to library?", isPresented: $showingSaveDialog) {
                    SaveImageAlert(showingSaveDialog: $showingSaveDialog, link: post.imageLink)
                }
                Image(systemName: "arrow.up")
                    .foregroundColor(post.isUpvoted ? .upvoteOrange : .secondary)
                    .onTapGesture {
                        if model.toggleUpvotePost(target: target.getCode(), post: post) == false {
                            // show login popup
                        }
                    }
                Image(systemName: "arrow.down")
                    .foregroundColor(post.isDownvoted ? .downvoteBlue : .secondary)
                    .onTapGesture {
                        if model.toggleDownvotePost(target: target.getCode(), post: post) == false {
                            // show login popup
                        }
                    }
            }
            .font(.system(size: 22))
            .frame(maxWidth: 40, alignment: .trailing)
            .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 10))
        }
        .frame(maxWidth: .infinity)
        .padding(EdgeInsets(top: 6, leading: 8, bottom: 6, trailing: 10))
    }
    
//    private func getFooterLabel(post: Post) -> String {
//        if let community = post.community {
//            return community
//        }
//        return post.userName != nil ? "u/" + post.userName! : ""
//    }
}

func formatScore(score: String) -> String {
    if var number = Int(score) {
        if number >= 1000 {
            if number >= 1000000 {
                number = number / 100000
                var displayScore = String(number)
                displayScore.insert(".", at: displayScore.index(before: displayScore.endIndex))
                displayScore = displayScore + "M"
                return displayScore
            }
            number = number / 100
            var displayScore = String(number)
            displayScore.insert(".", at: displayScore.index(before: displayScore.endIndex))
            displayScore = displayScore + "K"
            return displayScore
        } else {
            return score
        }
    } else {
        return score
    }
}

struct PostRowMenu: View {
    @EnvironmentObject var model: Model
    @EnvironmentObject var overlayModel: MessageOverlayModel
    @ObservedObject var post: Post
    @Binding var target: CommunityOrUser
    @Binding var showingSaveDialog: Bool
//    @State var isPresented: Bool = false
    @State var restoreScrollPlaceholder: Bool = true
    @State var newTarget: CommunityOrUser = CommunityOrUser(community: Community(""))
    @State var loadPosts: Bool = true
    @State var itemInView: String = ""
    
    var body: some View {
        Group {
            Button(action: { model.toggleUpvotePost(target: target.getCode(), post: post) }) {
                Label("Upvote", systemImage: "arrow.up")
            }
            Button(action: { model.toggleDownvotePost(target: target.getCode(), post: post) }) {
                Label("Downvote", systemImage: "arrow.down")
            }
            Button(action: {
                if model.toggleSavePost(target: target.getCode(), post: post) {
                    overlayModel.show(post.isSaved ? "Post saved" : "Removed from saved")
                }
            }) {
                Label(post.isSaved ? "Undo Save" : "Save", systemImage: post.isSaved ? "bookmark.slash" : "bookmark")
            }
            NavigationLink(destination: PostsView(itemInView: $itemInView, restoreScroll: $restoreScrollPlaceholder, target: $newTarget, loadPosts: $loadPosts)) {
                Button(action: {}) {
                    Label("User Profile", systemImage: "person")
                }
            }
            if post.contentType == .image {
                Button(action: { showingSaveDialog = true }) {
                    Label("Download image", systemImage: "arrow.down.square")
                }
            } else if post.contentType == .text {
                Button(action: {
                    UIPasteboard.general.string = String(post.text!.characters[...])
                    overlayModel.show("Copied to clipboard")
                }) {
                    Label("Copy text", systemImage: "list.clipboard")
                }
            }
        }
        .onAppear { newTarget = CommunityOrUser(community: nil, user: User(post.userName!)) }
    }
}
