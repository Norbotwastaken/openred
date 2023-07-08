//
//  Comments.swift
//  openred
//
//  Created by Norbert Antal on 6/18/23.
//

import Erik
import Kanna
import WebKit
import SwiftUI

class CommentsModel: ObservableObject {
    var browser: Erik = Erik()
    var document: Document? = nil
    let redditBaseURL: String = "https://old.reddit.com"
    var currentLink: String = "" // /r/something/comments
    var jsonLoader: JSONDataLoader
    
    @Published var comments: [Comment] = []
    @Published var commentsCollapsed: [String:Bool] = [:]
    @Published var title: String = ""
    @Published var commentCount: String = ""
    @Published var selectedSorting: String = ""
    
    let webView: WKWebView
    let userSessionManager: UserSessionManager
    
    init(userSessionManager: UserSessionManager) {
        self.webView = userSessionManager.getWebView()
        userSessionManager.loadLastLoggedInUser(webView: self.webView)
        self.jsonLoader = JSONDataLoader()
        self.browser = Erik(webView: webView)
        self.userSessionManager = userSessionManager
//        UserSessionManager().loadLastLoggedInUser(webView: webView)
//        webView
    }
    
    func loadComments(linkToThread: String, sortBy: String? = "") {
        if currentLink == linkToThread && sortBy == "" {
            return
            // returning to the same post comments again (may not be needed)
        }
        self.currentLink = linkToThread
        self.selectedSorting = ""
        self.comments = []
        
        var components = URLComponents()
        components.scheme = "https"
        components.host = "old.reddit.com"
        components.path = linkToThread.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)!
        components.queryItems = []
        
        if sortBy != nil {
            self.selectedSorting = sortBy!
            components.queryItems?.append(URLQueryItem(name: "sort", value: sortBy!))
        }
        
        browser.visit(url: components.url!) { object, error in
            if let doc = object {
                self.document = doc
                self.title = doc.title!
                // TODO: get comment count some other way
                self.commentCount = doc.querySelector("#siteTable .thing")!["data-comments-count"]!
            }
        }
        
