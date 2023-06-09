//
//  ContentView.swift
//  openred
//
//  Created by Norbert Antal on 6/4/23.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
//            PostsAndCommunitiesView()
            PostsView()
                .tabItem {
                    Label("Feed", systemImage: "newspaper")
                }
            Text("Inbox")
                .tabItem {
                    Label("Inbox", systemImage: "message")
                }
            Text("Search")
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
            Text("Settings")
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
