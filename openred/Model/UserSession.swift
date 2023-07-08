//
//  UserSession.swift
//  openred
//
//  Created by Norbert Antal on 6/20/23.
//

import Foundation
import WebKit

class UserSessionManager: ObservableObject {
    @Published var userName: String?
    var currentCookies: [String : Any]?
    private var webViews: [WKWebView] = []
    
    func getWebView() -> WKWebView {
        let webView = WKWebView()
        self.webViews.append(webView)
        return webView
    }
    
    func saveUserSession(webView: WKWebView, userName: String) {
        var cookieDict = [String : AnyObject]()

        webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
            for cookie in cookies {
                cookieDict[cookie.name] = cookie.properties as AnyObject?
                for view in self.webViews {
                    view.configuration.websiteDataStore.httpCookieStore.setCookie(cookie)
                }
            }
            self.currentCookies = cookieDict
            UserDefaults.standard.set(cookieDict, forKey: "cookies_" + userName)
            UserDefaults.standard.set(userName, forKey: "currentUserName")
        }
    }

    func loadLastLoggedInUser(webView: WKWebView) {
        if self.currentCookies == nil {
            if let userName = UserDefaults.standard.object(forKey: "currentUserName") as? String {
                self.userName = userName
                if let cookieDictionary = UserDefaults.standard.dictionary(forKey: "cookies_" + userName) {
                    self.currentCookies = cookieDictionary
                    
                    for (_, cookieProperties) in self.currentCookies! {
                        if let cookie = HTTPCookie(properties: cookieProperties as! [HTTPCookiePropertyKey : Any] ) {
                            webView.configuration.websiteDataStore.httpCookieStore.setCookie(cookie)
                            HTTPCookieStorage.shared.setCookie(cookie)
                        }
                    }
                }
            }
        }
    }
    
    func logOut() {
        UserDefaults.standard.removeObject(forKey: "currentUserName")
        for view in webViews {
            view.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
                for cookie in cookies {
                    view.configuration.websiteDataStore.httpCookieStore.delete(cookie)
                }
            }
        }
    }
}
