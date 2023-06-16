//
//  Model.swift
//  openred
//
//  Created by Norbert Antal on 6/6/23.
//

import Foundation
import Erik
import Kanna
import WebKit

class Model: ObservableObject {
    @Published var posts: [Post] = []
    @Published var communities: [Community] = []
    @Published var subscribedCommunities: [Community] = []
    @Published var mainPageCommunities: [Community] = []
    @Published var userFunctionCommunities: [Community] = []
    @Published var title: String
    @Published var selectedCommunityLink: String
    @Published var selectedSorting: String
    @Published var selectedSortingIcon: String
    @Published var userName: String?
    @Published var linkToNextPage: String?
    @Published var loginAttempt: LoginAttempt = .undecided
    
    let defaults = UserDefaults.standard
    let webView = WKWebView()
    var browser: Erik = Erik()
    var document: Document? = nil
    let redditBaseURL: String = "https://old.reddit.com"
    
    init() {
        self.title = ""
        self.selectedCommunityLink = redditBaseURL + "/r/all"
        self.selectedSorting = ""
        self.selectedSortingIcon = ViewModelAttributes.sortModifierIcons[""]!
        restoreCookies()
        self.browser = Erik(webView: self.webView)
        load(initialURL: selectedCommunityLink)
    }
    
    func login(username: String, password: String) {
        if let form = document!.querySelector("#login_login-main") as? Form {
            if let usernameInput = form.querySelector("input[name=\"user\"]") {
                usernameInput["value"] = username
            }
            if let passwordInput = form.querySelector("input[name=\"passwd\"]") {
                passwordInput["value"] = password
            }
            document?.querySelector("#login_login-main .btn")?.click() { object, error in
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    self.browser.currentContent { (obj, err) -> Void in
                        if let document = obj {
                            if document.querySelector("#login_login-main .error") != nil {
                                // failed login attempt
                                self.loginAttempt = .failed
                            } else {
                                self.loginAttempt = .successful
                                self.document = document
                                self.userName = username
                                self.storeCookies()
                                self.updateCommunitiesList(doc: document)
                            }
                        }
                    }
                }
            }
        }
    }
    
    func load(initialURL: String) {
        setAdditionalCommunities()
        browser.visit(url: URL(string: initialURL)! ) { object, error in
            if let doc = object {
                self.document = doc
                self.updateTitle(doc: doc, defaultTitle: "")
                self.updatePosts(doc: doc)
                self.updateCommunitiesList(doc: doc)
                self.loadUsername(doc: doc)
            }
        }
    }
    
    func loadCommunity(community: Community) {
        self.selectedSorting = ""
        self.selectedSortingIcon = ViewModelAttributes.sortModifierIcons[selectedSorting]!
        self.selectedCommunityLink = community.link
        if selectedCommunityLink.hasSuffix("/") {
            selectedCommunityLink = String(selectedCommunityLink.dropLast())
        }
        self.posts = [] // prompt scroll reset to top
        browser.visit(url: URL(string: selectedCommunityLink)! ) { object, error in
            if let doc = object {
                self.document = doc
                self.updateTitle(doc: doc, defaultTitle: community.name)
                self.updatePosts(doc: doc)
            }
        }
    }
    
    // 'communityCode' format is r/something
    func loadCommunity(communityCode: String) {
        self.selectedSorting = ""
        self.selectedSortingIcon = ViewModelAttributes.sortModifierIcons[selectedSorting]!
        self.selectedCommunityLink = redditBaseURL + "/" + communityCode
        self.posts = [] // prompt scroll reset to top
        browser.visit(url: URL(string: selectedCommunityLink)! ) { object, error in
            if let doc = object {
                self.document = doc
                self.updateTitle(doc: doc, defaultTitle: communityCode.components(separatedBy: "/")[1])
                self.updatePosts(doc: doc)
            }
        }
    }
    
    func refreshWithSortModifier(sortModifier: String) {
        let sortModifierComponents = sortModifier.components(separatedBy: "/")
        if (sortModifierComponents.count > 1) {
            self.selectedSorting = sortModifier.components(separatedBy: "/")[1]
        } else {
            self.selectedSorting = sortModifier
        }
        self.selectedSortingIcon = ViewModelAttributes.sortModifierIcons[selectedSorting]!
        self.posts = [] // prompt scroll reset to top
        browser.visit(url: URL(string: self.selectedCommunityLink + sortModifier)! ) { object, error in
            if let doc = object {
                self.document = doc
                self.updatePosts(doc: doc)
            }
        }
    }
    
    func loadNextPagePosts() {
        if self.linkToNextPage != nil {
            browser.visit(url: URL(string: self.linkToNextPage!)!, completionHandler: { object, error in
                if let doc = object {
                    self.updatePosts(doc: doc, appendToExisting: true)
                    self.updateTitle(doc: doc, defaultTitle: "")
                }
            })
        }
    }
    
    func toggleUpvotePost(post: Post) {
        var selectorModifier = post.isUpvoted ? "mod" : ""
        if let upvoteButton = document?.querySelector("#siteTable div.thing[data-permalink=\"" + post.linkToThread + "\"] div.arrow.up" + selectorModifier) {
            upvoteButton.click()
            post.isUpvoted.toggle()
            post.isDownvoted = false
            browser.currentContent { (obj, err) -> Void in
                if let document = obj {
                    self.document = document
                }
            }
        }
    }
    
    func toggleDownvotePost(post: Post) {
        var selectorModifier = post.isDownvoted ? "mod" : ""
        if let downvoteButton = document?.querySelector("#siteTable div.thing[data-permalink=\"" + post.linkToThread + "\"] div.arrow.down" + selectorModifier) {
            downvoteButton.click()
            post.isDownvoted.toggle()
            post.isUpvoted = false
            browser.currentContent { (obj, err) -> Void in
                if let document = obj {
                    self.document = document
                }
            }
        }
    }
    
    private func updateTitle(doc: Document, defaultTitle: String) {
        if let newTitle = doc.querySelector(".pagename.redditname a")?.text {
            self.title = newTitle.prefix(1).capitalized + String(newTitle.dropFirst())
        } else {
            self.title = defaultTitle
        }
        if let linkToNextPageElement = doc.querySelector(".nav-buttons .next-button a") {
            self.linkToNextPage = linkToNextPageElement["href"] ?? ""
        } else {
            self.linkToNextPage = ""
        }
    }
    
    private func loadUsername(doc: Document) {
        if doc.querySelector("#header .logout")?.text != nil {
            self.userName = doc.querySelector("#header .user a")!.text
        }
    }
    
    private func updatePosts(doc: Document, appendToExisting: Bool = false) {
        if !appendToExisting {
            self.posts = []
        }
        
        self.browser.currentContent { (obj, err) -> Void in
            if let document = obj {
                self.posts.append(contentsOf: RedditParser().parsePosts(document: document))
            }
        }
    }
    
    private func updateCommunitiesList(doc: Document) {
        for element in doc.querySelectorAll("#sr-header-area .drop-choices a:not(.bottom-option)") {
            self.subscribedCommunities.append(Community(element.text!, link: element["href"]!,
                                                        iconName: nil, isMultiCommunity: false))
        }
        var unsortedCommunities: [Community] = []
        let communityElements = doc.querySelectorAll(".sr-list .flat-list.sr-bar:nth-of-type(n+2) li a")
        communityElements.indices.forEach { i in
            if i > 4 { // nth-of-type does not work here, skip manually
                let element = communityElements[i]
                unsortedCommunities.append(Community(element.text!, link: element["href"]!,
                                                     iconName: nil, isMultiCommunity: false))
            }
        }
        self.communities = unsortedCommunities
            .sorted { $0.name.lowercased() < $1.name.lowercased() }
    }
    
    private func setAdditionalCommunities() {
        self.mainPageCommunities.append(Community("Home", link: redditBaseURL,
                                                  iconName: "house.fill", isMultiCommunity: true))
        self.mainPageCommunities.append(Community("Popular Posts", link: redditBaseURL + "/r/popular",
                                                  iconName: "chart.line.uptrend.xyaxis.circle.fill", isMultiCommunity: true))
        self.mainPageCommunities.append(Community("All Posts", link: redditBaseURL + "/r/all",
                                                  iconName: "a.circle.fill", isMultiCommunity: true))
        self.userFunctionCommunities.append(Community("Saved", link: redditBaseURL + "/saved",
                                                      iconName: "heart.text.square", isMultiCommunity: true))
        self.userFunctionCommunities.append(Community("Moderator Posts", link: redditBaseURL + "/mod",
                                                      iconName: "shield", isMultiCommunity: true))
    }
    
    private func storeCookies() {
        let userDefaults = UserDefaults.standard
        var cookieDict = [String : AnyObject]()
        
        webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
            for cookie in cookies {
                cookieDict[cookie.name] = cookie.properties as AnyObject?
            }
            userDefaults.set(cookieDict, forKey: "cookies")
        }
    }
    
    private func restoreCookies() {
        let userDefaults = UserDefaults.standard
        if let cookieDictionary = userDefaults.dictionary(forKey: "cookies") {
            for (_, cookieProperties) in cookieDictionary {
                if let cookie = HTTPCookie(properties: cookieProperties as! [HTTPCookiePropertyKey : Any] ) {
                    webView.configuration.websiteDataStore.httpCookieStore.setCookie(cookie)
                }
            }
        }
    }
}

enum LoginAttempt: Codable {
    case undecided
    case successful
    case failed
}

struct ViewModelAttributes {
    static var sortModifierIcons = [
        "" : "arrow.up.arrow.down",
        "hot" : "flame",
        "top" : "arrow.up.to.line.compact",
        "new" : "clock.badge",
        "rising" : "chart.line.uptrend.xyaxis",
        "controversial" : "arrow.right.and.line.vertical.and.arrow.left"
    ]
}
