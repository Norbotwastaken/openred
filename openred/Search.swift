//
//  Search.swift
//  openred
//
//  Created by Norbert Antal on 6/25/23.
//

import SwiftUI

struct SearchView: View {
    @EnvironmentObject var model: Model
    @Binding var tabSelection: Int
    @Binding var showPosts: Bool
    @Binding var target: CommunityOrUser
    @State private var communityName: String = ""
    @FocusState private var isFieldFocused: Bool
    
    var body: some View {
        VStack {
            TextField("Subreddit", text: $communityName)
                .textFieldStyle(.roundedBorder)
                .focused($isFieldFocused)
                .textFieldStyle(.roundedBorder)
//                .preferredColorScheme(.dark)
//                .colorInvert()
                .frame(alignment: .top)
                .padding(EdgeInsets(top: 10, leading: 45, bottom: 0, trailing: 45))
                .onTapGesture {} // override other onTap
                .onSubmit {
//                    showPosts = false
                    let community = CommunityOrUser(community: Community(communityName, isMultiCommunity: ["all", "popular", "saved", "mod", ""]
                        .contains(communityName.lowercased())))
                    model.resetPagesTo(target: community)
                    model.loadCommunity(community: community)
                    target = community
                    tabSelection = 1
                    showPosts = true
                }
                .frame(alignment: .top)
                .padding(EdgeInsets(top: 50, leading: 0, bottom: 0, trailing: 0))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color(UIColor.systemGray6))
        .onTapGesture {
            isFieldFocused = false
        }
    }
}
