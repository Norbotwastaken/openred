//
//  MessageCreateModel.swift
//  openred
//
//  Created by Norbert Antal on 8/27/23.
//

import Erik
import Kanna
import WebKit

class MessageCreateModel: ObservableObject {
    let browser: Erik
    let webView: WKWebView
    let userSessionManager: UserSessionManager
    
    var document: Document? = nil
    var requiresCaptcha: Bool = false
    var composeLink: URL?
    @Published var submissionState: SubmissionState = .idle
    private let webViewKey = "new_message"
    
    init(userSessionManager: UserSessionManager) {
        self.userSessionManager = userSessionManager
        userSessionManager.createWebViewFor(viewName: webViewKey)
        self.webView = userSessionManager.getWebViewFor(viewName: webViewKey)!
        self.browser = Erik(webView: webView)
    }
    
    func openComposePage(userName: String) {
        if userSessionManager.userName == nil {
            return
        }
        var components = URLComponents()
        components.scheme = "https"
        components.host = "old.reddit.com"
        components.path = "/message/compose"
        components.queryItems = [ URLQueryItem(name: "to", value: userName) ]
        self.composeLink = components.url
        
        browser.visit(url: self.composeLink!) { o, e in
            if o != nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    // refresh contents after captcha load
                    self.browser.currentContent { (obj, err) -> Void in
                        self.document = obj
                        if !self.document!.querySelectorAll(".g-recaptcha iframe").isEmpty {
                            self.requiresCaptcha = true
                        }
                    }
                }
            }
        }
    }
    
    func sendMessage(subject: String, message: String) {
        if document == nil {
            return
        }
        if requiresCaptcha {
            self.submissionState = .failed
            return
        }
        self.submissionState = .undecided
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            var js = "document.getElementById(\"compose-message\").getElementsByTagName(\"input\")[2].value = \"\(subject)\"; "
            js = js + "document.getElementsByClassName(\"message_field\")[0].getElementsByTagName(\"textarea\")[0].value = \"\(message)\";"
            
            self.browser.evaluate(javaScript: js) { (jsObj, jsErr) -> Void in
                self.browser.currentContent { (o2, e2) -> Void in
                    self.document = o2
                    self.document!.querySelector("button#send")!.click()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        self.browser.currentContent { (o3, e3) -> Void in
                            self.document = o3
                            let confirmationText = self.document!.querySelector("#compose-message .status")?.text
                            if confirmationText == "your message has been delivered" {
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
