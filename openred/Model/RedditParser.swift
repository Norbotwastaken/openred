//
//  RedditParser.swift
//  openred
//
//  Created by Norbert Antal on 6/16/23.
//

import Foundation
import Erik
import Kanna
import WebKit

struct RedditParser {
    func parsePosts(document: Document) -> [Post] {
        var posts: [Post] = []
        let elements = document.querySelectorAll("#siteTable div.thing:not(.promoted)")
//        elements.indices.forEach { i in
        for i in elements.indices {
            let element = elements[i]
            if element.className!.contains("comment") {
                // TODO: process comment elements (saved, user pages)
                continue
            }
            let title = element.querySelector(".entry .top-matter p.title a.title")?.text
            let flair = element.querySelector(".title .flairrichtext")?.text
            let community = element.querySelector(".entry .top-matter .tagline .subreddit")?.text // r/something
            let commentCount = element["data-comments-count"]
            let userName = element.querySelector(".entry .top-matter .tagline .author")?.text
            let submittedAge = self.formatPostAge(text: element.querySelector(".entry .tagline time")!.text!)
            let linkToThread = element["data-permalink"]
            let score = element["data-score"]
            var contentType: ContentType = .link
            var mediaLink: String?
            var externalLink = element["data-url"]
            var gallery: Gallery?
            var crosspost: Crosspost?
            let isActiveLoadMarker = (i == elements.count - 7)
            var thumbnailLink = element.querySelector(".thumbnail img")?["src"]
            if thumbnailLink != nil {
                thumbnailLink = "https:" + thumbnailLink!
            }
            let isUpvoted = element.querySelector("div.midcol.likes") != nil
            let isDownvoted = element.querySelector("div.midcol.dislikes") != nil
            let isSaved = element.className!.contains("saved")
            var awards: [Award] = []
            
            if let mediaElement = element.querySelector(".entry .expando") {
                let mediaContainerElement = mediaElement["data-cachedhtml"]
                if (mediaContainerElement != nil && mediaContainerElement!.contains("data-hls-url")) {
                    contentType = .video
                    mediaLink = mediaContainerElement!.components(separatedBy: "data-hls-url=\"")[1]
                        .components(separatedBy: "\"")[0]
                } else if (mediaContainerElement != nil && mediaContainerElement!.contains("type=\"video/mp4\"")) {
                    contentType = .gif
                    mediaLink = mediaContainerElement!.components(separatedBy: "<a href=\"")[1]
                        .components(separatedBy: "\"")[0]
                    if mediaLink!.contains("imgur.com") && mediaLink!.contains(".gifv") {
                        // gif from imgur, but it is an .mp4 video file
                        contentType = .video
                        mediaLink = String(mediaLink!.dropLast(4)) + "mp4"
                    }
                } else if element["data-is-gallery"] == "true" {
                    contentType = .gallery
                    var galleryItems: [GalleryItem] = []
                    if let doc = try? HTML(html: mediaContainerElement!, encoding: .utf8) {
                        for galleryElement in doc.css(".gallery-preview") {
                            let galleryPreviewElement = galleryElement.at_css(".media-preview-content a")
                            var galleryItemCaption = galleryElement.at_css(".gallery-item-caption")?.text
                            if galleryItemCaption != nil {
                                // remove "Caption: " prefix
                                galleryItemCaption = String(galleryItemCaption!.dropFirst(10))
                            }
                            let galleryItemPreviewLink = galleryPreviewElement!.at_css("img")!["src"]!
                                .replacingOccurrences(of: "&amp;", with: "&")
                            var galleryItemFullLink = galleryPreviewElement!["href"]!
                            if galleryItemFullLink.contains("preview.redd.it") {
                                galleryItemFullLink = galleryItemFullLink.replacingOccurrences(of: "&amp;", with: "&")
                            } else {
                                // could be any outside link
                                galleryItemFullLink = galleryItemPreviewLink
                            }
                            
                            galleryItems.append(GalleryItem(galleryItemPreviewLink,
                                                            fullLink: galleryItemFullLink, caption: galleryItemCaption))
                        }
                        let galleryTextHTML = doc.at_css(".usertext .md")?.innerHTML
                        gallery = Gallery(textHTML: galleryTextHTML, items: galleryItems)
                    }
                } else if let originalPostTitle = element["data-crosspost-root-title"] {
                    contentType = .crosspost
                    var originalPostLink = element["data-url"]!
                    let originalPostCommunityName = element["data-crosspost-root-subreddit"]! // without the /r/
                    let originalPostScore = element["data-crosspost-root-score"]!
                    let originalPostCommentCount = element["data-crosspost-root-num-comments"]!
                    let originalPostAge = self.formatPostAge(text: element["data-crosspost-root-time"]!)
                    if mediaContainerElement != nil, let doc = try? HTML(html: mediaContainerElement!, encoding: .utf8) {
                        originalPostLink = doc.at_css(".crosspost-preview-header a.content-link")!["href"]!
                        var externalLink = doc.at_css(".crosspost-preview-header a.outbound")?["href"]!
                    }

                    crosspost = Crosspost(originalPostLink, contentType: contentType,
                              communityName: originalPostCommunityName, title: originalPostTitle, score: originalPostScore,
                              commentCount: originalPostCommentCount, age: originalPostAge)
                } else if (mediaContainerElement != nil && mediaContainerElement!.contains("<a href")) {
                    contentType = .image
                    mediaLink = mediaContainerElement!.components(separatedBy: "<a href=\"")[1]
                        .components(separatedBy: "\"")[0]
                } else if (element["data-domain"] != nil && element["data-domain"]!.starts(with: "self.")) {
                    contentType = .text
                    // can not serve additional info on text posts
                }
            } else if let thumbnail = element.querySelector(".thumbnail") {
                if thumbnail["href"] != nil &&
                    thumbnail["href"]!.contains("imgur.com") && thumbnail["href"]!.contains(".gifv") {
                    contentType = .video // gif from imgur, but is a video file
                    mediaLink = String(thumbnail["href"]!.dropLast(4)) + "mp4"
                }
            } else {
                contentType = .link
                externalLink = element["data-url"]
            }
            
            for awardElement in element.querySelectorAll(".awardings-bar .awarding-link") {
                awards.append(Award(link: awardElement.querySelector("img.awarding-icon")!["src"]!, count: awardElement["data-count"]!))
            }
            
            posts.append(Post(linkToThread!,
                title: title ?? "no title for this post",
                flair: flair,
                community: community,
                commentCount: commentCount ?? "0",
                userName: userName,
                submittedAge: submittedAge,
                score: score ?? "0",
                contentType: contentType,
                mediaLink: mediaLink,
                thumbnailLink: thumbnailLink,
                externalLink: externalLink,
                gallery: gallery,
                crosspost: crosspost,
                isActiveLoadMarker: isActiveLoadMarker,
                isUpvoted: isUpvoted,
                isDownvoted: isDownvoted,
                isSaved: isSaved,
                awards: awards))
        }
        return posts
    }
    
    // Transform '3 hours ago' into '3h'
    private func formatPostAge(text: String) -> String {
        var postAgeSections = text.components(separatedBy: " ")
        if postAgeSections[0] == "an" {
            postAgeSections[0] = "1"
        }
        return postAgeSections[0] + postAgeSections[1].prefix(1)
    }
}
