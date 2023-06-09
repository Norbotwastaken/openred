//
//  ListView.swift
//  openred
//
//  Created by Norbert Antal on 6/6/23.
//

import SwiftUI

struct PostsView: View {
    @EnvironmentObject var model: Model
    
    @State var presentSideMenu = false
    
    var body: some View {
        NavigationStack {
            ZStack {
//                if !self.presentSideMenu {
                    List {
                        ForEach(model.posts) { post in
                            PostView(post: post)
                        }
                    }
                    .navigationTitle(model.title)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button {
                                // Perform an action
                                print("Add Item Tapped")
                            } label: {
                                Image(systemName: "ellipsis")
                            }
                        }
                        
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button {
                                presentSideMenu.toggle()
                                print("Left button tapped")
                            } label: {
                                Image(systemName: "chevron.left")
                                Text("Subreddits")
                            }
                        }
                    }
//                }
                SideMenu(isShowing: $presentSideMenu)
            }
        }
    }
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

struct PostView_Previews: PreviewProvider {
    static var previews: some View {
        PostsView()
    }
}
