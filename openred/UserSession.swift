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
    var currentCookies: [String : Any] = [:]
    private var webViews: [String:WKWebView] = [:]
    @Published var userNames: [String] = []
    var favoriteCommunities: [String] = []
    
    var upvoteOnSave: Bool = false
    var reverseSwipeControls: Bool = false
    var textSize: Int = 0
    var lockApp: Bool = false
    var commentTheme: String = "default"
    var unmuteVideos: Bool = false
    var appIcon: String = "default"
    
    func createWebViewFor(viewName: String) {
        let webView = WKWebView()
        for (_, cookieProperties) in self.currentCookies {
            if let cookie = HTTPCookie(properties: cookieProperties as! [HTTPCookiePropertyKey : Any] ) {
                webView.configuration.websiteDataStore.httpCookieStore.setCookie(cookie)
            }
        }
        if webViews.isEmpty {
            loadLastLoggedInUser(webView: webView)
        }
        webViews[viewName] = webView
    }
    
    func getWebViewFor(viewName: String) -> WKWebView? {
        webViews[viewName]
    }
    
    func saveUserSession(webViewKey: String, userName: String) {
        var cookieDict = [String : AnyObject]()
        
        let webView = webViews[webViewKey]!
        webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
            for cookie in cookies {
                cookieDict[cookie.name] = cookie.properties as AnyObject?
                for viewKey in self.webViews.keys {
                    if viewKey != webViewKey {
                        self.webViews[viewKey]!.configuration.websiteDataStore.httpCookieStore.setCookie(cookie)
                    }
                }
                HTTPCookieStorage.shared.setCookie(cookie)
            }
            self.currentCookies = cookieDict
            UserDefaults.standard.set(cookieDict, forKey: "cookies_" + userName)
            UserDefaults.standard.set(userName, forKey: "currentUserName")
            UserDefaults.standard.set([String](), forKey: "favorites_" + userName)
            self.userName = userName
            
            var users: [String] = []
            if let savedUsers = UserDefaults.standard.object(forKey: "users") as? [String] {
                users = savedUsers
            }
            if !users.contains(userName) {
                users.append(userName)
            }
            UserDefaults.standard.set(users, forKey: "users")
            self.userNames = users
        }
    }

    func loadLastLoggedInUser(webView: WKWebView) {
        if self.currentCookies.isEmpty {
            if let userName = UserDefaults.standard.object(forKey: "currentUserName") as? String {
                self.userName = userName
                if let favorites = UserDefaults.standard.object(forKey: "favorites_" + userName) as? [String] {
                    favoriteCommunities = favorites
                } else {
                    UserDefaults.standard.set([String](), forKey: "favorites_" + userName)
                }
                if let cookieDictionary = UserDefaults.standard.dictionary(forKey: "cookies_" + userName) {
                    self.currentCookies = cookieDictionary
                    
                    for (_, cookieProperties) in self.currentCookies {
                        if let cookie = HTTPCookie(properties: cookieProperties as! [HTTPCookiePropertyKey : Any] ) {
                            webView.configuration.websiteDataStore.httpCookieStore.setCookie(cookie)
                            HTTPCookieStorage.shared.setCookie(cookie)
                        }
                    }
                }
            }
        }
        if let savedUsers = UserDefaults.standard.object(forKey: "users") as? [String] {
            userNames = savedUsers
        }
    }
    
    func switchToAccount(userName: String) {
        if let cookieDictionary = UserDefaults.standard.dictionary(forKey: "cookies_" + userName) {
            logOut()
            self.userName = userName
            self.currentCookies = cookieDictionary
            if let favorites = UserDefaults.standard.object(forKey: "favorites_" + userName) as? [String] {
                favoriteCommunities = favorites
            } else {
                UserDefaults.standard.set([String](), forKey: "favorites_" + userName)
            }
            
            for (_, cookieProperties) in self.currentCookies {
                if let cookie = HTTPCookie(properties: cookieProperties as! [HTTPCookiePropertyKey : Any] ) {
                    for webView in webViews.values {
                        webView.configuration.websiteDataStore.httpCookieStore.setCookie(cookie)
                    }
                    HTTPCookieStorage.shared.setCookie(cookie)
                }
            }
            UserDefaults.standard.set(userName, forKey: "currentUserName")
        }
    }
    
    func logOut() {
        UserDefaults.standard.removeObject(forKey: "currentUserName")
//        for viewKey in webViews.keys {
//            webViews[viewKey] = WKWebView()
//        }
        for webView in webViews.values {
            webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
                for cookie in cookies {
                    webView.configuration.websiteDataStore.httpCookieStore.delete(cookie)
                }
            }
        }
        HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)
        self.currentCookies = [:]
//        for cookie in HTTPCookieStorage.shared.cookies! {
//            HTTPCookieStorage.shared.deleteCookie(cookie)
//        }
        self.userName = nil
        self.favoriteCommunities = []
    }
    
    func removeAccount(_ userName: String) {
        var users: [String] = []
        if let savedUsers = UserDefaults.standard.object(forKey: "users") as? [String] {
            users = savedUsers.filter{ $0 != userName }
            userNames = users
            UserDefaults.standard.set(users, forKey: "users")
        }
        UserDefaults.standard.removeObject(forKey: "cookies_" + userName)
        UserDefaults.standard.removeObject(forKey: "favorites_" + userName)
    }
    
    func removeWebViews(keys: [String], removeCommentViews: Bool = true) {
        for key in keys {
            webViews.removeValue(forKey: key)
        }
        if removeCommentViews {
            for key in (webViews.keys.filter{ $0.contains("/comments/") }) {
                webViews.removeValue(forKey: key)
            }
        }
    }
    
    func setFavoriteCommunities(_ communities: [String]) {
        favoriteCommunities = communities
        UserDefaults.standard.set(favoriteCommunities, forKey: "favorites_" + userName!)
    }
}
