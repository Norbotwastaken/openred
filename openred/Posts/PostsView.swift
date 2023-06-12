//
//  ListView.swift
//  openred
//
//  Created by Norbert Antal on 6/6/23.
//

import SwiftUI
import AVKit
import ExytePopupView

struct PostsView: View {
    @EnvironmentObject var model: Model
    @Binding var communitiesSidebarVisible: Bool
    @State var mediaPopupShowing = false
    
    @State var player = AVPlayer()
    
    var videoLink: String = "https://v.redd.it/8twxap1nxc5b1/HLSPlaylist.m3u8"
//    var videoLink: String = "https://i.imgur.com/a41akKA.mp4"
    // https://v.redd.it/8twxap1nxc5b1/HLSPlaylist.m3u8?a=1689099504%2COTc0YzQyZmRhZDhmZThlZDViYjc1MWFkYTBmZTEyOTgzYmMxN2IwZWNhZGMyOTliYTk2NjVjZWFmY2NkMmU5NA%3D%3D&v=1&f=sd
    
    var body: some View {
        ZStack {
            NavigationStack {
                List {
                    ForEach(model.posts) { post in
                        PostRow(mediaPopupShowing: $mediaPopupShowing, post: post)
                            .listRowInsets(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0))
                            .listRowSeparator(.hidden)
                    }
                }
//                .background(Color(UIColor.systemGray5))
                .listStyle(PlainListStyle())
                .navigationTitle(model.title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            communitiesSidebarVisible.toggle()
                            print("Left button tapped")
                        } label: {
                            Image(systemName: "chevron.left")
                            Text("Subreddits")
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        HStack {
                            SortMenu()
                            Button {
                                // Perform an action
                                print("Add Item Tapped")
                            } label: {
                                Image(systemName: "ellipsis")
                            }
                        }
                    }
                }
                .toolbarBackground(.visible, for: .navigationBar)
                .popup(isPresented: $mediaPopupShowing) {
                    ZStack {
                        VideoPlayer(player: player)
                            .onAppear() {
                                player = AVPlayer(url: URL(string: videoLink)!)
                                player.isMuted = true
                                player.play()
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        Image(systemName: "xmark")
                            .font(.system(size: 30))
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                            .foregroundColor(Color.white)
                            .opacity(0.6)
                            .padding(EdgeInsets(top: 8, leading: 22, bottom: 0, trailing: 0))
                            .onTapGesture {
                                mediaPopupShowing = false
                                player.pause()
                            }
                    }
                    } customize: {
                        $0.type(.floater(verticalPadding: 20, horizontalPadding: 0, useSafeAreaInset: false))
                            .position(.top)
                            .closeOnTap(false)
                            .backgroundColor(Color.black)
                            .appearFrom(.top).animation(.easeIn(duration: 0))
                            .isOpaque(true)
                            .dismissCallback({ player.pause() })
                    }
            }
        }
    }
}

struct PostRow: View {
    @EnvironmentObject var model: Model
    @Binding var mediaPopupShowing: Bool
    var post: Post
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(post.title)
                .font(.headline)
                .padding(EdgeInsets(top: 10, leading: 10, bottom: 0, trailing: 10))
                .fixedSize(horizontal: false, vertical: false)
            
            ZStack {
                Rectangle()
                    .fill(Color(UIColor.systemGray5))
                    .frame(maxWidth: .infinity, maxHeight: 650)
                AsyncImage(url: URL(string: "https://i.redd.it/erqky2za2i5b1.jpg")) { image in
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: 650)
                } placeholder: {
                    ProgressView()
                }
            }
//            VIDEO CONTENT:
//            AsyncImage(url: URL(string: "https://external-preview.redd.it/OHN1NDFwOWhqYzViMROWQp8u0aNhb9RRct3G8JqqU1tAu90RWyV40ipGUCP-.png?width=140&height=140&crop=140:140,smart&format=jpg&v=enabled&lthumb=true&s=0061202d36bc9e581fee91ccf8a9d432bfaaf521")) { image in
//                ZStack {
//                    image.resizable()
//                        .frame(maxWidth: .infinity, maxHeight: 140)
//                        .blur(radius: 10, opaque: true)
//                    image.frame(maxWidth: .infinity, maxHeight: 140)
//                    Image(systemName: "play.fill")
//                        .font(.system(size: 45))
//                        .opacity(0.4)
//                        .foregroundColor(Color.white)
//                }
//            } placeholder: {
//                ProgressView()
//            }
//            .onTapGesture {
//                mediaPopupShowing = true
//            }
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

extension PostRowFooter {
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
}

struct SortMenu: View {
    @EnvironmentObject var model: Model
    
    let topURLBase: String = "/top/?sort=top&t="
    let controversialURLBase: String = "/controversial/?sort=controversial&t="
    
    var body: some View {
        Menu {
            Button(action: {sortCommunity(sortModifier: "")}) {
                Label("Hot", systemImage: ViewModelAttributes.sortModifierIcons["hot"]!)
            }
            Menu {
                Button("Hour", action: { sortCommunity(sortModifier: topURLBase + "hour" )})
                Button("Day", action: { sortCommunity(sortModifier: topURLBase + "day" )})
                Button("Week", action: { sortCommunity(sortModifier: topURLBase + "week" )})
                Button("Month", action: { sortCommunity(sortModifier: topURLBase + "month" )})
                Button("Year", action: { sortCommunity(sortModifier: topURLBase + "year" )})
                Button("All Time", action: { sortCommunity(sortModifier: topURLBase + "all" )})
            } label: {
                Label("Top", systemImage: ViewModelAttributes.sortModifierIcons["top"]!)
            }
            Button(action: {sortCommunity(sortModifier: "/new" )}) {
                Label("New", systemImage: ViewModelAttributes.sortModifierIcons["new"]!)
            }
            Button(action: {sortCommunity(sortModifier: "/rising" )}) {
                Label("Rising", systemImage: ViewModelAttributes.sortModifierIcons["rising"]!)
            }
            Menu {
                Button("Hour", action: { sortCommunity(sortModifier: controversialURLBase + "hour" )})
                Button("Day", action: { sortCommunity(sortModifier: controversialURLBase + "day" )})
                Button("Week", action: { sortCommunity(sortModifier: controversialURLBase + "week" )})
                Button("Month", action: { sortCommunity(sortModifier: controversialURLBase + "month" )})
                Button("Year", action: { sortCommunity(sortModifier: controversialURLBase + "year" )})
                Button("All Time", action: { sortCommunity(sortModifier: controversialURLBase + "all" )})
            } label: {
                Label("Controversial", systemImage: ViewModelAttributes.sortModifierIcons["controversial"]!)
            }
        } label: {
            Label("Sort by", systemImage: model.selectedSortingIcon)
        }
    }
    
    func sortCommunity(sortModifier: String) {
        model.refreshWithSortModifier(sortModifier: sortModifier)
    }
}

//struct PostView_Previews: PreviewProvider {
//    static var previews: some View {
//        PostsView()
//    }
//}
