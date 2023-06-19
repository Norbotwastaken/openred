//
//  Comments.swift
//  openred
//
//  Created by Norbert Antal on 6/18/23.
//

import Erik
import Kanna
import WebKit
import RichText

class CommentsModel: ObservableObject {
    var browser: Erik = Erik()
    var document: Document? = nil
    let redditBaseURL: String = "https://old.reddit.com"
    var currentLink: String = "" // /r/something/comments
    
    @Published var comments: [Comment] = []
    @Published var commentsCollapsed: [String:Bool] = [:]
    @Published var title: String = ""
    @Published var commentCount: String = ""
    
    let webView: WKWebView
    
    init(webView: WKWebView) {
        self.webView = webView
        self.browser = Erik(webView: webView)
    }
    
    init() {
        self.webView = WKWebView()
        self.browser = Erik(webView: webView)
        UserSessionManager().loadLastLoggedInUser(webView: webView)
    }
    
    func openCommentsPage(linkToThread: String) {
        if currentLink == linkToThread {
            return
        }
        self.currentLink = linkToThread
        self.comments = []
        self.commentsCollapsed = [:]
        var commentsByID: [String: Comment] = [:]
        browser.visit(url: URL(string: redditBaseURL + linkToThread)!) { object, error in
            if let doc = object {
                self.title = doc.title!
                self.commentCount = doc.querySelector("#siteTable .thing")!["data-comments-count"]!
                for commentElement in doc.querySelectorAll(".commentarea .thing.comment") {
                    let id: String = commentElement.querySelector(".parent a")!["name"]! // jokhk6z
                    let user: String? = commentElement["data-author"]
                    let content: String? = commentElement.querySelector(".usertext-body .md")?.innerHTML
                    let age: String? = commentElement.querySelector(".tagline time")?.text
                    let score: String? = commentElement.querySelector(".tagline .score")?["title"]
                    
                    let isUpvoted = commentElement.querySelector(">div.midcol.likes") != nil
                    let isDownvoted = commentElement.querySelector(">div.midcol.dislikes") != nil
                    var parent: String? = commentElement.querySelector(".buttons li a[data-event-action=\"parent\"]")?["href"] // #jokhk6z
                    var depth: Int = 0
                    if parent != nil {
                        parent = String(parent!.dropFirst(1))
                        if parent == id {
                            // top level comment with sub comments
                            parent = nil
                        } else {
                            // child comment
                            depth = commentsByID[parent!]!.depth + 1
                        }
                    } else {
                        // top level comment without sub comments
                        parent = nil
                    }
                    
                    let comment = Comment(id: id, depth: depth, score: score, content: content,
                                                 user: user, age: age, parent: parent, isUpvoted: isUpvoted,
                                          isDownvoted: isDownvoted)
                    commentsByID[id] = comment
                    if parent != nil {
                        comment.allParents = self.findAllParents(firstParent: parent!, comments: commentsByID)
                    }
                    self.commentsCollapsed[id] = false
                    self.comments.append(comment)
                }
            }
        }
    }
    
    private func findAllParents(firstParent: String, comments: [String: Comment]) -> [String] {
        var allParents: [String] = [firstParent]
        var currentParentId: String? = firstParent
        var hasNextParent = true
        while (hasNextParent) {
//            if comments.keys.contains(currentParentId!) {
                currentParentId = comments[currentParentId!]!.parent
                if currentParentId != nil {
                    allParents.append(currentParentId!)
                } else {
                    hasNextParent = false
                }
//            } else {
//                hasNextParent = false
//            }
        }
        return allParents
    }
    
    func toggleUpvoteComment(comment: Comment) -> Bool {
//        if userName == nil {
//            return false
//        }
        let selectorModifier = comment.isUpvoted ? "mod" : ""
        if let upvoteButton = document?.querySelectorAll(".sitetable div.thing[id=\"thing_t1_" + comment.id + "\"] div.arrow.up" + selectorModifier).first {
            upvoteButton.click()
            comment.isUpvoted.toggle()
            comment.isDownvoted = false
            browser.currentContent { (obj, err) -> Void in
                if let document = obj {
                    self.document = document
                }
            }
        }
        return true
    }
    
    func toggleDownvoteComment(comment: Comment) -> Bool {
//        if userName == nil {
//            return false
//        }
        let selectorModifier = comment.isDownvoted ? "mod" : ""
        if let downButton = document?.querySelectorAll(".sitetable div.thing[id=\"thing_t1_" + comment.id + "\"] div.arrow.down" + selectorModifier).first {
            downButton.click()
            comment.isDownvoted.toggle()
            comment.isUpvoted = false
            browser.currentContent { (obj, err) -> Void in
                if let document = obj {
                    self.document = document
                }
            }
        }
        return true
    }
}

class Comment: Identifiable, ObservableObject {
    var id: String
    var depth: Int
    var score: String?
    var content: String?
    var user: String?
    var age: String?
    var parent: String?
    var allParents: [String]
    @Published var isUpvoted: Bool
    @Published var isDownvoted: Bool
    
    init(id: String, depth: Int, score: String?, content: String?, user: String?,
         age: String?, parent: String?, isUpvoted: Bool, isDownvoted: Bool) {
        self.id = id
        self.depth = depth
        self.score = score
        self.content = content
        self.user = user
        self.age = age
        self.parent = parent
        self.allParents = []
        self.isUpvoted = isUpvoted
        self.isDownvoted = isDownvoted
    }
}
