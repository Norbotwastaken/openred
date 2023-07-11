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
                // Expand first layer of collapsed comments (DOM needs refreshing)
                for expandButton in doc.querySelectorAll(".thing.collapsed .expand") {
                    expandButton.click()
                }
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
    
    func sendReply(parent: Comment?, content: String) -> Bool {
        if userSessionManager.userName == nil {
            return false
        }
        browser.currentContent { (obj, err) -> Void in
            self.document = obj
            if parent != nil {
                if let replyButton = self.document!.querySelectorAll(".sitetable div.thing[id=\"thing_t1_" + parent!.id + "\"]>.entry .buttons .reply-button a").first {
                    replyButton.click()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        self.browser.currentContent { (obj, err) -> Void in
                            self.document = obj
//                            if let input = self.document?.querySelectorAll(".sitetable div.thing[id=\"thing_t1_" + parent!.id + "\"] .usertext-edit textarea").last {
                                let stub = "document.getElementById(\"commentreply_t1_" + parent!.id +
                                "\").getElementsByClassName(\"usertext-edit\")[0].getElementsByTagName(\"textarea\")[0].value"
                                let js = stub + " = \"" + content + "\"; " //+ "var resultErik = " + stub + ";"
                                self.browser.evaluate(javaScript: js) { (jsObj, jsErr) -> Void in
                                    // .sitetable div.thing[id="thing_t1_jr0mpq1"] .child form#commentreply_t1_jr0mpq1 .usertext-buttons button.save
                                    self.browser.currentContent { (obj2, err2) -> Void in
                                        self.document = obj2
                                        self.document!.querySelectorAll(".sitetable div.thing[id=\"thing_t1_" + parent!.id +
                                                                        "\"] .child form#commentreply_t1_" + parent!.id + " .usertext-buttons button.save").last!.click()
                                    }
//                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        // Read submitted comment from DOM
//                                        self.browser.currentContent { (obj, err) -> Void in
//                                            self.document = obj
//                                            var newCommentTimeTag = self.document!.querySelectorAll(".sitetable div.thing[id=\"thing_t1_\(parent!.id)\"] .child" +
//                                                                                                    " .thing.comment .tagline time").first
//                                            if newCommentTimeTag != nil && newCommentTimeTag!.text == "just now" {
//                                                let newCommentElement = self.document!
//                                                    .querySelectorAll(".sitetable div.thing[id=\"thing_t1_\(parent!.id)\"] .child .thing.comment").first
//
//                                                let newComment = Comment(id: newCommentElement!["data-fullname"] ?? "", depth: parent!.depth + 1,
//                                                                         content: content, user: self.userSessionManager.userName!)
//                                                parent!.replies.insert(newComment, at: 0)
//                                            }
//                                        }
//                                    }
                                }
//                            }
                        }
                    }
                }
            }
        }
        return true
    }
    
    var selectedSortingIcon: String {
        CommentsModelAttributes.sortModifierIcons[selectedSorting]!
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
