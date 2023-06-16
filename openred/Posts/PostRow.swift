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
            Text(post.title)
                .font(.headline)
                .padding(EdgeInsets(top: 10, leading: 10, bottom: 0, trailing: 10))
                .fixedSize(horizontal: false, vertical: false)
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
                        .font(.system(size: 15))
                        .fontWeight(.semibold)
                        .fixedSize(horizontal: false, vertical: false)
                    HStack {
                        Text(crosspost.score).font(.system(size: 15))
                        HStack {
                            Image(systemName: "text.bubble").font(.system(size: 15))
                            Text(formatScore(score: crosspost.commentCount)).font(.system(size: 15))
                        }
                        Text(crosspost.communityName).font(.system(size: 15))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                }
                .padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
            }
            .padding(SwiftUI.EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
        }
    }
}

struct PostRowFooter: View {
    @EnvironmentObject var model: Model
    var post: Post
    
    var body: some View {
        HStack {
            VStack {
                if let community = post.community {
                    Text(community)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .onTapGesture {
                            model.loadCommunity(communityCode: community)
                        }
                } else {
                    Spacer().frame(height: 15)
                }
                HStack {
                    HStack {
                        Image(systemName: "arrow.up").font(.system(size: 15))
                        Text(formatScore(score: post.score)).font(.system(size: 15))
                    }
                    HStack {
                        Image(systemName: "text.bubble").font(.system(size: 15))
                        Text(formatScore(score: post.commentCount)).font(.system(size: 15))
                    }
                    HStack {
                        Image(systemName: "clock").font(.system(size: 15))
                        Text(post.submittedAge).font(.system(size: 15))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: 15, alignment: .leading)
            }
            .frame(minWidth: 190, maxWidth: .infinity, alignment: .leading)
            HStack {
                // TODO: Add menu
                Button(action: {}) {
                    Label("", systemImage: "arrow.up")
                }.foregroundColor(Color(UIColor.systemGray))
                Button(action: {}) {
                    Label("", systemImage: "arrow.down")
                }.foregroundColor(Color(UIColor.systemGray))
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .frame(maxWidth: .infinity)
        .padding(EdgeInsets(top: 0, leading: 10, bottom: 10, trailing: 10))
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
