//
//  PostsView.swift
//  openred
//
//  Created by Norbert Antal on 6/6/23.
//

import SwiftUI
import AVKit

struct PostsView: View {
    @EnvironmentObject var model: Model
    @Binding var sidebarOffset: CGSize
    @Binding var mediaPopupShowing: Bool
    @Binding var popupContentType: ContentType
    @Binding var mediaPopupImage: Image?
    @Binding var videoLink: String?
    @Binding var player: AVPlayer
    
    var body: some View {
        ZStack {
            NavigationStack {
                List {
                    ForEach(model.posts) { post in
                        PostRow(mediaPopupShowing: $mediaPopupShowing, mediaPopupImage: $mediaPopupImage,
                                popupContentType: $popupContentType, videoLink: $videoLink, post: post)
                            .listRowInsets(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0))
                            .listRowSeparator(.hidden)
                    }
                }
                .listStyle(PlainListStyle())
                .navigationTitle(model.title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            sidebarOffset.width = -1
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
