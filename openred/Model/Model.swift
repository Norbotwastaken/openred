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
    @Published var mainPageCommunities: [Community] = []
    @Published var userFunctionCommunities: [Community] = []
    @Published var title: String
    @Published var selectedCommunityLink: String
    @Published var selectedSorting: String
    @Published var selectedSortingIcon: String
    @Published var userName: String?
    @Published var loginAttempt: LoginAttempt = .undecided
    
    let defaults = UserDefaults.standard
    let webView = WKWebView()
    var browser: Erik = Erik()
    var document: Document? = nil
    let redditBaseURL: String = "https://old.reddit.com"
    
    init() {
//        self.browser = Erik(webView: self.webView)
        self.title = ""
        self.selectedCommunityLink = redditBaseURL + "/r/all"
        self.selectedSorting = ""
        self.selectedSortingIcon = ViewModelAttributes.sortModifierIcons[""]!
//        loadCookies()
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
                                self.saveCookies()
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
//        if selectedCommunityLink.hasSuffix("/") {
//            selectedCommunityLink = String(selectedCommunityLink.dropLast())
//        }
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
    
    private func updateTitle(doc: Document, defaultTitle: String) {
        if let newTitle = doc.querySelector(".pagename.redditname a")?.text {
            self.title = newTitle.prefix(1).capitalized + String(newTitle.dropFirst())
        } else {
            self.title = defaultTitle
        }
    }
    
    private func updatePosts(doc: Document) {
        self.posts = []
        
        for element in doc.querySelectorAll("#siteTable div.thing:not(.promoted)") {
            let title = element.querySelector(".entry .top-matter p.title a.title")?.text
            let community = element.querySelector(".entry .top-matter .tagline .subreddit")?.text // r/something
            let commentCount = element["data-comments-count"]
            let userName = element.querySelector(".entry .top-matter .tagline .author")?.text
            var submittedAge = element.querySelector(".entry .tagline .live-timestamp")?.text
            let linkToThread = element["data-permalink"]
            let score = element["data-score"]
            var contentType: ContentType = .link
            var mediaLink: String?
            var thumbnailLink = element.querySelector(".thumbnail img")?["src"]
            if thumbnailLink != nil {
                thumbnailLink = "https:" + thumbnailLink!
            }
            // data-is-gallery="true" Tag for galleries
            // TODO: handle crossposts
            
            if let mediaElement = element.querySelector(".entry .expando") {
                let mediaContainerString = mediaElement["data-cachedhtml"]
                if (mediaContainerString != nil && mediaContainerString!.contains("data-hls-url")) {
                    contentType = .video
                    mediaLink = mediaContainerString!.components(separatedBy: "data-hls-url=\"")[1]
                        .components(separatedBy: "\"")[0]
//                    if thumbnailLink!.hasPrefix("//") {
//                        thumbnailLink = String(thumbnailLink!.dropFirst(2))
//                    }
                } else if (mediaContainerString != nil && mediaContainerString!.contains("<a href")) {
                    contentType = .image
                    mediaLink = mediaContainerString!.components(separatedBy: "<a href=\"")[1]
                        .components(separatedBy: "\"")[0]
                } else {
                    contentType = .text
                }
            } // else it is an external link
            
            // Transform '3 hours ago' into '3h'
            if let postAgeSections = submittedAge?.components(separatedBy: " ") {
                submittedAge = postAgeSections[0] + postAgeSections[1].prefix(1)
            }
            
            posts.append(Post(linkToThread!, title: title ?? "no title for this post",
                              community: community,
                              commentCount: commentCount ?? "0",
                              userName: userName ?? "",
                              submittedAge: submittedAge ?? "",
                              score: score ?? "0",
                              contentType: contentType,
                              mediaLink: mediaLink,
                              thumbnailLink: thumbnailLink))
        }
    }
    
    private func updateCommunitiesList(doc: Document) {
        var unsortedCommunities: [Community] = []
        for element in doc.querySelectorAll(".sr-list .flat-list.sr-bar:nth-of-type(n+2) li a") {
            let communityLink = element["href"]
            if let communityName = element.text {
                unsortedCommunities.append(Community(communityName,link: communityLink ?? "no link",
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
    
    private func saveCookies() {
        self.webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
            cookies.forEach { cookie in
                cookie.archive()
            }
//            if let encoded = try? JSONEncoder().encode(cookies) {
//                self.defaults.set(cookies, forKey: "cookies")
//            }
//            self.defaults.set(cookies, forKey: "cookies")
        }
    }
//
    private func loadCookies() {
        HTTPCookie.loadCookie(using: <#T##Data?#>)
//        let savedCookies = defaults.object(forKey: "cookies") as? [HTTPCookie] ?? [HTTPCookie]()
//        for cookie in savedCookies {
//            webView.configuration.websiteDataStore.httpCookieStore.setCookie(cookie)
//        }
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

extension HTTPCookie {

    fileprivate func save(cookieProperties: [HTTPCookiePropertyKey : Any]) -> Data {
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: cookieProperties, requiringSecureCoding: false)
            return data
        } catch {
            
        }
        return Data()
    }

    static fileprivate func loadCookieProperties(from data: Data) -> [HTTPCookiePropertyKey : Any]? {
        let unarchivedDictionary = NSKeyedUnarchiver.unarchiveObject(with: data)
        return unarchivedDictionary as? [HTTPCookiePropertyKey : Any]
    }

    static func loadCookie(using data: Data?) -> HTTPCookie? {
        guard let data = data,
            let properties = loadCookieProperties(from: data) else {
                return nil
        }
        return HTTPCookie(properties: properties)

    }

    func archive() -> Data? {
        guard let properties = self.properties else {
            return nil
        }
        return save(cookieProperties: properties)
    }

}
