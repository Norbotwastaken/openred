//
//  ListView.swift
//  openred
//
//  Created by Norbert Antal on 6/6/23.
//

import SwiftUI

struct PostsView: View {
    @EnvironmentObject var model: Model
    @Binding var communitiesSidebarVisible: Bool
    
    var body: some View {
        ZStack {
            NavigationStack {
                List {
                    ForEach(model.posts) { post in
                        PostView(post: post)
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
                            Menu {
                                Button(Label("Hot", systemImage: "flame"), action: doNothing)
                                Button(Label("Top", systemImage: "arrow.up.to.line.compact")) {
                                    Button("Hour", action: doNothing)
                                    Button("Day", action: doNothing)
                                    Button("Week", action: doNothing)
                                    Button("Month", action: doNothing)
                                    Button("Year", action: doNothing)
                                    Button("All Time", action: doNothing)
                                }
                                Button(Label("New", systemImage: "clock.badge"), action: doNothing)
                                Button(Label("Rising", systemImage: "chart.line.uptrend.xyaxis"), action: doNothing)
                                Menu(Label("Controversial", systemImage: "arrow.right.and.line.vertical.and.arrow.left")) {
                                    Button("Hour", action: doNothing)
                                    Button("Day", action: doNothing)
                                    Button("Week", action: doNothing)
                                    Button("Month", action: doNothing)
                                    Button("Year", action: doNothing)
                                    Button("All Time", action: doNothing)
                                }
                            } label: {
                                Label("Sort by", systemImage: "arrow.up.arrow.down")
                            }
//                            Button {
//                                // Perform an action
//                                print("Add Item Tapped")
//                            } label: {
//                                Image(systemName: "arrow.up.arrow.down")
//                            }
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
    func doNothing() {}
}

struct PostView: View {
    var post: Post
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(post.title).font(.headline)
            
            Text(post.community).foregroundStyle(.secondary).lineLimit(1)
            Text(post.userName)
            Text(post.commentCount)
        }
    }
}

//struct PostView_Previews: PreviewProvider {
//    static var previews: some View {
//        PostsView()
//    }
//}
