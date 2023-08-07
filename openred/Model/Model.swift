//
//  Model.swift
//  openred
//
//  Created by Norbert Antal on 6/6/23.
//

import Erik
import WebKit

class Model: ObservableObject {
    @Published var pages: [String:Page] = [:]
    @Published var communities: [Community] = []
    @Published var favoriteCommunities: [Community] = []
    @Published var loginAttempt: LoginAttempt = .undecided
    @Published var messageCount: Int = 0
    var resetPagesToCommunity: String?
    
    let defaults = UserDefaults.standard
    let userSessionManager: UserSessionManager
    let redditBaseURL: String = "https://old.reddit.com"
    let jsonLoader: JSONDataLoader = JSONDataLoader()
    private let starterCommunity = CommunityOrUser(community: Community("all", iconName: nil, isMultiCommunity: true))
    
    init(userSessionManager: UserSessionManager) {
        self.userSessionManager = userSessionManager
        userSessionManager.createWebViewFor(viewName: starterCommunity.getCode())
        pages["r/all"] = Page(target: starterCommunity, webView: userSessionManager
            .getWebViewFor(viewName: starterCommunity.getCode()))
        loadCommunity(community: pages["r/all"]!.selectedCommunity)
        loadCommunitiesData()
    }
    
    func login(username: String, password: String) {
        let page = pages.first!.value
        if let form = page.document!.querySelector("#login_login-main") as? Form {
            if let usernameInput = form.querySelector("input[name=\"user\"]") {
                usernameInput["value"] = username
            }
            if let passwordInput = form.querySelector("input[name=\"passwd\"]") {
                passwordInput["value"] = password
            }
            page.document?.querySelector("#login_login-main .btn")?.click() { object, error in
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    page.browser.currentContent { (obj, err) -> Void in
                        if let document = obj {
                            if document.querySelector("#login_login-main .error") != nil {
                                self.loginAttempt = .failed
                            } else {
                                self.loginAttempt = .successful
                                page.document = document
                                self.userSessionManager.saveUserSession(webViewKey: page.selectedCommunity.getCode(), userName: username)
                                self.loadCommunitiesDataFromDoc(doc: document)
                                self.loadCommunitiesData() // doesn't work here for some reason
                            }
                        }
                    }
                }
            }
        }
    }
    
    func logOut() {
        userSessionManager.logOut()
        userSessionManager.createWebViewFor(viewName: starterCommunity.getCode())
        pages["r/all"] = Page(target: starterCommunity, webView: userSessionManager
            .getWebViewFor(viewName: starterCommunity.getCode()))
        loadCommunity(community: pages["r/all"]!.selectedCommunity)
        resetPagesTo(target: pages["r/all"]!.selectedCommunity)
//        pages = [:]
        communities = []
        favoriteCommunities = []
    }
    
    func switchAccountTo(userName: String) {
        userSessionManager.switchToAccount(userName: userName)
//        userSessionManager.createWebViewFor(viewName: starterCommunity.getCode())
//        pages["r/all"] = Page(target: starterCommunity, webView: userSessionManager
//            .getWebViewFor(viewName: starterCommunity.getCode()))
//        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
//            self.loadCommunity(community: self.pages["r/all"]!.selectedCommunity)
        pages = [:]
        self.loadCommunitiesData()
//            self.resetPagesTo(target: self.pages["r/all"]!.selectedCommunity)
//        }
    }
    
    // 'sortBy': top
    // 'sortTime': month
    // 'after': t3_14c4ene
    //  old.reddit.com/r/something/top/.json?sort=top&t=month&count=25&after=t3_14c4ene
    func loadCommunity(community: CommunityOrUser, filter: String = "", sortBy: String? = nil, sortTime: String? = nil, after: String? = nil) {
        if pages[community.getCode()] == nil {
            userSessionManager.createWebViewFor(viewName: community.getCode())
        }
        let page = pages[community.getCode()] ?? Page(target: community, webView: userSessionManager
            .getWebViewFor(viewName: community.getCode()))
        page.selectedSortTime = sortTime
        page.selectedSorting = ""
        
        var components = URLComponents()
        components.scheme = "https"
        components.host = "old.reddit.com"
        components.queryItems = []
        components.path = "/" + community.getCode()
        let baseComponents = components
        if !community.isUser && community.community?.path != nil {
            components.path = "/" + community.community!.path!
        }
        if community.isUser && filter != "" {
            components.path = components.path + "/\(filter)"
        }
        
        if sortBy != nil {
            page.selectedSorting = sortBy!
            if !community.isUser {
                components.path = components.path + "/" + sortBy!
            }
            components.queryItems?.append(URLQueryItem(name: "sort", value: sortBy!))
            if sortTime != nil {
                components.queryItems?.append(URLQueryItem(name: "t", value: sortTime!))
            }
        }
        
        if after != nil {
            components.queryItems?.append(URLQueryItem(name: "after", value: after!))
        } else {
            page.items = []
        }
        self.pages[community.getCode()] = page
        
        page.browser.visit(url: components.url! ) { object, error in
            let defaultTitle = community.isUser ? community.user!.name : community.community!.name
            if let doc = object {
                if let nsfwButton = doc.querySelector(".interstitial form button[value=\"yes\"]") {
                    nsfwButton.click()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                        self.updateModel(community.getCode(), doc: doc, defaultTitle: defaultTitle)
                    }
                } else {
                    self.updateModel(community.getCode(), doc: doc, defaultTitle: defaultTitle)
                }
            }
        }
        
        components.path = components.path + "/.json"
        jsonLoader.loadItems(url: components.url!) { (items, after, error) in
            DispatchQueue.main.async {
                if let items = items {
                    for i in items.indices {
                        page.items.append(items[i])
                    }
                }
                page.after = after
                self.pages[community.getCode()] = page
            }
        }
        
        if !community.isUser && !community.isMultiCommunity {
            var aboutPageComponents = baseComponents
            aboutPageComponents.path = aboutPageComponents.path + "/about.json"
            jsonLoader.loadAboutCommunity(url: aboutPageComponents.url!) { (about, error) in
                DispatchQueue.main.async {
                    if let about = about {
                        self.pages[community.getCode()]?.selectedCommunity.community!.about = about
                    }
                }
            }
            var rulesPageComponents = baseComponents
            rulesPageComponents.path = rulesPageComponents.path + "/about/rules.json"
            jsonLoader.loadRules(url: rulesPageComponents.url!) { (rules, error) in
                DispatchQueue.main.async {
                    if let rules = rules {
                        self.pages[community.getCode()]?.selectedCommunity.community!.rules = rules
                    }
                }
            }
        } else if community.isUser {
            var aboutUserPageComponents = baseComponents
            aboutUserPageComponents.path = aboutUserPageComponents.path + "/about.json"
            jsonLoader.loadAboutUser(url: aboutUserPageComponents.url!) { (about, error) in
                DispatchQueue.main.async {
                    if let about = about {
                        self.pages[community.getCode()]?.selectedCommunity.user!.about = about
                    }
                }
            }
            var trophiesPageComponents = baseComponents
            trophiesPageComponents.path = trophiesPageComponents.path + "/trophies.json"
            jsonLoader.loadTrophies(url: trophiesPageComponents.url!) { (trophies, error) in
                DispatchQueue.main.async {
                    if let trophies = trophies {
                        self.pages[community.getCode()]?.selectedCommunity.user!.trophies = trophies
                    }
                }
            }
        }
    }
    
    func loadNextPagePosts(target: String) {
        let page = self.pages[target]!
        if page.after != nil {
            loadCommunity(community: page.selectedCommunity, sortBy: page.selectedSorting,
                          sortTime: page.selectedSortTime, after: page.after)
        }
    }
    
    func toggleUpvotePost(target: String, post: Post) -> Bool {
        if self.userSessionManager.userName == nil {
            return false
        }
        let selectorModifier = post.isUpvoted ? "mod" : ""
        if let upvoteButton = self.pages[target]!.document?
            .querySelector("#siteTable div.thing[data-permalink=\"" + post.linkToThread + "\"] div.arrow.up" + selectorModifier) {
            upvoteButton.click()
            post.isUpvoted.toggle()
            post.isDownvoted = false
            self.pages[target]!.browser.currentContent { (obj, err) -> Void in
                if let document = obj {
                    self.pages[target]!.document = document
                }
            }
            return true
        }
        return false
    }
    
    func toggleDownvotePost(target: String, post: Post) -> Bool {
        if self.userSessionManager.userName == nil {
            return false
        }
        let selectorModifier = post.isDownvoted ? "mod" : ""
        if let downvoteButton = self.pages[target]!.document?
            .querySelector("#siteTable div.thing[data-permalink=\"" + post.linkToThread + "\"] div.arrow.down" + selectorModifier) {
            downvoteButton.click()
            post.isDownvoted.toggle()
            post.isUpvoted = false
            self.pages[target]!.browser.currentContent { (obj, err) -> Void in
                if let document = obj {
                    self.pages[target]!.document = document
                }
            }
        }
        return true
    }
    
    func toggleSavePost(target: String, post: Post) -> Bool {
        if self.userSessionManager.userName == nil {
            return false
        }
        if let saveButton = self.pages[target]!.document?.querySelector("#siteTable div.thing[data-permalink=\"" + post.linkToThread + "\"] .buttons .save-button a") {
            saveButton.click()
            post.isSaved.toggle()
        }
        return true
    }
    
    func toggleSubscribe(target: CommunityOrUser) -> Bool {
        if self.userSessionManager.userName == nil {
            return false
        }
        if let subscribeButton = self.pages[target.getCode()]!.document?.querySelectorAll(".subscribe-button a").first {
            subscribeButton.click()
            let community = self.communities.filter { $0.id.lowercased() == target.id.lowercased() }.first
            if community != nil {
                self.communities = self.communities.filter { $0.id.lowercased() != target.id.lowercased() }
            } else {
                self.communities.append(target.community!)
            }
        }
        return true
    }
    
    func toggleFriend(target: CommunityOrUser) -> Bool {
        if self.userSessionManager.userName == nil {
            return false
        }
        if self.pages[target.getCode()]!.selectedCommunity.isUser {
            if let toggleButton = self.pages[target.getCode()]!.document?.querySelectorAll(".titlebox .fancy-toggle-button a.active").first {
                toggleButton.click()
                self.pages[target.getCode()]!.selectedCommunity.user!.about!.is_friend.toggle()
                objectWillChange.send()
            }
            return true
        }
        return false
    }
    
    func blockUser(target: CommunityOrUser) -> Bool {
        if userSessionManager.userName == nil {
            return false
        }
        if self.pages[target.getCode()]!.selectedCommunity.isUser {
            if let toggleButton = self.pages[target.getCode()]!.document!.querySelector(".titlebox .block_user-button .error a.yes") {
                toggleButton.click()
                self.pages[target.getCode()]!.selectedCommunity.user!.about!.is_blocked = true
                objectWillChange.send()
                return true
            }
        }
        return false
    }
    
    func resetPagesTo(target: CommunityOrUser) {
        resetPagesToCommunity = target.getCode()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            let keysToDelete: [String] = self.pages.keys.filter{ $0 != self.resetPagesToCommunity! }
            let community = self.pages[self.resetPagesToCommunity!]
            var newPages: [String:Page] = [:]
            newPages[self.resetPagesToCommunity!] = community
            self.pages = newPages
            self.userSessionManager.removeWebViews(keys: keysToDelete)
        }
    }
    
    func loadCommunitiesData() {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "old.reddit.com"
        components.queryItems = []
        components.path = "/subreddits/mine/.json"
        jsonLoader.loadAboutCommunities(url: components.url!) { (abouts, error) in
            DispatchQueue.main.async {
                if let abouts = abouts {
                    self.communities = abouts
                        .map{ Community($0.displayName, iconURL: $0.communityIcon!, isMultiCommunity: false) }
                        .sorted { $0.name.lowercased() < $1.name.lowercased() }
                    self.favoriteCommunities = []
                    for name in self.userSessionManager.favoriteCommunities {
                        let c = self.communities.filter{ $0.name.lowercased() == name.lowercased() }.first
                        c?.isFavorite = true
                        if c != nil {self.favoriteCommunities.append(c!)}
                    }
                }
            }
        }
    }
    
    func toggleAsFavoriteCommunity(community: Community) {
        community.isFavorite.toggle()
        let difference = favoriteCommunities.filter{ $0.name.lowercased() != community.name.lowercased() }
        if (difference.count == favoriteCommunities.count) {
            favoriteCommunities.append(community)
        } else {
            favoriteCommunities = difference
        }
        userSessionManager.setFavoriteCommunities(favoriteCommunities.map{ $0.name.lowercased() })
    }
    
    private func updateModel(_ target: String, doc: Document, defaultTitle: String) {
        if let page = self.pages[target] {
            page.document = doc
            if let newTitle = doc.querySelector(".pagename.redditname a")?.text {
                page.title = newTitle.prefix(1).capitalized + String(newTitle.dropFirst())
            } else {
                page.title = defaultTitle
            }
            self.pages[target] = page
            
//            self.updateCommunitiesList(doc: doc)
            self.loadUsername(doc: doc)
            self.updateMessageCount(doc: doc)
        }
    }
    
    private func updateMessageCount(doc: Document) {
        if let count = doc.querySelector(".message-count")?.text {
            self.messageCount = Int(count)!
        } else {
            self.messageCount = 0
        }
    }
    
    private func loadUsername(doc: Document) {
        if doc.querySelector("#header .logout")?.text != nil {
            self.userSessionManager.userName = doc.querySelector("#header .user a")!.text
        }
    }
    
    private func loadCommunitiesDataFromDoc(doc: Document) {
        var unsortedCommunities: [Community] = []
        let communityElements = doc.querySelectorAll(".sr-list .flat-list.sr-bar:nth-of-type(n+2) li a")
        communityElements.indices.forEach { i in
            if i > 4 { // nth-of-type does not work here, skip manually
                let element = communityElements[i]
                unsortedCommunities.append(Community(element.text!, iconName: nil, isMultiCommunity: false))
            }
        }
        self.communities = []
        self.communities = unsortedCommunities
            .sorted { $0.name.lowercased() < $1.name.lowercased() }
    }
    
    var mainPageCommunities: [Community] {
        var communities: [Community] = []
        communities.append(Community("", iconName: "house.fill", isMultiCommunity: true, displayName: "Home", path: ""))
        communities.append(Community("Popular", iconName: "chart.line.uptrend.xyaxis.circle.fill",
                                     isMultiCommunity: true, displayName: "Popular Posts"))
        communities.append(Community("All", iconName: "a.circle.fill",
                                     isMultiCommunity: true, displayName: "All Posts"))
        return communities
    }
    
    var userFunctionCommunities: [Community] {
        var communities: [Community] = []
        communities.append(Community("Saved", iconName: "heart.text.square", isMultiCommunity: true, displayName: "Saved", path: "saved"))
        communities.append(Community("Mod", iconName: "shield", isMultiCommunity: true, displayName: "Moderator Posts"))
        return communities
    }
    
    func selectedSortingIcon(target: String) -> String {
//        if pages[target] != nil {
            return ViewModelAttributes.sortModifierIcons[pages[target]!.selectedSorting]!
//        } else {
//            return ViewModelAttributes.sortModifierIcons[""]!
//        }
    }
    
    var userName: String? {
        self.userSessionManager.userName
    }
    
    var savedUserNames: [String] {
        self.userSessionManager.userNames
            .filter{ $0.lowercased() != userName?.lowercased() }
            .sorted { $0.lowercased() < $1.lowercased() }
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

class Page: ObservableObject {
    @Published var items: [PostOrComment]
    @Published var title: String = ""
    @Published var selectedCommunity: CommunityOrUser
    @Published var selectedSorting: String = ""
    @Published var selectedSortTime: String?
    @Published var after: String?
    
    let webView: WKWebView
    var browser: Erik
    var document: Document?
    
    init(target: CommunityOrUser, webView: WKWebView) {
        self.selectedCommunity = target
        self.items = []
        self.webView = webView
        self.browser = Erik(webView: self.webView)
    }
}