        components.path = components.path + "/.json"
        jsonLoader.loadComments(url: components.url!) { (comments, error) in
            DispatchQueue.main.async {
                if let comments = comments {
                    for comment in comments {
                        self.comments.append(comment)
                    }
                }
            }
        }
    }
    
    func openCommentsPage(linkToThread: String, withSortModifier: String = "") {
        if currentLink == linkToThread && withSortModifier == "" {
            return
        }
        self.currentLink = linkToThread
//        self.selectedSortingIcon = CommentsModelAttributes.sortModifierIcons[""]!
        self.selectedSorting = ""
        self.comments = []
        self.commentsCollapsed = [:]
        var commentsByID: [String: CommentX] = [:]
        jsonLoader.getData(url: redditBaseURL + linkToThread.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)! + ".json" + withSortModifier)
        browser.visit(url: URL(string: redditBaseURL + linkToThread.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)! + withSortModifier)!) { object, error in
            if let doc = object {
                self.document = doc
                self.title = doc.title!
                self.commentCount = doc.querySelector("#siteTable .thing")!["data-comments-count"]!
                for commentElement in doc.querySelectorAll(".commentarea .thing.comment:not(.deleted)") {
                    let id: String = commentElement.querySelector(".parent a")!["name"]! // jokhk6z
                    let user: String? = commentElement["data-author"]
                    let content: String? = self.jsonLoader.content[id]
                    if content == nil {
                        // an element which is present on website but not in json yet. (new)
                        continue
                    }
                    let age: String? = commentElement.querySelector(".tagline time")?.text
                    let score: String? = commentElement.querySelector(".tagline .score")?["title"]
                    
                    let isUpvoted = commentElement.querySelector(">div.midcol.likes") != nil
                    let isDownvoted = commentElement.querySelector(">div.midcol.dislikes") != nil
                    let isSaved = commentElement.className!.contains("saved")
                    var parent: String? = commentElement.querySelector(".buttons li a[data-event-action=\"parent\"]")?["href"] // #jokhk6z
                    var depth: Int = 0
                    if parent != nil {
                        parent = String(parent!.dropFirst(1))
                        if parent == id {
                            // top level comment with sub comments
                            parent = nil
                        } else {
                            // child comment
                            if let parentComment = commentsByID[parent!] {
                                depth = parentComment.depth + 1
                            } else {
                                // parent is a deleted comment, skip children of deleted
                                continue
                            }
                        }
                    } else {
                        // top level comment without sub comments
                        parent = nil
                    }
                    
                    let comment = CommentX(id: id, depth: depth, score: score, content: content,
                                                 user: user, age: age, parent: parent, isUpvoted: isUpvoted,
                                          isDownvoted: isDownvoted, isSaved: isSaved)
                    commentsByID[id] = comment
                    if parent != nil {
                        comment.allParents = self.findAllParents(firstParent: parent!, comments: commentsByID)
                    }
                    self.commentsCollapsed[id] = false
//                    self.comments.append(comment)
                }
            }
        }
    }
    
    private func findAllParents(firstParent: String, comments: [String: CommentX]) -> [String] {
        var allParents: [String] = [firstParent]
        var currentParentId: String? = firstParent
        var hasNextParent = true
        while (hasNextParent) {
            currentParentId = comments[currentParentId!]!.parent
            if currentParentId != nil {
                allParents.append(currentParentId!)
            } else {
                hasNextParent = false
            }
        }
        return allParents
    }
    
    func refreshWithSortModifier(sortModifier: String) {
        // sortModifier format: "new"
        var baseThreadLink = self.currentLink
        self.openCommentsPage(linkToThread: currentLink, withSortModifier: "?sort=" + sortModifier)
        self.selectedSorting = sortModifier
//        self.selectedSortingIcon = CommentsModelAttributes.sortModifierIcons[sortModifier]!
        self.currentLink = baseThreadLink
    }
    
    func toggleUpvoteComment(comment: Comment) -> Bool {
        if userSessionManager.userName == nil {
            return false
        }
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
        if userSessionManager.userName == nil {
            return false
        }
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
    
    func toggleSaveComment(comment: Comment) -> Bool {
        if userSessionManager.userName == nil {
            return false
        }
        if let saveButton = document?.querySelectorAll(".sitetable div.thing[id=\"thing_t1_" + comment.id + "\"] .buttons .save-button a").first {
            saveButton.click()
            comment.isSaved.toggle()
        }
        return true
    }
    
    var selectedSortingIcon: String {
        CommentsModelAttributes.sortModifierIcons[selectedSorting]!
    }
}

class CommentX: Identifiable, ObservableObject {
    var id: String
    var depth: Int
    var score: String?
    var content: LocalizedStringKey?
    var user: String?
    var age: String?
    var parent: String?
    var allParents: [String]
    @Published var isUpvoted: Bool
    @Published var isDownvoted: Bool
    @Published var isSaved: Bool
    
    init(id: String, depth: Int, score: String?, content: String?, user: String?,
         age: String?, parent: String?, isUpvoted: Bool, isDownvoted: Bool, isSaved: Bool) {
        self.id = id
        self.depth = depth
        self.score = score
        self.content = LocalizedStringKey(content ?? "")
        self.user = user
        self.age = age
        self.parent = parent
        self.allParents = []
        self.isUpvoted = isUpvoted
        self.isDownvoted = isDownvoted
        self.isSaved = isSaved
    }
}

struct CommentsModelAttributes {
    static var sortModifierIcons = [
        "" : "arrow.up.arrow.down", // "best"
        "confidence" : "arrow.up.arrow.down", // "best"
        "top" : "arrow.up.to.line.compact",
        "new" : "clock.badge",
        "old" : "clock.arrow.circlepath",
        "qa" : "bubble.left.and.bubble.right",
        "controversial" : "arrow.right.and.line.vertical.and.arrow.left"
    ]
}
