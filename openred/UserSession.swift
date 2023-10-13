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
    var communityCollections: [String:[String]] = [:]
    var adLastPresented: [Date] = []
    private var adHistoryLength: Int = 2
    
    var upvoteOnSave: Bool = false
    var textSize: Int = 0
    var lockApp: Bool = false
    var commentTheme: String = "default"
    var unmuteVideos: Bool = false
    var appIcon: String = "default"
    var sendCrashReports: Bool = true
    var showNSFW: Bool = false
    var accentColor: String = "red"
    var homePage: String = "r/all"
    var compactMode: Bool = false
    var compactModeReverse: Bool = false
    var promotePremium: Bool = false
    var homePageCommunity: CommunityOrUser =
    CommunityOrUser(community: Community("all", iconName: nil, isMultiCommunity: true))
    var commentLeftPrimary: SwipeAction = .upvote
    var commentLeftSecondary: SwipeAction = .downvote
    var commentRightPrimary: SwipeAction = .collapse
    var commentRightSecondary: SwipeAction = .reply
    var postLeftPrimary: SwipeAction = .upvote
    var postLeftSecondary: SwipeAction = .downvote
    var postRightPrimary: SwipeAction = .noAction
    var postRightSecondary: SwipeAction = .noAction
    var hasRedditPremium: Bool = false
    
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
        self.userName = userName
        UserDefaults.standard.set(userName, forKey: "currentUserName")
        var users: [String] = []
        if let savedUsers = UserDefaults.standard.object(forKey: "users") as? [String] {
            users = savedUsers
        }
        if !users.contains(userName) {
            users.append(userName)
            UserDefaults.standard.set([String](), forKey: "favorites_" + userName)
        }
        UserDefaults.standard.set(users, forKey: "users")
        self.userNames = users
        
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
        }
    }

    func loadLastLoggedInUser(webView: WKWebView) {
        URLCache.shared.removeAllCachedResponses()
        if self.currentCookies.isEmpty {
            if let userName = UserDefaults.standard.object(forKey: "currentUserName") as? String {
                self.userName = userName
                if let favorites = UserDefaults.standard.object(forKey: "favorites_" + userName) as? [String] {
                    favoriteCommunities = favorites
                } else {
                    UserDefaults.standard.set([String](), forKey: "favorites_" + userName)
                }
                if let collections = UserDefaults.standard.object(forKey: "collections_" + userName) as? [String:[String]] {
                    communityCollections = collections
                } else {
                    UserDefaults.standard.set([String](), forKey: "collections_" + userName)
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
            if let collections = UserDefaults.standard.object(forKey: "collections_" + userName) as? [String:[String]] {
                communityCollections = collections
            } else {
                UserDefaults.standard.set([String](), forKey: "collections_" + userName)
            }
            
            for (_, cookieProperties) in self.currentCookies {
                if let cookie = HTTPCookie(properties: cookieProperties as! [HTTPCookiePropertyKey : Any] ) {
                    for webView in webViews.values {
                        webView.configuration.websiteDataStore.httpCookieStore.setCookie(cookie)
                    }
                    HTTPCookieStorage.shared.setCookie(cookie)
                }
            }
            URLCache.shared.removeAllCachedResponses()
            UserDefaults.standard.set(userName, forKey: "currentUserName")
        }
    }
    
    func logOut() {
        URLCache.shared.removeAllCachedResponses()
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
        self.communityCollections = [:]
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
    
    func setCommunityCollections(_ communityCollections: [String:[String]]) {
        self.communityCollections = communityCollections
        UserDefaults.standard.set(communityCollections, forKey: "collections_" + userName!)
    }
    
    private func loadHomePage() -> String {
        if let savedHomePage = UserDefaults.standard.object(forKey: "homePage") as? String {
            homePage = savedHomePage
        }
        return homePage
    }
    
    func getHomePageCommunity() -> CommunityOrUser {
        var homePage = loadHomePage()
        var isMultiCommunity = false
        if ["r/all", "", "r/popular"].contains(homePage) {
            isMultiCommunity = true
        }
        homePage = homePage.hasPrefix("r/") ? String(homePage.dropFirst(2)) : homePage
        homePageCommunity = CommunityOrUser(community: Community(homePage, iconName: nil, isMultiCommunity: isMultiCommunity))
        if homePage == "" {
            homePageCommunity = CommunityOrUser(community: Community(homePage, iconName: nil, isMultiCommunity: true, path: ""))
        }
        return homePageCommunity
    }
    
    func createCommunityCollection(collectionName: String, communityName: String? = nil) -> Bool {
        if collectionName.count > 45 || userName == nil {
            return false
        }
        if communityCollections[collectionName] == nil {
            communityCollections[collectionName] = communityName == nil ? [] : [communityName!]
            UserDefaults.standard.set(communityCollections, forKey: "collections_" + userName!)
            return true
        }
        return false
    }
    
    func deleteCommunityCollection(collectionName: String) -> Bool {
        if communityCollections[collectionName] != nil && userName != nil {
            communityCollections.removeValue(forKey: collectionName)
            UserDefaults.standard.set(communityCollections, forKey: "collections_" + userName!)
            return true
        }
        return false
    }
    
    func addToCommunityCollection(collectionName: String, communityName: String) -> Bool {
        if let collection = communityCollections[collectionName] {
            if collection.contains(communityName) {
                return false
            }
            var newContents = [communityName]
            newContents.append(contentsOf: communityCollections[collectionName] ?? [])
            communityCollections[collectionName] = newContents
            UserDefaults.standard.set(communityCollections, forKey: "collections_" + userName!)
            objectWillChange.send()
            return true
        }
        return false
    }
    
    func removeFromCommunityCollection(collectionName: String, communityName: String) -> Bool {
        if let collection = communityCollections[collectionName] {
            var newContents = communityCollections[collectionName]!
                .filter{ $0.lowercased() != communityName.lowercased() }
            communityCollections[collectionName] = newContents
            UserDefaults.standard.set(communityCollections, forKey: "collections_" + userName!)
            objectWillChange.send()
            return true
        }
        return false
    }
    
    func markAdPresented() {
        let now = Date()
        if adLastPresented.count < adHistoryLength {
            adLastPresented.append(now)
        } else {
            var sortedDates = adLastPresented.sorted(by: { $0.compare($1) == .orderedAscending})
            sortedDates[0] = now
            adLastPresented = sortedDates
        }
        UserDefaults.standard.set(adLastPresented, forKey: "adLastPresented")
    }
}

struct CollectionListItem: Identifiable {
    var id = UUID()
    var name: String
    var parentCollection: String?
    var communities: [CollectionListItem]?
    
    func containtsCommunity(_ community: String) -> Bool {
        communities?.filter{ $0.name.lowercased() == community.lowercased() }.count != 0
    }
}
