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
    
    var body: some View {
        VStack(alignment: .leading) {
            VStack {
                Text(post.title)
                    .font(.headline) +
                Text(post.flair != nil ? "  [" + post.flair! + "]" : "")
                    .foregroundColor(.secondary)
                    .font(.system(size: 12))
            }
            .fixedSize(horizontal: false, vertical: true)
            .padding(EdgeInsets(top: 8, leading: 10, bottom: 0, trailing: 10))
            .disabled(true)
            PostRowContent(post: post)
                .frame(maxWidth: .infinity, maxHeight: 650)
            PostRowFooter(post: post)
            Rectangle()
                .fill(Color(UIColor.systemGray5)
                    .shadow(.inner(radius: 2, y: 1)).opacity(0.5))
                .frame(maxWidth: .infinity, maxHeight: 5)
        }
    }
}

struct PostRowFooter: View {
    @EnvironmentObject var model: Model
    @ObservedObject var post: Post
    
    var body: some View {
        HStack {
            VStack(spacing: 8) {
                Text(getFooterLabel(post: post))
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .onTapGesture {
                        if post.community != nil {
                            model.loadCommunity(communityCode: post.community!)
                        } else {
                            // TODO: load user page
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
                        ForEach(post.awards.indices) { i in
                            if i < 3 {
                                AsyncImage(url: URL(string: post.awards[i].link)) { image in
                                    image.image?
                                        .resizable()
                                        .scaledToFill()
                                        .frame(maxWidth: 15, maxHeight: 15)
                                }
                            }
                        }
                        if post.getTotalAwardCount() > 0 {
                            Text(String(post.getTotalAwardCount()))
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
                PostRowMenu(post: post)
                Image(systemName: "arrow.up")
                    .foregroundColor(post.isUpvoted ? .upvoteOrange : .secondary)
                    .onTapGesture {
                        if model.toggleUpvotePost(post: post) == false {
                            // show login popup
                        }
                    }
                Image(systemName: "arrow.down")
                    .foregroundColor(post.isDownvoted ? .downvoteBlue : .secondary)
                    .onTapGesture {
                        if model.toggleDownvotePost(post: post) == false {
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
    
    private func getFooterLabel(post: Post) -> String {
        if let community = post.community {
            return community
        }
        return post.userName != nil ? "u/" + post.userName! : ""
    }
}

func formatScore(score: String) -> String {
    if var number = Int(score) {
        if number >= 1000 {
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
    @ObservedObject var post: Post
    
    var body: some View {
        Menu {
            Button(action: { model.toggleUpvotePost(post: post) }) {
                Label("Upvote", systemImage: "arrow.up")
            }
            Button(action: { model.toggleDownvotePost(post: post) }) {
                Label("Downvote", systemImage: "arrow.down")
            }
            Button(action: { model.toggleSavePost(post: post) }) {
                Label(post.isSaved ? "Undo Save" : "Save", systemImage: post.isSaved ? "bookmark.slash" : "bookmark")
            }
        } label: {
            ZStack {
                Spacer()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                Image(systemName: "ellipsis")
            }
            .frame(width: 20, height: 20)
        }
    }
}
