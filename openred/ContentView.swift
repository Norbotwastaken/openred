//
//  ContentView.swift
//  openred
//
//  Created by Norbert Antal on 6/4/23.
//

import SwiftUI

struct ContentView: View {
    @State var communitiesSidebarVisible = false
    
    var body: some View {
        ZStack{
            TabView {
                PostsView(communitiesSidebarVisible: $communitiesSidebarVisible)
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
            CommunitiesSidebar(isShowing: $communitiesSidebarVisible)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
