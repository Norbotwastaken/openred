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
    @Published var linkToNextPage: String?
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
        if let userIndicatorElement = doc.querySelector("#header .logout")?.text {
            self.userName = doc.querySelector("#header .user a")!.text
        }
    }
    
    private func updatePosts(doc: Document, appendToExisting: Bool = false) {
        if !appendToExisting {
            self.posts = []
        }
        
        for element in doc.querySelectorAll("#siteTable div.thing:not(.promoted)") {
            if (element["data-is-gallery"] == "true") {
                element.querySelector(".expando-button")?.click()
            }
            if (element["data-domain"] != nil && element["data-domain"]!.starts(with: "self.")) {
                // regular text (or self) post
                element.querySelector(".expando-button")?.click()
            }
            // TODO: crossposts
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.browser.currentContent { (obj, err) -> Void in
                if let document = obj {
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
                        var textContentHTML: String?
                        var galleryLinks: [String] = []
                        var thumbnailLink = element.querySelector(".thumbnail img")?["src"]
                        if thumbnailLink != nil {
                            thumbnailLink = "https:" + thumbnailLink!
                        }
                        
                        if let mediaElement = element.querySelector(".entry .expando") {
                            let mediaContainerString = mediaElement["data-cachedhtml"]
                            if (mediaContainerString != nil && mediaContainerString!.contains("data-hls-url")) {
                                contentType = .video
                                mediaLink = mediaContainerString!.components(separatedBy: "data-hls-url=\"")[1]
                                    .components(separatedBy: "\"")[0]
                            } else if (mediaContainerString != nil && mediaContainerString!.contains("type=\"video/mp4\"")) {
                                contentType = .gif
                                mediaLink = mediaContainerString!.components(separatedBy: "<a href=\"")[1]
                                    .components(separatedBy: "\"")[0]
                                if mediaLink!.contains("imgur.com") && mediaLink!.contains(".gifv") {
                                    // gif from imgur, but it is an .mp4 video file
                                    contentType = .video
                                    mediaLink = String(mediaLink!.dropLast(4)) + "mp4"
                                }
                            } else if (mediaContainerString != nil && mediaContainerString!.contains("<a href")) {
                                contentType = .image
                                mediaLink = mediaContainerString!.components(separatedBy: "<a href=\"")[1]
                                    .components(separatedBy: "\"")[0]
                            } else if element["data-is-gallery"] == "true" {
                                contentType = .gallery
                                for galleryElement in mediaElement.querySelectorAll(".gallery-preview .media-preview-content a") {
                                    galleryLinks.append(galleryElement["href"] ?? "")
                                }
                                textContentHTML = mediaElement.querySelectorAll(".usertext-body .md").innerHTML
                            } else if (element["data-domain"] != nil && element["data-domain"]!.starts(with: "self.")) {
                                contentType = .text
                                textContentHTML = mediaElement.querySelectorAll(".usertext-body .md").innerHTML
                                
                            }
                        } else if let thumbnail = element.querySelector(".thumbnail") {
                            if thumbnail["href"] != nil &&
                                thumbnail["href"]!.contains("imgur.com") && thumbnail["href"]!.contains(".gifv") {
                                contentType = .video // gif from imgur, but is a video file
                                mediaLink = String(thumbnail["href"]!.dropLast(4)) + "mp4"
                            }
            //                else if thumbnail["href"] != nil && thumbnail["href"]!.contains("reddit.com/gallery") {
            //                    contentType = .gallery
            //                    element.querySelector(".expando-button")?.click() { object, error in
            //                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            //                            self.browser.currentContent { (obj, err) -> Void in
            //                                if let document = obj {
            //
            //                                }
            //                            }
            //                        }
            //                    }
            //                }
                        }
                        // else it is an external link
                        
                        // Transform '3 hours ago' into '3h'
                        if let postAgeSections = submittedAge?.components(separatedBy: " ") {
                            submittedAge = postAgeSections[0] + postAgeSections[1].prefix(1)
                        }
                        
                        self.posts.append(Post(linkToThread!, title: title ?? "no title for this post",
                                          community: community,
                                          commentCount: commentCount ?? "0",
                                          userName: userName ?? "",
                                          submittedAge: submittedAge ?? "",
                                          score: score ?? "0",
                                          contentType: contentType,
                                          mediaLink: mediaLink,
                                          thumbnailLink: thumbnailLink,
                                          galleryLinks: galleryLinks,
                                          textContent: textContentHTML))
                    }
                }
            }
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
    
    func storeCookies() {
        let userDefaults = UserDefaults.standard
        var cookieDict = [String : AnyObject]()
        
        webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
            for cookie in cookies {
                cookieDict[cookie.name] = cookie.properties as AnyObject?
            }
            userDefaults.set(cookieDict, forKey: "cookies")
        }
    }
    
    func restoreCookies() {
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
