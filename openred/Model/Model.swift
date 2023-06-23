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
    @Published var title: String = ""
    @Published var selectedCommunityCode: String = "/r/all"
    @Published var selectedSorting: String = ""
    @Published var selectedSortTime: String?
    @Published var after: String?
    @Published var loginAttempt: LoginAttempt = .undecided
    
    let defaults = UserDefaults.standard
    let userSessionManager: UserSessionManager
    let webView: WKWebView = WKWebView()
    var browser: Erik = Erik()
    var document: Document? = nil
    let redditBaseURL: String = "https://old.reddit.com"
    var jsonLoader: JSONDataLoader = JSONDataLoader()
    
    init(userSessionManager: UserSessionManager) {
        self.userSessionManager = userSessionManager
        self.userSessionManager.loadLastLoggedInUser(webView: webView)
//        self.jsonLoader = JSONDataLoader()
        self.mainPageCommunities = setMainPageCommunities
        self.userFunctionCommunities = setUserFunctionCommunities
        self.browser = Erik(webView: self.webView)
        self.loadCommunity(communityCode: selectedCommunityCode)
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
                                self.userSessionManager.userName = username
//                                self.userName = username
                                self.userSessionManager.saveUserSession(webView: self.webView, userName: username)
                                self.updateCommunitiesList(doc: document)
                            }
                        }
                    }
                }
            }
        }
    }
    
    func logOut() {
        userSessionManager.logOut()
        loadCommunity(communityCode: selectedCommunityCode)
    }
    
    // 'communityCode': r/something
    // 'sortBy': top
    // 'sortTime': month
    // 'after': t3_14c4ene
    //  old.reddit.com/r/something/top/.json?sort=top&t=month&count=25&after=t3_14c4ene
    func loadCommunity(communityCode: String, sortBy: String? = nil, sortTime: String? = nil, after: String? = nil) {
        self.selectedCommunityCode = communityCode
        self.selectedSortTime = sortTime
        self.selectedSorting = ""
        
        var components = URLComponents()
        components.scheme = "https"
        components.host = "old.reddit.com"
        components.path = "/" + communityCode
        components.queryItems = []
        
        if sortBy != nil {
            self.selectedSorting = sortBy!
            components.path = components.path + "/" + sortBy!
            components.queryItems?.append(URLQueryItem(name: "sort", value: sortBy!))
            if sortTime != nil {
                components.queryItems?.append(URLQueryItem(name: "t", value: sortTime!))
            }
        }
        
        if after != nil {
            components.queryItems?.append(URLQueryItem(name: "after", value: after!))
        } else {
            self.posts = []
        }
        
        browser.visit(url: components.url! ) { object, error in
            if let doc = object {
                self.document = doc
                self.updateTitle(doc: doc, defaultTitle: communityCode.components(separatedBy: "/")[1])

                self.updateCommunitiesList(doc: doc)
                self.loadUsername(doc: doc)
            }
        }
        
        components.path = components.path + "/.json"
        jsonLoader.loadPosts(url: components.url!) { (posts, after, error) in
            DispatchQueue.main.async {
                if let posts = posts {
                    for i in posts.indices {
                        let isActiveLoadMarker = (i == posts.count - 7)
                        self.posts.append(Post(jsonPost: posts[i], isActiveLoadMarker: isActiveLoadMarker))
                    }
                }
                self.after = after
            }
        }
    }
    
    func loadNextPagePosts() {
        if self.after != nil {
            loadCommunity(communityCode: selectedCommunityCode, sortBy: selectedSorting,
                          sortTime: selectedSortTime, after: after)
        }
    }
    
    func toggleUpvotePost(post: Post) -> Bool {
        if self.userSessionManager.userName == nil {
            return false
        }
        let selectorModifier = post.isUpvoted ? "mod" : ""
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
        return true
    }
    
    func toggleDownvotePost(post: Post) -> Bool {
        if self.userSessionManager.userName == nil {
            return false
        }
        let selectorModifier = post.isDownvoted ? "mod" : ""
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
        return true
    }
    
    func toggleSavePost(post: Post) -> Bool {
        if self.userSessionManager.userName == nil {
            return false
        }
        if let saveButton = document?.querySelector("#siteTable div.thing[data-permalink=\"" + post.linkToThread + "\"] .buttons .save-button a") {
            saveButton.click()
            post.isSaved.toggle()
        }
        return true
    }
    
    private func updateTitle(doc: Document, defaultTitle: String) {
        if let newTitle = doc.querySelector(".pagename.redditname a")?.text {
            self.title = newTitle.prefix(1).capitalized + String(newTitle.dropFirst())
        } else {
            self.title = defaultTitle
        }
    }
    
    private func loadUsername(doc: Document) {
        if doc.querySelector("#header .logout")?.text != nil {
            self.userSessionManager.userName = doc.querySelector("#header .user a")!.text
//            userSessionManager.userName = self.userName
        }
    }
    
    private func updateCommunitiesList(doc: Document) {
        self.subscribedCommunities = []
        for element in doc.querySelectorAll("#sr-header-area .drop-choices a:not(.bottom-option)") {
            self.subscribedCommunities.append(Community(element.text!, link: element["href"]!,
                                                        iconName: nil, isMultiCommunity: false,
                                                        communityCode: "r/" + element.text!))
        }
        var unsortedCommunities: [Community] = []
        let communityElements = doc.querySelectorAll(".sr-list .flat-list.sr-bar:nth-of-type(n+2) li a")
        communityElements.indices.forEach { i in
            if i > 4 { // nth-of-type does not work here, skip manually
                let element = communityElements[i]
                unsortedCommunities.append(Community(element.text!, link: element["href"]!,
                                                     iconName: nil, isMultiCommunity: false,
                                                     communityCode: "r/" + element.text!))
            }
        }
        self.communities = []
        self.communities = unsortedCommunities
            .sorted { $0.name.lowercased() < $1.name.lowercased() }
    }
    
    var setMainPageCommunities: [Community] {
        var communities: [Community] = []
        communities.append(Community("Home", link: redditBaseURL,
                                                  iconName: "house.fill", isMultiCommunity: true, communityCode: ""))
        communities.append(Community("Popular Posts", link: redditBaseURL + "/r/popular",
                                                  iconName: "chart.line.uptrend.xyaxis.circle.fill",
                                                  isMultiCommunity: true, communityCode: "r/popular"))
        communities.append(Community("All Posts", link: redditBaseURL + "/r/all",
                                                  iconName: "a.circle.fill", isMultiCommunity: true,
                                                  communityCode: "r/all"))
        return communities
    }
    
    var setUserFunctionCommunities: [Community] {
        var communities: [Community] = []
        communities.append(Community("Saved", link: redditBaseURL + "/saved", iconName: "heart.text.square",
                                     isMultiCommunity: true, communityCode: "/saved"))
        communities.append(Community("Moderator Posts", link: redditBaseURL + "/mod", iconName: "shield",
                                     isMultiCommunity: true, communityCode: "/mod"))
        return communities
    }
    
    var selectedSortingIcon: String {
        ViewModelAttributes.sortModifierIcons[selectedSorting]!
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
