//
//  PostContent.swift
//  openred
//
//  Created by Norbert Antal on 6/21/23.
//

import Foundation
import SwiftUI
import AVKit
import SwiftUIGIF

struct PostRowContent: View {
    @EnvironmentObject var model: Model
    @EnvironmentObject var popupViewModel: PopupViewModel
    @State var startLoadingGif: Bool = false
    @State var restorePostsPlaceholder: Bool = false
    @State var imageContainerSize: CGSize = CGSize(width: 1, height: 400)
    @State var showSafari: Bool = false
    @State var safariLink: URL?
    @State var isInternalPresented: Bool = false
    @State var internalIsPost: Bool = false
    @State var internalRestoreScrollPlaceholder: Bool = true
    @State var internalCommunityTarget: CommunityOrUser = CommunityOrUser(community: Community(""))
    @State var internalLoadPosts: Bool = true
    @State var internalItemInView: String = ""
    
    var post: Post
    var isPostOpen: Bool = false
    var enableCrosspostLink: Bool = false
    
    var body: some View {
        if post.contentType == .text {
            ZStack {
                if showSafari {
                    Spacer()
                        .fullScreenCover(isPresented: $showSafari, content: {
                            SFSafariViewWrapper(url: safariLink!)
                        })
                }
                Text(post.text!)
                    .font(.system(size: 15))
                    .padding(EdgeInsets(top: 0, leading: isPostOpen ? 0 : 10, bottom: 0,
                                        trailing: isPostOpen ? 0 : 10))
                    .frame(maxHeight: isPostOpen ? .infinity : 60, alignment: .leading)
                    .opacity(0.9)
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
        }
        if post.contentType == .image {
            ZStack {
                Rectangle()
                    .fill(Color(UIColor.systemGray5))
                    .frame(maxWidth: .infinity, maxHeight: 650)
                AsyncImage(url: URL(string: post.imagePreviewLink ?? "")) { image in
                    ZStack {
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity, maxHeight: 650)
                            .blur(radius: post.nsfw ? 30 : 0, opaque: true)
                            .onTapGesture {
                                popupViewModel.fullImageLink = post.imageLink
                                popupViewModel.contentType = post.contentType
                                popupViewModel.isShowing = true
                            }
                            .saveSize(in: $imageContainerSize)
                        if post.nsfw {
                            VStack {
                                Text("NSFW")
                                    .font(.system(size: 24))
                                    .fontWeight(.semibold)
                                    .opacity(0.8)
                                    .padding(EdgeInsets(top: 3, leading: 4, bottom: 3, trailing: 4))
                                    .background(Color(red: 1, green: 0, blue: 93 / 255).opacity(0.6))
                                    .cornerRadius(5)
                                Text("Sensitive content")
                                    .opacity(0.7)
                            }
                        }
                    }
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
                        .blur(radius: post.nsfw ? 20 : 10, opaque: true)
                    if !post.nsfw {
                        image.frame(maxWidth: .infinity, maxHeight: 140)
                    }
                    if post.nsfw {
                        VStack {
                            Text("NSFW")
                                .font(.system(size: 24))
                                .fontWeight(.semibold)
                                .opacity(0.8)
                                .padding(EdgeInsets(top: 3, leading: 4, bottom: 3, trailing: 4))
                                .background(Color(red: 1, green: 0, blue: 93 / 255).opacity(0.6))
                                .cornerRadius(5)
                            Text("Sensitive content")
                                .opacity(0.7)
                        }
                    } else {
                        Image(systemName: "play.fill")
                            .font(.system(size: 45))
                            .opacity(0.4)
                            .foregroundColor(Color.white)
                    }
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
                popupViewModel.videoLink = post.videoLink!
                popupViewModel.contentType = post.contentType
                popupViewModel.isShowing = true
            }
        } else if post.contentType == .gif {
            ZStack {
                ZStack {
                    Rectangle()
                        .fill(Color(UIColor.systemGray5))
                        .opacity(0.01)
                        .frame(height: imageContainerSize.height)
                        .scaledToFill()
                        .onTapGesture {
                            startLoadingGif = true
                        }
                    if post.nsfw && !startLoadingGif {
                        VStack {
                            Text("NSFW")
                                .font(.system(size: 24))
                                .fontWeight(.semibold)
                                .opacity(0.8)
                                .padding(EdgeInsets(top: 3, leading: 4, bottom: 3, trailing: 4))
                                .background(Color(red: 1, green: 0, blue: 93 / 255).opacity(0.6))
                                .cornerRadius(5)
                            Text("Tap to open content")
                                .opacity(0.7)
                        }
                        .onTapGesture {
                            startLoadingGif = true
                        }
                    } else {
                        ProgressView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onAppear(perform: {
                    if !post.nsfw {
                        startLoadingGif = true
                    }
                })
                if startLoadingGif && post.videoLink != nil {
                    GIFView(url: URL(string: post.videoLink!)!)
                        .frame(maxWidth: .infinity, maxHeight: 650)
                }
            }
        } else if post.contentType == .gallery {
            ZStack {
                Rectangle()
                    .fill(Color(UIColor.systemGray5))
                    .frame(maxWidth: .infinity, maxHeight: 650)
                AsyncImage(url: URL(string: post.gallery!.items[0].previewLink)) { image in
                    ZStack {
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity, maxHeight: 650)
                            .blur(radius: post.nsfw ? 30 : 0, opaque: true)
                            .onTapGesture {
                                popupViewModel.image = image
                                popupViewModel.contentType = post.contentType
                                popupViewModel.gallery = post.gallery
                                popupViewModel.isShowing = true
                            }
                            .saveSize(in: $imageContainerSize)
                        if post.nsfw {
                            VStack {
                                Text("NSFW")
                                    .font(.system(size: 24))
                                    .fontWeight(.semibold)
                                    .opacity(0.8)
                                    .padding(EdgeInsets(top: 3, leading: 4, bottom: 3, trailing: 4))
                                    .background(Color(red: 1, green: 0, blue: 93 / 255).opacity(0.6))
                                    .cornerRadius(5)
                                Text("Sensitive content")
                                    .opacity(0.7)
                            }
                        }
                    }
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
                    PostRowContent(post: crosspost)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    HStack {
                        HStack(spacing: 3) {
                            Image(systemName: "arrow.triangle.branch")
                                .rotationEffect(.degrees(90))
                            Text("r/" + crosspost.community!)
                        }
                        HStack(spacing: 2) {
                            Image(systemName: "arrow.up")
                            Text(formatScore(score:crosspost.score))
                        }
                        HStack(spacing: 2) {
                            Image(systemName: "text.bubble")
                            Text(formatScore(score: crosspost.commentCount))
                        }
                    }
                    .font(.system(size: 14))
                    .opacity(0.8)
                    .padding(EdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 5))
                    .frame(maxWidth: .infinity, maxHeight: 30, alignment: .leading)
                }
                .padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
                .overlay(
                    ZStack {
                        if enableCrosspostLink {
                            NavigationLink(destination: CommentsView(
                                restorePostsScroll: $restorePostsPlaceholder, link: crosspost.linkToThread
                            ), label: { EmptyView() })
                            .opacity(0)
                        }
                    }
                )
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
                            .blur(radius: post.nsfw ? 20 : 0, opaque: true)
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
                        Text(post.externalLinkDomain ?? "Open link")
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
                showSafari.toggle()
            }
            .fullScreenCover(isPresented: $showSafari, content: {
                SFSafariViewWrapper(url: URL(string: post.externalLink!)!)
            })
        }
    }
}
