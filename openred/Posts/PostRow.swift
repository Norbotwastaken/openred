//
//  PostRow.swift
//  openred
//
//  Created by Norbert Antal on 6/12/23.
//

import Foundation
import SwiftUI
import AVKit
import SwiftUIGIF

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

struct PostRowContent: View {
    @EnvironmentObject var model: Model
    @EnvironmentObject var popupViewModel: PopupViewModel
    @State var startLoadingGif: Bool = false
    @State var imageContainerSize: CGSize = CGSize(width: 1, height: 400)
    var post: Post
    
    var body: some View {
        if post.contentType == .image {
            ZStack {
                Rectangle()
                    .fill(Color(UIColor.systemGray5))
                    .frame(maxWidth: .infinity, maxHeight: 650)
                AsyncImage(url: URL(string: post.mediaLink ?? "")) { image in
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: 650)
                        .onTapGesture {
                            popupViewModel.image = image
                            popupViewModel.contentType = post.contentType
                            popupViewModel.isShowing = true
                        }
                        .saveSize(in: $imageContainerSize)
                } placeholder: {
                    ZStack {
                        Rectangle()
                            .fill(Color(UIColor.systemGray5))
                            .frame(height: imageContainerSize.height)
                            .scaledToFill()
                        Image(systemName: "photo")
                            .font(.system(size: 30))
                            .foregroundColor(Color.white)
                            .opacity(0.8)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        else if post.contentType == .video {
            AsyncImage(url: URL(string: post.thumbnailLink ?? "")) { image in
                ZStack {
                    image.resizable()
                        .frame(maxWidth: .infinity, maxHeight: 140)
                        .blur(radius: 10, opaque: true)
                    image.frame(maxWidth: .infinity, maxHeight: 140)
                    Image(systemName: "play.fill")
                        .font(.system(size: 45))
                        .opacity(0.4)
                        .foregroundColor(Color.white)
                    Text("VIDEO")
                        .font(.system(size: 15))
                        .fontWeight(.semibold)
                        .opacity(0.6)
                        .padding(EdgeInsets(top: 3, leading: 4, bottom: 3, trailing: 4))
                        .background(.red.opacity(0.5))
                        .cornerRadius(5)
                        .padding(EdgeInsets(top: 10, leading: 0, bottom: 0, trailing: 10))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } placeholder: {
                ZStack {
                    Rectangle()
                        .fill(Color(UIColor.systemGray5))
                        .frame(height: 140)
                        .scaledToFill()
                    Image(systemName: "video")
                        .font(.system(size: 30))
                        .foregroundColor(Color.white)
                        .opacity(0.8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .onTapGesture {
                popupViewModel.videoLink = post.mediaLink!
                popupViewModel.contentType = post.contentType
                popupViewModel.isShowing = true
            }
        } else if post.contentType == .gif {
            ZStack {
                ZStack {
                    Rectangle()
                        .fill(Color(UIColor.systemGray5))
                        .opacity(0)
                        .frame(height: imageContainerSize.height)
                        .scaledToFill()
                    ProgressView()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onAppear(perform: { startLoadingGif = true })
                if startLoadingGif {
                    GIFView(url: URL(string: post.mediaLink ?? "")!)
                        .frame(maxWidth: .infinity, maxHeight: 650)
                }
            }
        } else if post.contentType == .gallery {
            ZStack {
                Rectangle()
                    .fill(Color(UIColor.systemGray5))
                    .frame(maxWidth: .infinity, maxHeight: 650)
                AsyncImage(url: URL(string: post.gallery!.items[0].previewLink)) { image in
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: 650)
                        .onTapGesture {
                            popupViewModel.image = image
                            popupViewModel.contentType = post.contentType
                            popupViewModel.gallery = post.gallery
                            popupViewModel.isShowing = true
                        }
                        .saveSize(in: $imageContainerSize)
                } placeholder: {
                    ZStack {
                        Rectangle()
                            .fill(Color(UIColor.systemGray5))
                            .frame(height: imageContainerSize.height)
                            .scaledToFill()
                        Image(systemName: "photo")
                            .font(.system(size: 30))
                            .foregroundColor(Color.white)
                            .opacity(0.8)
                    }
                    .onTapGesture {
                        popupViewModel.contentType = post.contentType
                        popupViewModel.gallery = post.gallery
                        popupViewModel.isShowing = true
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                Text("ALBUM")
                    .font(.system(size: 15))
                    .fontWeight(.semibold)
                    .opacity(0.7)
                    .padding(EdgeInsets(top: 3, leading: 4, bottom: 3, trailing: 4))
                    .background(.green.opacity(0.4))
                    .cornerRadius(5)
                    .padding(EdgeInsets(top: 10, leading: 0, bottom: 0, trailing: 10))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            }
        } else if post.contentType == .crosspost {
            let crosspost = post.crosspost!
            ZStack {
                Rectangle()
                    .fill(Color(UIColor.systemGray6))
                    .cornerRadius(10)
                VStack {
                    Text(crosspost.title)
                        .font(.system(size: 14))
                        .fontWeight(.semibold)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(EdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 5))
                    HStack {
                        HStack(spacing: 3) {
                            Image(systemName: "arrow.triangle.branch")
                                .rotationEffect(.degrees(90))
                            Text(crosspost.communityName)
                        }
                        HStack(spacing: 2) {
                            Image(systemName: "arrow.up")
                            Text(crosspost.score)
                        }
                        HStack(spacing: 2) {
                            Image(systemName: "text.bubble")
                            Text(formatScore(score: crosspost.commentCount))
                        }
                    }
                    .font(.system(size: 14))
                    .opacity(0.8)
                    .padding(EdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 5))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                }
                .padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
            }
            .padding(SwiftUI.EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
        } else if post.contentType == .link {
            ZStack {
                Rectangle()
                    .fill(Color(UIColor.systemGray6))
                    .cornerRadius(10)
                HStack {
                    AsyncImage(url: URL(string: post.thumbnailLink ?? "")) { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .roundedCorner(10, corners: [.topLeft, .bottomLeft])
                            .frame(maxWidth: 140, maxHeight: 140, alignment: .leading)
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
                        .frame(maxWidth: 90, maxHeight: 140, alignment: .leading)
                    }
                    VStack(spacing: 10) {
                        Text("Open link")
                            .font(.system(size: 16))
                            .foregroundStyle(.secondary)
                            .fontWeight(.semibold)
                            .padding(SwiftUI.EdgeInsets(top: 10, leading: 0, bottom: 0, trailing: 0))
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                        Text(post.externalLink!)
                            .font(.system(size: 13))
                            .fontWeight(.thin)
                            .fixedSize(horizontal: false, vertical: false)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                            .padding(SwiftUI.EdgeInsets(top: 0, leading: 0, bottom: 10, trailing: 0))
                    }
                    .frame(maxWidth: .infinity, maxHeight: 140, alignment: .topLeading)
                }
                .frame(maxWidth: .infinity, maxHeight: 140, alignment: .leading)
            }
            .padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
            .onTapGesture {
                UIApplication.shared.open(URL(string: post.externalLink!)!)
            }
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
                        Text(post.submittedAge)
                    }
                    HStack(spacing: 3) {
                        // TODO: limit to 4
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
                Image(systemName: "ellipsis")
                    .foregroundStyle(.secondary)
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
