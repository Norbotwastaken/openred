//
//  PostsView.swift
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
    @State var popupContentType: ContentType = .link
    @State var mediaPopupImage: Image?
    @State var videoLink: String?
    
    @State var player = AVPlayer()
    
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
//                .popup(isPresented: $mediaPopupShowing) {
//                    MediaPopupContent(mediaPopupShowing: $mediaPopupShowing, mediaPopupImage: $mediaPopupImage,
//                                      videoLink: $videoLink, contentType: $popupContentType, player: $player)
//                    } customize: {
//                        $0.type(.floater(verticalPadding: 20, horizontalPadding: 0, useSafeAreaInset: false))
//                            .position(.top)
//                            .closeOnTap(false)
//                            .backgroundColor(Color.black)
//                            .appearFrom(.top).animation(.easeIn(duration: 0))
//                            .isOpaque(true)
//                            .dismissCallback({ player.pause() })
//                    }
            }
            if mediaPopupShowing {
                MediaPopupContent(mediaPopupShowing: $mediaPopupShowing, mediaPopupImage: $mediaPopupImage,
                                  videoLink: $videoLink, contentType: $popupContentType, player: $player)
                .gesture(DragGesture(minimumDistance: 3.0, coordinateSpace: .local)
                    .onEnded { value in
                        print(value.translation)
                        switch(value.translation.width, value.translation.height) {
                        case (...0, -30...30): print("left swipe")
                        case (0..., -30...30): print("right swipe")
                        case (-100...100, ...0): dismissPopup() // up swipe
                        case (-100...100, 0...): dismissPopup() // down swipe
                        default: print("no clue")
                        }
                    }
                )
            }
        }
    }
    private func dismissPopup() {
        player.pause()
        mediaPopupShowing = false
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
