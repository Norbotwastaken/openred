//
//  MessageModel.swift
//  openred
//
//  Created by Norbert Antal on 7/13/23.
//

import Erik
import Kanna
import WebKit

class MessageModel: ObservableObject {
    let browser: Erik
    let webView: WKWebView
    let userSessionManager: UserSessionManager
    let jsonLoader: JSONDataLoader = JSONDataLoader()
    
    var document: Document? = nil
    @Published var messages: [Message] = []
    var currentFilter: String = ""
    @Published var nextLink: String?
    @Published var prevLink: String?
    @Published var submissionState: SubmissionState = .idle
    
    init(userSessionManager: UserSessionManager) {
        self.userSessionManager = userSessionManager
        self.webView = userSessionManager.getWebView()
        self.browser = Erik(webView: webView)
    }
    
    func openInbox(filter: String = "inbox", link: String? = nil) {
        var url: URL
        if link != nil {
            self.messages = [] // reset scroll
            self.nextLink = nil
            self.prevLink = nil
            url = URL(string: link!)!
        } else {
            if filter == currentFilter {
                return
            }
            currentFilter = filter
            var components = URLComponents()
            components.scheme = "https"
            components.host = "old.reddit.com"
            components.path = "/message/\(filter)/"
            url = components.url!
        }
        
        browser.visit(url: url) { object, error in
            if let doc = object {
                self.document = doc
                self.prevLink = doc.querySelector(".prev-button a")?["href"]
                self.nextLink = doc.querySelector(".next-button a")?["href"]
            }
        }
        
        url = url.appendingPathComponent(".json")
        jsonLoader.loadMessages(url: url) { (messages, error) in
            DispatchQueue.main.async {
                self.messages = messages!
            }
        }
    }
    
    func sendReply(message: Message, content: String) {
        if userSessionManager.userName == nil {
            return
        }
        browser.currentContent { (obj, err) -> Void in
            self.document = obj
            self.submissionState = .undecided
            if let replyButton = self.document!.querySelectorAll("#thing_\(message.type)_\(message.id) .buttons a").last {
                replyButton.click()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.browser.currentContent { (obj, err) -> Void in
                        self.document = obj
                        let js = "document.getElementById(\"commentreply_\(message.type)_\(message.id)\").getElementsByTagName(\"textarea\")[0].value = \"\(content)\""
                        self.browser.evaluate(javaScript: js) { (jsObj, jsErr) -> Void in
                            self.browser.currentContent { (obj2, err2) -> Void in
                                self.document = obj2
                                self.document!.querySelectorAll("#commentreply_\(message.type)_\(message.id) .usertext-buttons .save").first!.click()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                    self.browser.currentContent { (obj3, err3) -> Void in
                                        self.document = obj3
                                        if self.document!.querySelector("#thing id-\(message.type)_\(message.id) .child .sitetable") != nil {
                                            self.submissionState = .success
                                        } else {
                                            self.submissionState = .failed
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        return
    }
    
    func blockUser(message: Message) {
        if userSessionManager.userName == nil {
            return
        }
        browser.currentContent { (obj, err) -> Void in
            self.document = obj
            self.document!.querySelectorAll("#thing_\(message.type)_\(message.id) .buttons .yes").first!.click()
        }
    }
}
