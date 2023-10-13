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
    @EnvironmentObject var overlayModel: MessageOverlayModel
    @EnvironmentObject var settingsModel: SettingsModel
    var post: Post
    @Binding var target: CommunityOrUser
    @State var showingSaveDialog = false
    @State var showingDeleteDialog = false
    @State var showingNsfwDialog = false
    @State var showingSpoilerDialog = false
    
    var body: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading) {
                HStack {
                    if settingsModel.compactMode && (post.thumbnailLink != "" || post.contentType == .link)
                        && !settingsModel.compactModeReverse {
                        PostRowCompactContent(post: post)
                    }
                    VStack {
                        if settingsModel.compactMode {
                            Text(post.title)
                                .font(.system(size: 16 + CGFloat(model.textSizeInrease)))
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity, alignment: .topLeading)
                            PostRowCompactFooter(post: post, target: $target)
                        } else {
                            Text(post.title)
                                .font(.headline) +
                            Text(post.flair != nil ? LocalizedStringKey("  [" +  post.flair! + "]") : "")
                                .foregroundColor(.secondary)
                                .font(.system(size: 12))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    if settingsModel.compactMode && (post.thumbnailLink != "" || post.contentType == .link)
                        && settingsModel.compactModeReverse {
                        // Duplicate of previous block, positions thumbnails on the other side.
                        PostRowCompactContent(post: post)
                    }
                    if !settingsModel.compactMode {
                        HStack {
                            if post.nsfw {
                                Text("NSFW")
                                    .foregroundColor(.white)
                                    .font(.system(size: 14 + CGFloat(model.textSizeInrease)))
                                    .fontWeight(.semibold)
                                    .padding(EdgeInsets(top: 3, leading: 4, bottom: 3, trailing: 4))
                                    .background(Color.nsfwPink)
                                    .cornerRadius(5)
                                    .frame(alignment: .leading)
                            }
                            if post.spoiler {
                                Text("Spoiler".uppercased())
                                    .foregroundColor(.white)
                                    .font(.system(size: 14 + CGFloat(model.textSizeInrease)))
                                    .fontWeight(.semibold)
                                    .padding(EdgeInsets(top: 3, leading: 4, bottom: 3, trailing: 4))
                                    .background(Color(UIColor.systemGray))
                                    .cornerRadius(5)
                                    .frame(alignment: .leading)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .fixedSize(horizontal: false, vertical: true)
            .padding(EdgeInsets(top: settingsModel.compactMode ? 0 : 8, leading: 10,
                                bottom: settingsModel.compactMode ? 0 : 4, trailing: 10))
            .disabled(!settingsModel.compactMode)
            if !settingsModel.compactMode {
                PostRowContent(post: post)
                    .frame(maxWidth: .infinity, maxHeight: 650, alignment: .leading)
                PostRowFooter(post: post, target: $target)
            }
            if !settingsModel.compactMode {
                Rectangle()
                    .fill(Color(UIColor.systemGray3)
                        .shadow(.inner(radius: 2, y: 1)).opacity(0.5))
                    .frame(maxWidth: .infinity, maxHeight: 5)
            } else {
                Divider()
            }
        }
        .contextMenu{ PostRowMenu(post: post, target: $target, showingSaveDialog: $showingSaveDialog,
                                  showingDeleteDialog: $showingDeleteDialog, showingNsfwDialog: $showingNsfwDialog,
                                  showingSpoilerDialog: $showingSpoilerDialog) }
        .alert("Save image to library?", isPresented: $showingSaveDialog) {
            if post.contentType == .image {
                SaveImageAlert(showingSaveDialog: $showingSaveDialog, link: post.imageLink)
            } else if post.contentType == .gallery {
                SaveImageAlert(showingSaveDialog: $showingSaveDialog, link: post.gallery!.items[0].fullLink,
                               links: post.gallery!.items.map{ $0.fullLink })
            }
        }
        .alert("Delete post?", isPresented: $showingDeleteDialog) {
            Button("Cancel", role: .cancel) { showingDeleteDialog = false }
            Button("Delete", role: .destructive) {
                if model.deletePost(target: target.getCode(), post: post) {
                    overlayModel.show("Successfully deleted")
                }
                showingDeleteDialog = false
            }
        } message: {
            Text("Are you sure you want to delete your post?")
        }
        .alert(post.nsfw ? "Remove NSFW mark" : "Mark as NSFW", isPresented: $showingNsfwDialog) {
            Button("Cancel", role: .cancel) { showingNsfwDialog = false }
            Button("Continue") {
                if model.togglePostNsfw(target: target.getCode(), post: post) {
                    overlayModel.show("Post updated")
                }
                showingNsfwDialog = false
            }.keyboardShortcut(.defaultAction)
        } message: {
            Text(post.nsfw ? "Are you sure you want to mark your post as safe for work?"
                 : "Are you sure you want to mark your post as NSFW?")
        }
        .alert(post.spoiler ? "Remove spoiler mark" : "Mark as spoiler", isPresented: $showingSpoilerDialog) {
            Button("Cancel", role: .cancel) { showingSpoilerDialog = false }
            Button("Continue") {
                if model.togglePostSpoiler(target: target.getCode(), post: post) {
                    overlayModel.show("Post updated")
                }
                showingSpoilerDialog = false
            }.keyboardShortcut(.defaultAction)
        } message: {
            Text(post.spoiler ? "Are you sure you want to mark your post as spoiler free?"
                 : "Are you sure you want to mark your post for spoilers?")
        }
    }
}

struct PostCommentRow: View {
    @EnvironmentObject var model: Model
    @EnvironmentObject var settingsModel: SettingsModel
    var comment: Comment
    @State var newTarget: CommunityOrUser = CommunityOrUser(community: Community(""))
    @State var isPresented: Bool = false
    @State var restoreScrollPlaceholder: Bool = true
    @State var loadPosts: Bool = true
    @State var itemInView: String = ""
    @State var spoilerBlurActive = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            VStack(spacing: 8) {
                Text(comment.linkTitle ?? "")
                    .font(.system(size: settingsModel.compactMode ? 16 + CGFloat(model.textSizeInrease) : 17))
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                HStack {
                    Text("r/" + comment.communityName)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .font(.system(size: settingsModel.compactMode ? 13 : 14))
                        .lineLimit(1)
                        .frame(alignment: .leading)
                        .onTapGesture {
                            newTarget = CommunityOrUser(community: Community(comment.communityName))
                            isPresented = true
                        }
                    Text("by")
                        .foregroundStyle(.secondary)
                        .font(.system(size: settingsModel.compactMode ? 13 : 14))
                        .lineLimit(1)
                        .frame(alignment: .leading)
                    Text(comment.user ?? "")
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .font(.system(size: settingsModel.compactMode ? 13 : 14))
                        .lineLimit(1)
                        .frame(alignment: .leading)
                    if comment.nsfw {
                        Text("NSFW")
                            .lineLimit(1)
                            .foregroundColor(.white)
                            .font(.system(size: settingsModel.compactMode ? 12 : 14))
                            .fontWeight(.semibold)
                            .padding(EdgeInsets(top: 3, leading: 4, bottom: 3, trailing: 4))
                            .background(Color.nsfwPink)
                            .cornerRadius(5)
                            .frame(alignment: .leading)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            ZStack {
                VStack(spacing: 8) {
                    Text(comment.content ?? "")
                        .tint(Color(UIColor.systemBlue))
                        .font(.system(size: settingsModel.compactMode ? 14 : 15))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
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
            if !settingsModel.compactMode {
                Rectangle()
                    .fill(Color(UIColor.systemGray3)
                        .shadow(.inner(radius: 2, y: 1)).opacity(0.5))
                    .frame(maxWidth: .infinity, maxHeight: 5)
            } else {
                Divider()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(EdgeInsets(top: settingsModel.compactMode ? 0 : 8, leading: 10, bottom: 0, trailing: 10))
        .navigationDestination(isPresented: $isPresented) {
            PostsView(itemInView: $itemInView, restoreScroll: $restoreScrollPlaceholder, target: $newTarget, loadPosts: $loadPosts)
        }
    }
}


struct PostRowFooter: View {
    @EnvironmentObject var model: Model
    @EnvironmentObject var overlayModel: MessageOverlayModel
    @ObservedObject var post: Post
    @Binding var target: CommunityOrUser
    @State var isPresented: Bool = false
    @State var restoreScrollPlaceholder: Bool = true
    @State var newTarget: CommunityOrUser = CommunityOrUser(community: Community("")) // placeholder value
    @State var loadPosts: Bool = true
    @State var itemInView: String = ""
    @State private var showingSaveDialog = false
    @State private var showingDeleteDialog = false
    @State private var showingNsfwDialog = false
    @State private var showingSpoilerDialog = false
    
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
                    .frame(maxWidth: .infinity, alignment: .leading)
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
                PostRowMenuButton(post: post, target: $target, showingSaveDialog: $showingSaveDialog,
                            showingDeleteDialog: $showingDeleteDialog, showingNsfwDialog: $showingNsfwDialog,
                            showingSpoilerDialog: $showingSpoilerDialog)
                Image(systemName: "arrow.up")
                    .fontWeight(post.isUpvoted ? .semibold : .regular)
                    .foregroundColor(post.isUpvoted ? .upvoteOrange : .secondary)
                    .onTapGesture {
                        if model.toggleUpvotePost(target: target.getCode(), post: post) == false {
                            // show login popup
                        }
                    }
                Image(systemName: "arrow.down")
                    .fontWeight(post.isDownvoted ? .semibold : .regular)
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
        .navigationDestination(isPresented: $isPresented) {
            PostsView(itemInView: $itemInView, restoreScroll: $restoreScrollPlaceholder, target: $newTarget, loadPosts: $loadPosts)
        }
    }
}

struct PostRowCompactFooter: View {
    @EnvironmentObject var model: Model
    @EnvironmentObject var overlayModel: MessageOverlayModel
    @ObservedObject var post: Post
    @Binding var target: CommunityOrUser
    @State var isPresented: Bool = false
    @State var restoreScrollPlaceholder: Bool = true
    @State var newTarget: CommunityOrUser = CommunityOrUser(community: Community("")) // placeholder value
    @State var loadPosts: Bool = true
    @State var itemInView: String = ""
    @State private var showingSaveDialog = false
    @State private var showingDeleteDialog = false
    @State private var showingNsfwDialog = false
    @State private var showingSpoilerDialog = false
    
    var body: some View {
        HStack {
            HStack(spacing: 5) {
                if post.stickied {
                    Image(systemName: "megaphone.fill")
                        .foregroundColor(Color(UIColor.systemGreen))
                        .font(.system(size: 12))
                }
                Text(model.pages[target.getCode()]!.selectedCommunity.isMultiCommunity ? post.community! :
                        post.userName != nil ? "by " + post.userName! : "")
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .onTapGesture {
                    if model.pages[target.getCode()]!.selectedCommunity.isMultiCommunity {
                        newTarget = CommunityOrUser(community: Community(post.community!))
                        isPresented = true
                    }
                }
            }
            if post.nsfw && post.thumbnailLink == "" {
                Text("NSFW")
                    .font(.system(size: 12))
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
                    .padding(EdgeInsets(top: 3, leading: 4, bottom: 3, trailing: 4))
                    .background(Color.nsfwPink.opacity(0.8))
                    .cornerRadius(5)
            }
            if post.spoiler && post.thumbnailLink == "" {
                Text("Spoiler".uppercased())
                    .font(.system(size: 12))
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
                    .padding(EdgeInsets(top: 3, leading: 4, bottom: 3, trailing: 4))
                    .background(Color(UIColor.systemGray))
                    .cornerRadius(5)
            }
            HStack(spacing: 3) {
                Image(systemName: "arrow.up")
                Text(formatScore(score: post.score))
            }
            .fontWeight(post.isUpvoted || post.isDownvoted ? .semibold : .regular)
            .foregroundColor(post.isUpvoted ? .upvoteOrange : post.isDownvoted ? .downvoteBlue : .secondary)
            .onTapGesture {
                model.toggleUpvotePost(target: target.getCode(), post: post)
            }
            HStack(spacing: 3) {
                Image(systemName: "text.bubble")
                Text(formatScore(score: post.commentCount))
            }
            HStack(spacing: 3) {
                Image(systemName: "clock")
                Text(post.displayAge)
            }
            PostRowMenuButton(post: post, target: $target, showingSaveDialog: $showingSaveDialog,
                              showingDeleteDialog: $showingDeleteDialog, showingNsfwDialog: $showingNsfwDialog,
                              showingSpoilerDialog: $showingSpoilerDialog)
                .font(.system(size: 18))
        }
        .font(.system(size: 13))
        .foregroundStyle(.secondary)
        .padding(EdgeInsets(top: 0, leading: 0, bottom: 5, trailing: 5))
        .frame(maxWidth: .infinity, maxHeight: 15, alignment: .leading)
        .navigationDestination(isPresented: $isPresented) {
            PostsView(itemInView: $itemInView, restoreScroll: $restoreScrollPlaceholder, target: $newTarget, loadPosts: $loadPosts)
        }
    }
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

struct PostRowMenuButton: View {
    @EnvironmentObject var model: Model
    @EnvironmentObject var overlayModel: MessageOverlayModel
    @StateObject var post: Post
    @Binding var target: CommunityOrUser
    @Binding var showingSaveDialog: Bool
    @Binding var showingDeleteDialog: Bool
    @Binding var showingNsfwDialog: Bool
    @Binding var showingSpoilerDialog: Bool
    @State var restoreScrollPlaceholder: Bool = true
    @State var newTarget: CommunityOrUser = CommunityOrUser(community: Community(""))
    @State var loadPosts: Bool = true
    @State var itemInView: String = ""
    
    var body: some View {
        Menu {
            PostRowMenu(post: post, target: $target, showingSaveDialog: $showingSaveDialog,
                        showingDeleteDialog: $showingDeleteDialog, showingNsfwDialog: $showingNsfwDialog,
                        showingSpoilerDialog: $showingSpoilerDialog)
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
            if post.contentType == .image {
                SaveImageAlert(showingSaveDialog: $showingSaveDialog, link: post.imageLink)
            } else if post.contentType == .gallery {
                SaveImageAlert(showingSaveDialog: $showingSaveDialog, link: post.gallery!.items[0].fullLink,
                               links: post.gallery!.items.map{ $0.fullLink })
            }
        }
        .alert("Delete post?", isPresented: $showingDeleteDialog) {
            Button("Cancel", role: .cancel) { showingDeleteDialog = false }
            Button("Delete", role: .destructive) {
                if model.deletePost(target: target.getCode(), post: post) {
                    overlayModel.show("Successfully deleted")
                }
                showingDeleteDialog = false
            }
        } message: {
            Text("Are you sure you want to delete your post?")
        }
        .alert(post.nsfw ? "Remove NSFW mark" : "Mark as NSFW", isPresented: $showingNsfwDialog) {
            Button("Cancel", role: .cancel) { showingNsfwDialog = false }
            Button("Continue") {
                if model.togglePostNsfw(target: target.getCode(), post: post) {
                    overlayModel.show("Post updated")
                }
                showingNsfwDialog = false
            }.keyboardShortcut(.defaultAction)
        } message: {
            Text(post.nsfw ? "Are you sure you want to mark your post as safe for work?"
                 : "Are you sure you want to mark your post as NSFW?")
        }
        .alert(post.spoiler ? "Remove spoiler mark" : "Mark as spoiler", isPresented: $showingSpoilerDialog) {
            Button("Cancel", role: .cancel) { showingSpoilerDialog = false }
            Button("Continue") {
                if model.togglePostSpoiler(target: target.getCode(), post: post) {
                    overlayModel.show("Post updated")
                }
                showingSpoilerDialog = false
            }.keyboardShortcut(.defaultAction)
        } message: {
            Text(post.spoiler ? "Are you sure you want to mark your post as spoiler free?"
                 : "Are you sure you want to mark your post for spoilers?")
        }
    }
}

struct PostRowMenu: View {
    @EnvironmentObject var model: Model
    @EnvironmentObject var overlayModel: MessageOverlayModel
    @StateObject var post: Post
    @Binding var target: CommunityOrUser
    @Binding var showingSaveDialog: Bool
    @Binding var showingDeleteDialog: Bool
    @Binding var showingNsfwDialog: Bool
    @Binding var showingSpoilerDialog: Bool
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
            ShareLink(item: URL(string: "https://reddit.com\(post.linkToThread.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)!)")!) {
                Label("Share post", systemImage: "square.and.arrow.up")
            }
            if post.contentType == .image {
                ShareLink(item: URL(string: post.imageLink!)!) {
                    Label("Share image", systemImage: "square.and.arrow.up.circle")
                }
                Button(action: { showingSaveDialog = true }) {
                    Label("Download image", systemImage: "arrow.down.square")
                }
            } else if post.contentType == .gallery {
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
            } else if post.contentType == .link && URL(string: post.externalLink!) != nil {
                ShareLink(item: URL(string: post.externalLink!)!) {
                    Label("Share link", systemImage: "square.and.arrow.up.circle")
                }
                Button(action: {
                    UIPasteboard.general.string = post.externalLink!
                    overlayModel.show("Copied to clipboard")
                }) {
                    Label("Copy link", systemImage: "list.clipboard")
                }
            }
            if post.userName == model.userName {
                Button(action: { showingNsfwDialog = true }) {
                    Label(post.nsfw ? "Remove NSFW mark" : "Mark as NSFW", systemImage: "18.circle")
                }
                Button(action: { showingSpoilerDialog = true }) {
                    Label(post.spoiler ? "Remove spoiler mark" : "Mark as spoiler", systemImage: "car.side.rear.open")
                }
                Button(role: .destructive, action: { showingDeleteDialog = true }, label: {
                    Label("Delete", systemImage: "trash")
                })
            }
        }
        .onAppear { newTarget = CommunityOrUser(community: nil, user: User(post.userName!)) }
    }
}
