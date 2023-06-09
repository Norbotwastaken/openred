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
                .listStyle(PlainListStyle())
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
                            communitiesSidebarVisible.toggle()
                            print("Left button tapped")
                        } label: {
                            Image(systemName: "chevron.left")
                            Text("Subreddits")
                        }
                    }
                }
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

//struct PostView_Previews: PreviewProvider {
//    static var previews: some View {
//        PostsView()
//    }
//}
