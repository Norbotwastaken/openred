//
//  PostCreateModel.swift
//  openred
//
//  Created by Norbert Antal on 7/11/23.
//

import Erik
import Kanna
import WebKit

class PostCreateModel: ObservableObject {
    let browser: Erik
    let webView: WKWebView
    let userSessionManager: UserSessionManager
    
    var document: Document? = nil
    var requiresCaptcha: Bool = false
    var submissionLink: URL?
    @Published var submissionState: SubmissionState = .idle
    
    init(userSessionManager: UserSessionManager) {
        self.userSessionManager = userSessionManager
        self.webView = userSessionManager.getWebView()
        self.browser = Erik(webView: webView)
    }
    
    // 'communityCode': r/something
    func openCreatePage(communityCode: String) {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "old.reddit.com"
        components.path = "/" + communityCode.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)! + "/submit"
        self.submissionLink = components.url
        
        browser.visit(url: self.submissionLink!) { o, e in
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
    
    func post(isLink: Bool, title: String, text: String?, link: String?, sendReplies: Bool = true, isProfilePost: Bool = false) {
        if document == nil {
            return
        }
        if requiresCaptcha {
            self.submissionState = .failed
            return
        }
        self.submissionState = .undecided
        if !isLink {
            document!.querySelectorAll(".tabmenu li a").last!.click() { (o, e) -> Void in
                self.browser.currentContent { (o2, e2) -> Void in
                    self.document = o2
                }
            }
        } else if link != "" && !(link!.starts(with: "https://") || link!.starts(with: "http://")) {
            // an invalid link
            self.submissionState = .failed
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            var js = "document.getElementById(\"title-field\").getElementsByTagName(\"textarea\")[0].value = \"" + title + "\"; "
            if isLink {
                js = js + "document.getElementById(\"url-field\").getElementsByTagName(\"input\")[0].value = \"" + link! + "\"; "
            } else {
                js = js + "document.getElementById(\"text-field\").getElementsByTagName(\"textarea\")[0].value = \"" + text! + "\"; "
            }
            if sendReplies {
                js = js + "document.getElementById(\"sendreplies\").checked = true; "
            } else {
                js = js + "document.getElementById(\"sendreplies\").checked = false; "
            }
//            js = js + "var resultErik = document.getElementById(\"url-field\").getElementsByTagName(\"input\")[0].value;"
            self.browser.evaluate(javaScript: js) { (jsObj, jsErr) -> Void in
                self.browser.currentContent { (o2, e2) -> Void in
                    self.document = o2
                    self.document!.querySelector("button.btn")!.click()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        if self.browser.url != self.submissionLink! {
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

enum SubmissionState: Codable {
    case idle
    case undecided
    case failed
    case success
}
