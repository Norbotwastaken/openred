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
    @Published var title: String
    var document: Document?
    
    init() {
        self.title = "the default title"
        self.document = nil
        browse()
    }
    
    func browse() {
        Erik.visit(url: URL(string: "https://old.reddit.com/r/all")! ) { object, error in
            if let doc = object {
                self.document = doc
                self.updateDocument(doc: doc)
            }
        }
    }
    
    func updateDocument(doc: Document) {
        self.title = doc.title!
        
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
}
