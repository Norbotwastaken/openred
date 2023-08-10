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
//    var browser: Erik = Erik()
//    var document: Document? = nil
//    var currentLink: String = "" // /r/something/comments
    var jsonLoader: JSONDataLoader
    
    @Published var pages: [String:CommentPage] = [:]
//    @Published var comments: [Comment] = []
//    @Published var post: Post?
//    @Published var flatCommentsList: [Comment] = []
//    @Published var commentsCollapsed: [String:Bool] = [:]
//    @Published var title: String = ""
//    @Published var commentCount: String = ""
//    @Published var selectedSorting: String = ""
//    private let webViewKey = "comments"
    
//    let webView: WKWebView
    let userSessionManager: UserSessionManager
    
    init(userSessionManager: UserSessionManager) {
//        userSessionManager.createWebViewFor(viewName: webViewKey)
//        self.webView = userSessionManager.getWebViewFor(viewName: webViewKey)
//        userSessionManager.loadLastLoggedInUser(webView: self.webView)
        self.jsonLoader = JSONDataLoader()
//        self.browser = Erik(webView: webView)
        self.userSessionManager = userSessionManager
//        UserSessionManager().loadLastLoggedInUser(webView: webView)
//        webView
    }
    
    func loadComments(linkToThread: String, sortBy: String? = nil, forceLoad: Bool = false) {
        if pages[linkToThread] == nil {
            userSessionManager.createWebViewFor(viewName: linkToThread)
        } else if !forceLoad && sortBy == nil {
            return
        }
        let page = pages[linkToThread] ?? CommentPage(link: linkToThread, webView: userSessionManager
            .getWebViewFor(viewName: linkToThread))
        page.selectedSorting = ""
        
        var components = URLComponents()
        components.scheme = "https"
        components.host = "old.reddit.com"
        components.path = linkToThread.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)!
        components.queryItems = []
        
        if sortBy != nil {
            page.selectedSorting = sortBy!
            components.queryItems?.append(URLQueryItem(name: "sort", value: sortBy!))
        }
        
        page.browser.visit(url: components.url!) { object, error in
            if let doc = object {
                page.document = doc
                page.title = doc.title!
                // TODO: get comment count some other way
                page.commentCount = doc.querySelector("#siteTable .thing")?["data-comments-count"] ?? ""
                // Expand first layer of collapsed comments (DOM needs refreshing)
                for expandButton in doc.querySelectorAll(".thing.collapsed .expand") {
                    expandButton.click()
                }
            }
        }
        
        components.path = components.path + "/.json"
        jsonLoader.loadComments(url: components.url!) { (comments, post, error) in
            DispatchQueue.main.async {
                if let comments = comments {
                    page.post = post
                    for comment in comments {
                        page.comments.append(comment)
                    }
                    page.buildCommentArray(comments: comments, parents: [])
                    self.pages[linkToThread] = page
                }
            }
        }
    }
    
    func toggleUpvoteComment(link: String, comment: Comment) -> Bool {
        if userSessionManager.userName == nil {
            return false
        }
        let selectorModifier = comment.isUpvoted ? "mod" : ""
        if let upvoteButton = pages[link]?.document?.querySelectorAll(".sitetable div.thing[id=\"thing_t1_" + comment.id + "\"] div.arrow.up" + selectorModifier).first {
            upvoteButton.click()
            comment.isUpvoted.toggle()
            comment.isDownvoted = false
            pages[link]!.browser.currentContent { (obj, err) -> Void in
                if let document = obj {
                    self.pages[link]!.document = document
                }
            }
        }
        return true
    }
    
    func toggleDownvoteComment(link: String, comment: Comment) -> Bool {
        if userSessionManager.userName == nil {
            return false
        }
        let selectorModifier = comment.isDownvoted ? "mod" : ""
        if let downButton = pages[link]?.document?.querySelectorAll(".sitetable div.thing[id=\"thing_t1_" + comment.id + "\"] div.arrow.down" + selectorModifier).first {
            downButton.click()
            comment.isDownvoted.toggle()
            comment.isUpvoted = false
            pages[link]!.browser.currentContent { (obj, err) -> Void in
                if let document = obj {
                    self.pages[link]!.document = document
                }
            }
        }
        return true
    }
    
    func toggleSaveComment(link: String, comment: Comment) -> Bool {
        if userSessionManager.userName == nil {
            return false
        }
        if let saveButton = pages[link]?.document?.querySelectorAll(".sitetable div.thing[id=\"thing_t1_" + comment.id + "\"] .buttons .save-button a").first {
            saveButton.click()
            comment.isSaved.toggle()
            return true
        }
        return false
    }
    
    func sendReply(link: String, parent: Comment?, content: String) -> Bool {
        if userSessionManager.userName == nil {
            return false
        }
        let page = pages[link]
        if page == nil {
            return false
        }
        page!.browser.currentContent { (obj, err) -> Void in
            page!.document = obj
            if parent != nil {
                if let replyButton = page!.document!.querySelectorAll(".sitetable div.thing[id=\"thing_t1_" + parent!.id + "\"]>.entry .buttons .reply-button a").first {
                    replyButton.click()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        page!.browser.currentContent { (obj, err) -> Void in
                            page!.document = obj
                            let stub = "document.getElementById(\"commentreply_t1_" + parent!.id +
                            "\").getElementsByClassName(\"usertext-edit\")[0].getElementsByTagName(\"textarea\")[0].value"
                            let js = stub + " = \"" + content + "\"; " //+ "var resultErik = " + stub + ";"
                            page!.browser.evaluate(javaScript: js) { (jsObj, jsErr) -> Void in
                                page!.browser.currentContent { (obj2, err2) -> Void in
                                    page!.document = obj2
                                    page!.document!.querySelectorAll(".sitetable div.thing[id=\"thing_t1_" + parent!.id +
                                                                    "\"] .child form#commentreply_t1_" + parent!.id + " .usertext-buttons button.save").last!.click()
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        page!.browser.currentContent { (obj3, err3) -> Void in
                                            page!.document = obj3
                                            var newCommentTimeTag = page!.document!.querySelectorAll(".sitetable div.thing[id=\"thing_t1_\(parent!.id)\"] .child" +
                                                                                                    " .thing.comment .tagline time").first
                                            if newCommentTimeTag != nil && newCommentTimeTag!.text == "just now" {
                                                let newCommentElement = page!.document!
                                                    .querySelectorAll(".sitetable div.thing[id=\"thing_t1_\(parent!.id)\"] .child .thing.comment").first

                                                let newComment = Comment(id: newCommentElement!["data-fullname"] ?? "", depth: parent!.depth + 1,
                                                                         content: content, user: self.userSessionManager.userName!)
                                                parent!.replies.insert(newComment, at: 0)
                                                var i = 0
                                                while i < page!.flatCommentsList.count && page!.flatCommentsList[i].id != parent?.id {
                                                    i = i + 1
                                                }
                                                page!.flatCommentsList.insert(newComment, at: i + 1)
                                                page!.commentsCollapsed[newComment.id] = false
                                                // TODO: update other model collections
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    let stub = "document.getElementsByClassName(\"commentarea\")[0].getElementsByClassName(\"usertext\")[0].getElementsByTagName(\"textarea\")[0].value"
                    let js = stub + " = \"" + content + "\"; " // + "var resultErik = " + stub + ";"
                    page!.browser.evaluate(javaScript: js) { (jsObj, jsErr) -> Void in
                        page!.browser.currentContent { (obj2, err2) -> Void in
                            page!.document = obj2
                            page!.document!.querySelectorAll(".commentarea form[id^=\"form-t3\"] .usertext-buttons button.save").first!.click()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                page!.browser.currentContent { (obj3, err3) -> Void in
                                    page!.document = obj3
                                    if let newCommentElement = page!.document!.querySelectorAll(".commentarea .thing.comment").first {
                                        let newCommentTimeElement = newCommentElement.querySelector(".tagline time")
                                        if newCommentTimeElement != nil && newCommentTimeElement!.text == "just now" {
                                            let newComment = Comment(id: newCommentElement["data-fullname"] ?? "", depth: 0,
                                                                     content: content, user: self.userSessionManager.userName!)
                                            page!.comments.insert(newComment, at: 0)
                                            page!.flatCommentsList.insert(newComment, at: 0)
                                            page!.commentsCollapsed[newComment.id] = false
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        return true
    }
    
    func toggleUpvotePost(link: String, post: Post) -> Bool {
        if self.userSessionManager.userName == nil {
            return false
        }
        let selectorModifier = post.isUpvoted ? "mod" : ""
        if let upvoteButton = pages[link]?.document?.querySelector("#siteTable div.arrow.up" + selectorModifier) {
            upvoteButton.click()
            post.isUpvoted.toggle()
            post.isDownvoted = false
            pages[link]!.browser.currentContent { (obj, err) -> Void in
                if let document = obj {
                    self.pages[link]!.document = document
                }
            }
            return true
        }
        return false
    }
    
    func toggleDownvotePost(link: String, post: Post) -> Bool {
        if self.userSessionManager.userName == nil {
            return false
        }
        let selectorModifier = post.isDownvoted ? "mod" : ""
        if let downvoteButton = pages[link]?.document?.querySelector("#siteTable div.arrow.down" + selectorModifier) {
            downvoteButton.click()
            post.isDownvoted.toggle()
            post.isUpvoted = false
            pages[link]!.browser.currentContent { (obj, err) -> Void in
                if let document = obj {
                    self.pages[link]!.document = document
                }
            }
        }
        return true
    }
    
    func toggleSavePost(link: String, post: Post) -> Bool {
        if self.userSessionManager.userName == nil {
            return false
        }
        if let saveButton = pages[link]?.document?.querySelector("#siteTable .buttons .save-button a") {
            saveButton.click()
            post.isSaved.toggle()
        }
        return true
    }
    
    func selectedSortingIcon(link: String) -> String {
        return CommentsModelAttributes.sortModifierIcons[pages[link]!.selectedSorting]!
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

class CommentPage: ObservableObject {
    var currentLink: String
    @Published var comments: [Comment] = []
    @Published var post: Post?
    @Published var flatCommentsList: [Comment] = []
    @Published var commentsCollapsed: [String:Bool] = [:]
    @Published var title: String = ""
    @Published var commentCount: String = ""
    @Published var selectedSorting: String = ""
    
    let webView: WKWebView
    var browser: Erik
    var document: Document?
    
    init(link: String, webView: WKWebView) {
        self.currentLink = link
        self.webView = webView
        self.browser = Erik(webView: self.webView)
    }
    
    func buildCommentArray(comments: [Comment], parents: [String]) {
        for comment in comments {
            comment.allParents = parents
            commentsCollapsed[comment.id] = comment.isCollapsed
            flatCommentsList.append(comment)
            if !comment.replies.isEmpty {
                var newParents = parents
                newParents.append(comment.id)
                buildCommentArray(comments: comment.replies, parents: newParents)
            }
        }
    }
    
    func anyParentsCollapsed(comment: Comment) -> Bool {
        !comment.allParents.map{ commentsCollapsed[$0] }.filter{ $0 == true }.isEmpty
    }
}
