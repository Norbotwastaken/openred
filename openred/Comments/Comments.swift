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
    @Published var pages: [String:CommentPage] = [:]
    let userSessionManager: UserSessionManager
    var jsonLoader: JSONDataLoader
    
    init(userSessionManager: UserSessionManager) {
        self.jsonLoader = JSONDataLoader()
        self.userSessionManager = userSessionManager
    }
    
    func loadComments(linkToThread: String, sortBy: String? = nil, forceLoad: Bool = false) {
        if pages[linkToThread] == nil || userSessionManager.getWebViewFor(viewName: linkToThread) == nil {
            userSessionManager.createWebViewFor(viewName: linkToThread)
        } else if !forceLoad && sortBy == nil {
            return
        }
        let page = pages[linkToThread] ?? CommentPage(link: linkToThread, webView: userSessionManager
            .getWebViewFor(viewName: linkToThread)!)
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
                    page.comments = []
                    page.commentsCollapsed = [:]
                    page.flatCommentsList = []
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
    
    func resetPages() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            self.userSessionManager.removeWebViews(keys: Array(self.pages.keys))
            self.pages.removeAll()
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
            if comment.isSaved && userSessionManager.upvoteOnSave && !comment.isUpvoted {
                toggleUpvoteComment(link: link, comment: comment)
            }
            return true
        }
        return false
    }
    
    func deletePost(link: String) -> Bool {
        if self.userSessionManager.userName == nil {
            return false
        }
        if let deleteButton = self.pages[link]!.document?.querySelector("#siteTable form.del-button a.yes") {
            deleteButton.click()
            return true
        }
        return false
    }
    
    func togglePostNsfw(link: String) -> Bool {
        if self.userSessionManager.userName == nil {
            return false
        }
        if let nsfwButton = self.pages[link]!.document?.querySelector("#siteTable form.marknsfw-button a.yes") {
            nsfwButton.click()
            return true
        } else if let nsfwButton = self.pages[link]!.document?.querySelector("#siteTable form.unmarknsfw-button a.yes") {
            nsfwButton.click()
            return true
        }
        return false
    }
    
    func togglePostSpoiler(link: String) -> Bool {
        if self.userSessionManager.userName == nil {
            return false
        }
        if let spoilerButton = self.pages[link]!.document?.querySelector("#siteTable form.spoiler-button a.yes") {
            spoilerButton.click()
            return true
        } else if let spoilerButton = self.pages[link]!.document?.querySelector("#siteTable form.unspoiler-button a.yes") {
            spoilerButton.click()
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
        let formattedContent = String.formatForJS(content)
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
                            let js = stub + " = \"" + formattedContent + "\"; "// + "var resultErik = " + stub + ";"
                            page!.browser.evaluate(javaScript: js) { (jsObj, jsErr) -> Void in
                                page!.browser.currentContent { (obj2, err2) -> Void in
                                    page!.document = obj2
                                    page!.document!.querySelectorAll(".sitetable div.thing[id=\"thing_t1_" + parent!.id +
                                                                    "\"] .child form#commentreply_t1_" + parent!.id + " .usertext-buttons button.save").last!.click()
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        page!.browser.currentContent { (obj3, err3) -> Void in
                                            page!.document = obj3
                                            let newCommentTimeTag = page!.document!.querySelectorAll(".sitetable div.thing[id=\"thing_t1_\(parent!.id)\"] .child" +
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
                                                self.objectWillChange.send()
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
                    let js = stub + " = \"" + formattedContent + "\"; " // + "var resultErik = " + stub + ";"
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
                                            self.objectWillChange.send()
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
    
    func editComment(link: String, comment: Comment, content: String) {
        if userSessionManager.userName == nil {
            return
        }
        let page = pages[link]
        if page == nil {
            return
        }
        page!.browser.currentContent { (obj, err) -> Void in
            page!.document = obj
            if let editButton = page!.document!.querySelectorAll(".sitetable div.thing[id=\"thing_t1_" + comment.id + "\"]>.entry .buttons a.edit-usertext").first {
                editButton.click()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    page!.browser.currentContent { (obj, err) -> Void in
                        page!.document = obj
                        let stub = "document.getElementById(\"thing_t1_" + comment.id +
                        "\").getElementsByClassName(\"usertext-edit\")[0].getElementsByTagName(\"textarea\")[0].value"
                        let js = stub + " = \"" + String.formatForJS(content) + "\"; "// + "var resultErik = " + stub + ";"
                        page!.browser.evaluate(javaScript: js) { (jsObj, jsErr) -> Void in
                            page!.browser.currentContent { (obj2, err2) -> Void in
                                page!.document = obj2
                                page!.document!.querySelectorAll(".sitetable div.thing[id=\"thing_t1_\(comment.id)\"] .bottom-area .usertext-buttons button.save")
                                    .first!.click()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    page!.browser.currentContent { (obj3, err3) -> Void in
                                        page!.document = obj3
                                        self.objectWillChange.send()
                                        page!.comments.filter{ $0.id == comment.id }.first?.content = ContentFormatter().formatAndConvert(text: content)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func deleteComment(link: String, comment: Comment) {
        if userSessionManager.userName == nil {
            return
        }
        let page = pages[link]
        if page == nil {
            return
        }
        page!.browser.currentContent { (obj, err) -> Void in
            page!.document = obj
            if let deleteButton = page!.document!.querySelectorAll(".sitetable div.thing[id=\"thing_t1_\(comment.id)\"]>.entry .buttons form.del-button a.yes").first {
                deleteButton.click()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    page!.browser.currentContent { (obj, err) -> Void in
                        page!.document = obj
                        if let deleteFormText = page!.document!.querySelectorAll(".sitetable div.thing[id=\"thing_t1_\(comment.id)\"]>.entry .buttons form.del-button").first?.text {
                            if deleteFormText == "deleted" {
                                comment.content = nil
                                comment.isCollapsed = true
                                self.objectWillChange.send()
                            }
                        }
                    }
                }
            }
        }
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
            objectWillChange.send()
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
            objectWillChange.send()
            return true
        }
        return false
    }
    
    func toggleSavePost(link: String, post: Post) -> Bool {
        if self.userSessionManager.userName == nil {
            return false
        }
        if let saveButton = pages[link]?.document?.querySelector("#siteTable .buttons .save-button a") {
            saveButton.click()
            post.isSaved.toggle()
            if post.isSaved && userSessionManager.upvoteOnSave && !post.isUpvoted {
                toggleUpvotePost(link: link, post: post)
            }
            objectWillChange.send()
            return true
        }
        return false
    }
    
    func collapseComment(link: String, comment: Comment) {
        pages[link]?.collapseComment(comment)
    }
    
    func collapseCommentThread(link: String, comment: Comment) -> String {
        let id = pages[link]!.collapseCommentThread(comment)
        objectWillChange.send()
        return id
    }
    
    func selectedSortingIcon(link: String) -> String {
        if pages[link] == nil {
            return CommentsModelAttributes.sortModifierIcons[""]!
        }
        return CommentsModelAttributes.sortModifierIcons[pages[link]!.selectedSorting]!
    }
    
    var reverseSwipeControls: Bool {
        userSessionManager.reverseSwipeControls
    }
    
    var textSizeInrease: Int {
        userSessionManager.textSize * 2
    }
    
    var commentTheme: String {
        userSessionManager.commentTheme
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
    
    func collapseComment(_ comment: Comment) {
        comment.isCollapsed.toggle()
        commentsCollapsed[comment.id]!.toggle()
    }
    
    func collapseCommentThread(_ comment: Comment) -> String {
        if comment.allParents.isEmpty {
            comment.isCollapsed.toggle()
            commentsCollapsed[comment.id]!.toggle()
            return comment.id
        } else {
            let topLevelParent = comments.filter{ $0.id == comment.allParents[0] }.first!
            topLevelParent.isCollapsed = true
            commentsCollapsed[topLevelParent.id]! = true
            return topLevelParent.id
        }
    }
    
    var selectedSortingDisplayLabel: String {
        if selectedSorting == "" || selectedSorting == "confidence" {
            return "Hot"
        } else if selectedSorting == "qa" {
            return "Q&A"
        } else {
            return selectedSorting.capitalized
        }
    }
}
