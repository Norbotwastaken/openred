//
//  List.swift
//  openred
//
//  Created by Norbert Antal on 6/6/23.
//

import Foundation

class PostOrComment: Identifiable, ObservableObject {
    var id: String
    var post: Post?
    var comment: Comment?
    var isComment: Bool
    var isActiveLoadMarker: Bool
    var isAdMarker: Bool
    
    init(post: Post, isActiveLoadMarker: Bool = false, isAdMarker: Bool = false) {
        self.post = post
        self.isComment = false
        self.id = post.id
        self.isActiveLoadMarker = isActiveLoadMarker
        self.isAdMarker = isAdMarker
    }
    init(comment: Comment, isActiveLoadMarker: Bool = false, isAdMarker: Bool = false) {
        self.comment = comment
        self.isComment = true
        self.id = comment.id
        self.isActiveLoadMarker = isActiveLoadMarker
        self.isAdMarker = isAdMarker
    }
    
    func deactivateLoadMarker() {
        self.isActiveLoadMarker = false
    }
}

class Post: Identifiable, ObservableObject {
    var id: String
    var title: String
    var flair: String?
    var community: String?
    var communityCode: String
    var commentCount: String
    var userName: String?
    var displayAge: String
    var linkToThread: String
    var score: String
    var contentType: ContentType
    
//    var mediaLink: String?
    var imagePreviewLink: String?
    var imageLink: String?
    var videoLink: String?
    var embeddedMediaHtml: String?
    
    var thumbnailLink: String?
    var externalLink: String?
    var externalLinkDomain: String?
    var text: AttributedString?
    var gallery: Gallery?
    var crosspost: Post?
    var stickied: Bool
//    var crosspostAsPost: Post?
    @Published var isUpvoted: Bool
    @Published var isDownvoted: Bool
    @Published var isSaved: Bool
    var upvoteRatio: Double = 0
    var awardLinks: [String] = []
    var awardCount: Int
    var nsfw: Bool
    var spoiler: Bool
//    private var totalAwardCount: Int?
    
    init(jsonPost: JSONPost) {
        self.id = jsonPost.id
        self.title = jsonPost.title!
        self.thumbnailLink = jsonPost.thumbnail
        self.externalLink = jsonPost.url
        
        self.stickied = jsonPost.stickied
        self.isUpvoted = jsonPost.likes != nil ? jsonPost.likes! : false
        self.isDownvoted = jsonPost.likes != nil ? !jsonPost.likes! : false
        self.isSaved = jsonPost.saved
        self.flair = jsonPost.flair
        self.community = jsonPost.subreddit
        self.communityCode = jsonPost.subreddit_name_prefixed!
        self.commentCount = String(jsonPost.num_comments)
        self.userName = jsonPost.author
        self.linkToThread = jsonPost.permalink
        self.score = String(jsonPost.score)
        self.text = jsonPost.selftext ?? ""
        self.upvoteRatio = jsonPost.upvote_ratio ?? 0
        
        for award in jsonPost.all_awardings {
            self.awardLinks.append(award.resized_icons![1].url)
        }
        self.awardCount = jsonPost.total_awards_received
        
        if jsonPost.preview?.images.isEmpty == false {
            let jsonImage = jsonPost.preview?.images[0]
            self.imageLink = jsonImage!.source.url
            self.imagePreviewLink = !jsonImage!.resolutions.isEmpty ?
            jsonImage!.resolutions[jsonImage!.resolutions.count - 1].url : jsonImage!.source.url
        }
        
        self.contentType = ContentType.text
        if (jsonPost.is_self) {
            self.contentType = ContentType.text
        }
        else if (jsonPost.crosspost_parent_list != nil
                 && !jsonPost.crosspost_parent_list!.isEmpty) {
            self.contentType = ContentType.crosspost
            self.crosspost = Post(jsonPost: jsonPost.crosspost_parent_list![0])
        }
        else if (jsonPost.is_gallery != nil && jsonPost.is_gallery! &&
                 jsonPost.gallery_data != nil && jsonPost.media_metadata != nil) {
            self.contentType = ContentType.gallery
            self.gallery = Gallery(galleryData: jsonPost.gallery_data!.items,
                                   galleryItems: jsonPost.media_metadata!.elements,
                                   text: jsonPost.selftext)
        }
        else if (jsonPost.is_video != nil && jsonPost.is_video!) {
            // post_hint == hosted:video
            self.contentType = ContentType.video
            self.videoLink = jsonPost.media?.reddit_video!.hls_url
        }
        else if (jsonPost.post_hint == "image") {
            self.contentType = ContentType.image
            if (jsonPost.preview?.images[0].variants?.mp4 != nil) {
                self.contentType = ContentType.gif // or gif?
                let gifResolutions = jsonPost.preview?.images[0].variants?.gif?.resolutions
                if !gifResolutions!.isEmpty {
                    self.videoLink = gifResolutions![max(gifResolutions!.count - 2, 0)].url
                }
            }
        }
        else if (jsonPost.post_hint == "rich:video") {
            self.contentType = ContentType.video
            self.videoLink = jsonPost.url
            
            let iframeHosts = ["redgifs.com"]
            if jsonPost.media_embed != nil && jsonPost.media_embed!.content != nil &&
                (iframeHosts.filter{ jsonPost.media_embed!.content!.contains($0) }.first != nil) {
                // Display in a WKWebview
                self.embeddedMediaHtml = jsonPost.media_embed!.content!
            }
            let specialHosts = ["youtu.be", "youtube.com"]
            if jsonPost.url != nil && (specialHosts.filter{ jsonPost.url!.contains($0) }.first != nil) {
                // Display in an in-app Safari tab
                self.contentType = .link
            }
        }
        else if (jsonPost.post_hint == nil || jsonPost.post_hint == "link") {
            if jsonPost.url!.contains("imgur.com") && jsonPost.url!.contains(".gifv") {
                contentType = .video // gif from imgur, but is a video file
                videoLink = String(jsonPost.url!.dropLast(4)) + "mp4"
            } else {
                self.contentType = ContentType.link
                self.externalLink = jsonPost.url
                self.externalLinkDomain = jsonPost.domain
            }
        }
        
        self.nsfw = jsonPost.over_18
        self.spoiler = jsonPost.spoiler
        self.displayAge = ""
        self.displayAge = displayAge(Date(timeIntervalSince1970: TimeInterval(jsonPost.created)).timeAgoDisplay())
    }
    
    func displayAge(_ formattedTime: String) -> String {
        let timeSections = formattedTime.components(separatedBy: " ")
        return timeSections[0] + timeSections[1].prefix(1)
    }
}

struct Crosspost: Identifiable, Codable {
    var id: String
    var originalPostLink: String
    var contentType: ContentType
    var communityName: String // without the /r/
    var title: String
    var score: String
    var commentCount: String
    var age: String
    
    init(_ originalPostLink: String, contentType: ContentType, communityName: String, title: String, score: String, commentCount: String, age: String) {
        self.id = originalPostLink
        self.originalPostLink = originalPostLink
        self.contentType = contentType
        self.communityName = communityName
        self.title = title
        self.score = score
        self.commentCount = commentCount
        self.age = age
    }
}

struct Award {
    var link: String
    var count: String
}

enum ContentType: Codable {
    case text
    case image
    case gallery
    case video
    case gif
    case link
    case crosspost
}
