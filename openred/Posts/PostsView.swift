//
//  ListView.swift
//  openred
//
//  Created by Norbert Antal on 6/6/23.
//

import SwiftUI
import AVKit

struct PostsView: View {
    @EnvironmentObject var model: Model
    @Binding var communitiesSidebarVisible: Bool
    
    var body: some View {
        ZStack {
            NavigationStack {
                List {
                    ForEach(model.posts) { post in
                        PostView(post: post)
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
            }
        }
    }
}

struct PostView: View {
    @EnvironmentObject var model: Model
//    @State var player = AVPlayer(url: URL(string: "https://i.imgur.com/A0uSYLF.mp4")!)
    @State private var showingPopover = false
    var post: Post
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(post.title)
                .font(.headline)
                .padding(EdgeInsets(top: 10, leading: 10, bottom: 0, trailing: 10))
                .fixedSize(horizontal: false, vertical: false)
            ZStack {
//                AsyncImage(url: URL(string: "https://i.imgur.com/cLUedH2.jpeg")) { image in
//                    image
//                        .resizable()
//                        .scaledToFill()
//                } placeholder: {
//                    ProgressView()
//                }
                
                AsyncImage(url: URL(string: "https://external-preview.redd.it/OHN1NDFwOWhqYzViMROWQp8u0aNhb9RRct3G8JqqU1tAu90RWyV40ipGUCP-.png?width=140&height=140&crop=140:140,smart&format=jpg&v=enabled&lthumb=true&s=0061202d36bc9e581fee91ccf8a9d432bfaaf521")) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(maxHeight: 140)
                } placeholder: {
                    ProgressView()
                }
                .onTapGesture {
                    showingPopover = true
                }
                .popover(isPresented: $showingPopover) {
                    Text("Your content here")
                        .font(.headline)
                        .padding()
                }
                
//                AnimatedGifView(url: Binding(get: { URL(string: "https://i.imgur.com/EM7f96Q.gif")! }, set: { _ in }))
                // https://i.imgur.com/EM7f96Q.gifv
                // https://i.imgur.com/a41akKA.mp4
                
//                VideoPlayer(player: AVPlayer(url: URL(string: "https://i.imgur.com/A0uSYLF.mp4")!))
//                    .aspectRatio(contentMode: .fill)
//                    .frame(maxWidth: .infinity, maxHeight: .infinity)
//                    .scaledToFill()
            }
            .frame(maxWidth: .infinity, maxHeight: 800)
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
            Rectangle()
                .fill(Color(UIColor.systemGray5).shadow(.inner(radius: 2, y: 1)).opacity(0.5))
                .frame(maxWidth: .infinity, maxHeight: 5)
        }
//        .frame(maxHeight: .infinity)
    }
}

extension PostView {
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
