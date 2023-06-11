//
//  Model.swift
//  openred
//
//  Created by Norbert Antal on 6/6/23.
//

import Foundation
import Erik

class Model: ObservableObject {
    @Published var posts: [Post] = []
    @Published var communities: [Community] = []
    @Published var mainPageCommunities: [Community] = []
    @Published var userFunctionCommunities: [Community] = []
    @Published var title: String
    @Published var selectedCommunityLink: String
    @Published var selectedSorting: String
    @Published var selectedSortingIcon: String
    
    let redditBaseURL: String = "https://old.reddit.com"
    
    init() {
        self.title = ""
        self.selectedCommunityLink = redditBaseURL + "/r/all"
        self.selectedSorting = ""
        self.selectedSortingIcon = ViewModelAttributes.sortModifierIcons[""]!
        load(initialURL: selectedCommunityLink)
    }
    
    func load(initialURL: String) {
        setAdditionalCommunities()
        Erik.visit(url: URL(string: initialURL)! ) { object, error in
            if let doc = object {
                self.updateTitle(doc: doc, defaultTitle: "")
                self.updatePosts(doc: doc)
                self.updateCommunitiesList(doc: doc)
            }
        }
    }
    
    func loadCommunity(community: Community) {
        self.selectedSorting = ""
        self.selectedSortingIcon = ViewModelAttributes.sortModifierIcons[selectedSorting]!
        self.selectedCommunityLink = community.link
        if selectedCommunityLink.hasSuffix("/") {
            selectedCommunityLink = String(selectedCommunityLink.dropLast())
        }
        self.posts = [] // prompt scroll reset to top
        Erik.visit(url: URL(string: selectedCommunityLink)! ) { object, error in
            if let doc = object {
                self.updateTitle(doc: doc, defaultTitle: community.name)
                self.updatePosts(doc: doc)
            }
        }
    }
    
    // 'communityCode' format is r/something
    func loadCommunity(communityCode: String) {
        self.selectedSorting = ""
        self.selectedSortingIcon = ViewModelAttributes.sortModifierIcons[selectedSorting]!
        self.selectedCommunityLink = redditBaseURL + "/" + communityCode
//        if selectedCommunityLink.hasSuffix("/") {
//            selectedCommunityLink = String(selectedCommunityLink.dropLast())
//        }
        self.posts = [] // prompt scroll reset to top
        Erik.visit(url: URL(string: selectedCommunityLink)! ) { object, error in
            if let doc = object {
                self.updateTitle(doc: doc, defaultTitle: communityCode.components(separatedBy: "/")[1])
                self.updatePosts(doc: doc)
            }
        }
    }
    
    func refreshWithSortModifier(sortModifier: String) {
        self.selectedSorting = sortModifier.components(separatedBy: "/")[1]
        self.selectedSortingIcon = ViewModelAttributes.sortModifierIcons[selectedSorting]!
        self.posts = [] // prompt scroll reset to top
        Erik.visit(url: URL(string: self.selectedCommunityLink + sortModifier)! ) { object, error in
            if let doc = object {
                self.updatePosts(doc: doc)
            }
        }
    }
    
    private func updateTitle(doc: Document, defaultTitle: String) {
        if let newTitle = doc.querySelector(".pagename.redditname a")?.text {
            self.title = newTitle.prefix(1).capitalized + String(newTitle.dropFirst())
        } else {
            self.title = defaultTitle
        }
    }
    
    private func updatePosts(doc: Document) {
        self.posts = []
        
        for element in doc.querySelectorAll("#siteTable div.thing:not(.promoted)") {
            let title = element.querySelector(".entry .top-matter p.title a.title")?.text
            let community = element.querySelector(".entry .top-matter .tagline .subreddit")?.text // r/something
            let commentCount = element["data-comments-count"]
            let userName = element.querySelector(".entry .top-matter .tagline .author")?.text
            var submittedAge = element.querySelector(".entry .tagline .live-timestamp")?.text
            let linkToThread = element["data-permalink"]
            let score = element["data-score"]
            // data-is-gallery="true" Tag for galleries
            
            // Transform '3 hours ago' into '3h'
            if let postAgeSections = submittedAge?.components(separatedBy: " ") {
                submittedAge = postAgeSections[0] + postAgeSections[1].prefix(1)
            }
            
            posts.append(Post(linkToThread!, title: title ?? "no title for this post",
                              community: community,
                              commentCount: commentCount ?? "0",
                              userName: userName ?? "",
                              submittedAge: submittedAge ?? "",
                              score: score ?? "0"))
        }
    }
    
    private func updateCommunitiesList(doc: Document) {
        var unsortedCommunities: [Community] = []
        for element in doc.querySelectorAll(".sr-list #sr-bar li a") {
            let communityLink = element["href"]
            if let communityName = element.text {
                unsortedCommunities.append(Community(communityName,link: communityLink ?? "no link",
                                                     iconName: nil, isMultiCommunity: false))
            }
        }
        self.communities = unsortedCommunities
            .sorted { $0.name.lowercased() < $1.name.lowercased() }
    }
    
    func setAdditionalCommunities() {
        self.mainPageCommunities.append(Community("Home", link: redditBaseURL,
                                                  iconName: "house.fill", isMultiCommunity: true))
        self.mainPageCommunities.append(Community("Popular Posts", link: redditBaseURL + "/r/popular",
                                                  iconName: "chart.line.uptrend.xyaxis.circle.fill", isMultiCommunity: true))
        self.mainPageCommunities.append(Community("All Posts", link: redditBaseURL + "/r/all",
                                                  iconName: "a.circle.fill", isMultiCommunity: true))
        self.userFunctionCommunities.append(Community("Saved", link: redditBaseURL + "/saved",
                                                      iconName: "heart.text.square", isMultiCommunity: true))
        self.userFunctionCommunities.append(Community("Moderator Posts", link: redditBaseURL + "/mod",
                                                      iconName: "shield", isMultiCommunity: true))
    }
}

struct ViewModelAttributes {
    static var sortModifierIcons = [
        "" : "arrow.up.arrow.down",
        "hot" : "flame",
        "top" : "arrow.up.to.line.compact",
        "new" : "clock.badge",
        "rising" : "chart.line.uptrend.xyaxis",
        "controversial" : "arrow.right.and.line.vertical.and.arrow.left"
    ]
}
