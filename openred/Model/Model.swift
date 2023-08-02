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
    
//    @Published var items: [PostOrComment] = []
    @Published var communities: [Community] = []
    @Published var subscribedCommunities: [Community] = []
//    @Published var title: String = ""
//    @Published var selectedCommunity: CommunityOrUser
//    @Published var selectedSorting: String = ""
//    @Published var selectedSortTime: String?
//    @Published var after: String?
    @Published var loginAttempt: LoginAttempt = .undecided
    @Published var messageCount: Int = 0
    var resetPagesToCommunity: String?
    
    let defaults = UserDefaults.standard
    let userSessionManager: UserSessionManager
//    let webView: WKWebView = WKWebView()
//    var browser: Erik //= Erik()
//    var document: Document? = nil
    let redditBaseURL: String = "https://old.reddit.com"
    var jsonLoader: JSONDataLoader = JSONDataLoader()
    
    init(userSessionManager: UserSessionManager) {
        self.userSessionManager = userSessionManager
        
//        self.jsonLoader = JSONDataLoader()
//        self.mainPageCommunities = mainPageCommunities
//        self.userFunctionCommunities = userFunctionCommunities
        self.pages["r/all"] = Page(target: CommunityOrUser(community: Community("all", iconName: nil, isMultiCommunity: true)),
                                   webView: userSessionManager.getWebView())
        self.userSessionManager.loadLastLoggedInUser(webView: pages["r/all"]!.webView)
//        self.browser = Erik(webView: self.webView)
        loadCommunity(community: pages["r/all"]!.selectedCommunity)
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
                                // failed login attempt
                                self.loginAttempt = .failed
                            } else {
                                self.loginAttempt = .successful
                                page.document = document
                                self.userSessionManager.userName = username
                                self.userSessionManager.saveUserSession(webView: page.webView, userName: username)
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
        // TODO: erase tabs and load some community
//        loadCommunity(community: selectedCommunity)
    }
    
    // 'communityCode': r/something
//    func loadCommunity(communityCode: String, sortBy: String? = nil, sortTime: String? = nil, after: String? = nil) {
//        let community = CommunityOrUser(community: Community("", iconName: nil, isMultiCommunity: false))
//        self.loadCommunity(community: community, sortBy: sortBy, sortTime: sortTime, after: after)
//    }
    
    // 'sortBy': top
    // 'sortTime': month
    // 'after': t3_14c4ene
    //  old.reddit.com/r/something/top/.json?sort=top&t=month&count=25&after=t3_14c4ene
//    func loadCommunity(community: CommunityOrUser, filter: String = "", sortBy: String? = nil, sortTime: String? = nil, after: String? = nil) {
//        self.selectedCommunity = community
//        self.selectedSortTime = sortTime
//        self.selectedSorting = ""
//
//        var components = URLComponents()
//        components.scheme = "https"
//        components.host = "old.reddit.com"
//        components.queryItems = []
//        if !community.isUser {
//            components.path = "/r/" + community.community!.name
//        } else {
//            components.path = "/user/" + community.user!.name
//            if filter != "" {
//                components.path = components.path + "/\(filter)"
//            }
//        }
//
//        if sortBy != nil {
//            self.selectedSorting = sortBy!
//            if !community.isUser {
//                components.path = components.path + "/" + sortBy!
//            }
//            components.queryItems?.append(URLQueryItem(name: "sort", value: sortBy!))
//            if sortTime != nil {
//                components.queryItems?.append(URLQueryItem(name: "t", value: sortTime!))
//            }
//        }
//
//        if after != nil {
//            components.queryItems?.append(URLQueryItem(name: "after", value: after!))
//        } else {
//            self.items = []
//        }
//
//        browser.visit(url: components.url! ) { object, error in
//            let defaultTitle = community.isUser ? community.user!.name : community.community!.name
//            if let doc = object {
//                if let nsfwButton = doc.querySelector(".interstitial form button[value=\"yes\"]") {
//                    nsfwButton.click()
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
//                        self.updateModel(doc, defaultTitle: defaultTitle)
//                    }
//                } else {
//                    self.updateModel(doc, defaultTitle: defaultTitle)
//                }
//            }
//        }
//
//        components.path = components.path + "/.json"
//        jsonLoader.loadItems(url: components.url!) { (items, after, error) in
//            DispatchQueue.main.async {
//                if let items = items {
//                    for i in items.indices {
//                        self.items.append(items[i])
//                    }
//                }
//                self.after = after
//            }
//        }
//    }
    
    func loadCommunity(community: CommunityOrUser, filter: String = "", sortBy: String? = nil, sortTime: String? = nil, after: String? = nil) {
        var page = pages[community.getCode()] ?? Page(target: community, webView: userSessionManager.getWebView())
        page.selectedSortTime = sortTime
        page.selectedSorting = ""
        
        var components = URLComponents()
        components.scheme = "https"
        components.host = "old.reddit.com"
        components.queryItems = []
        components.path = "/" + community.getCode()
        var baseComponents = components
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
            jsonLoader.loadAbout(url: aboutPageComponents.url!) { (about, error) in
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
            let community = self.subscribedCommunities.filter { $0.id.lowercased() == target.id.lowercased() }.first
            if community != nil {
                self.subscribedCommunities = self.subscribedCommunities.filter { $0.id.lowercased() != target.id.lowercased() }
            } else {
                self.subscribedCommunities.append(target.community!)
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
            let community = self.pages[self.resetPagesToCommunity!]
            var newPages: [String:Page] = [:]
            newPages[self.resetPagesToCommunity!] = community
            self.pages = newPages
        }
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
            
            self.updateCommunitiesList(doc: doc)
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
    
    private func updateCommunitiesList(doc: Document) {
        self.subscribedCommunities = []
        for element in doc.querySelectorAll("#sr-header-area .drop-choices a:not(.bottom-option)") {
            self.subscribedCommunities.append(Community(element.text!, iconName: nil, isMultiCommunity: false))
        }
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
        communities.append(Community("", iconName: "house.fill", isMultiCommunity: true, displayName: "Home"))
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
