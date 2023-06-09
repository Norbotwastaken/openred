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
    
    let redditBaseURL: String = "https://old.reddit.com"
    
    var document: Document?
    
    init() {
        self.title = ""
        self.document = nil
        browse()
        
        self.mainPageCommunities.append(Community("Home", link: redditBaseURL, iconName: "house.fill"))
        self.mainPageCommunities.append(Community("Popular Posts", link: redditBaseURL + "/r/popular", iconName: "chart.line.uptrend.xyaxis"))
        self.mainPageCommunities.append(Community("All Posts", link: redditBaseURL + "/r/all", iconName: "a.circle.fill"))
        self.userFunctionCommunities.append(Community("Saved", link: redditBaseURL + "/saved", iconName: "heart.text.square"))
        self.userFunctionCommunities.append(Community("Moderator Posts", link: redditBaseURL + "/mod", iconName: "shield"))
    }
    
    func browse() {
        Erik.visit(url: URL(string: redditBaseURL + "/r/all")! ) { object, error in
            if let doc = object {
                self.document = doc
                self.updateDocument(doc: doc)
            }
        }
    }
    
    func updateDocument(doc: Document) {
        self.title = doc.title!
        
        updateCommunitiesList(doc: doc)
        
        var i = 0
        for element in doc.querySelectorAll("#siteTable div.thing .entry") {
            let title = element.querySelector(".top-matter p.title a.title")?.text
            let community = element.querySelector(".top-matter .tagline .subreddit")?.text
            let commentCount = element.querySelector(".top-matter .buttons .comments")?.text
            let userName = element.querySelector(".top-matter .tagline .author")?.text
            let liveTimeStamp = "default-timestamp" // element.querySelector(".top-matter p.title a.title")?.text
            let linkToThread = element.querySelector(".top-matter .tagline .subreddit")?["href"]
            
            posts.append(Post(String(i), title: title ?? "no title for this post",
                              community: community ?? "community placeholder (Ad)",
                              commentCount: commentCount ?? "0 (Ad)",
                              userName: userName ?? "#user",
                              liveTimestamp: liveTimeStamp,
                              linkToThread: linkToThread ?? "no link available (Ad)"))
            i += 1
        }
    }
    
    func updateCommunitiesList(doc: Document) {
        var unsortedCommunities: [Community] = []
        for element in doc.querySelectorAll(".sr-list #sr-bar li a") {
            let communityLink = element["href"]
            if let communityName = element.text {
                unsortedCommunities
                    .append(Community(communityName, link: communityLink ?? "no link", iconName: nil))
            }
        }
        self.communities = unsortedCommunities
            .sorted { $0.name.lowercased() < $1.name.lowercased() }
    }
}
