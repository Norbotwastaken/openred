//
//  List.swift
//  openred
//
//  Created by Norbert Antal on 6/6/23.
//

import Foundation

class Post: Identifiable, ObservableObject {
    var id: String
    var title: String
    var flair: String?
    var community: String?
    var commentCount: String
    var userName: String?
    var displayAge: String
    var linkToThread: String
    var score: String
    var contentType: ContentType
    
    var mediaLink: String?
    var imagePreviewLink: String?
    var imageLink: String?
    var videoLink: String?
    
    var thumbnailLink: String?
    var externalLink: String?
    var externalLinkDomain: String?
    var text: String?
    var gallery: Gallery?
    var crosspost: Crosspost?
    var crosspostAsPost: Post?
    var isActiveLoadMarker: Bool
    @Published var isUpvoted: Bool
    @Published var isDownvoted: Bool
    @Published var isSaved: Bool
    var awards: [Award]
    private var totalAwardCount: Int?
    
    init(jsonPost: JSONPost, isActiveLoadMarker: Bool = false) {
        self.id = jsonPost.id
        self.title = jsonPost.title!
        self.thumbnailLink = jsonPost.thumbnail
        self.externalLink = jsonPost.url
        self.isActiveLoadMarker = isActiveLoadMarker
        self.isUpvoted = jsonPost.likes != nil ? jsonPost.likes! : false
        self.isDownvoted = jsonPost.likes != nil ? !jsonPost.likes! : false
        self.isSaved = jsonPost.saved
        self.flair = jsonPost.link_flair_text
        self.community = jsonPost.subreddit_name_prefixed
        self.commentCount = String(jsonPost.num_comments)
        self.userName = jsonPost.author
        self.linkToThread = jsonPost.permalink
        self.score = String(jsonPost.score)
        self.text = jsonPost.selftext ?? ""
        self.contentType = ContentType.text // !
        if (jsonPost.is_self) {
            self.contentType = ContentType.text
        }
        else if (jsonPost.is_gallery != nil && jsonPost.is_gallery!) {
            self.contentType = ContentType.gallery
            self.gallery = Gallery(galleryData: jsonPost.gallery_data!.items,
                                   galleryItems: jsonPost.media_metadata!.galleryItems.elements,
                                   text: jsonPost.selftext)
        }
        else if (jsonPost.is_video != nil && jsonPost.is_video!) {
            // post_hint == hosted:video
            self.contentType = ContentType.video
            self.videoLink = jsonPost.media?.reddit_video.hls_url
        }
        else if (jsonPost.crosspost_parent_list != nil
                 && !jsonPost.crosspost_parent_list!.isEmpty) {
            self.contentType = ContentType.crosspost
            self.crosspostAsPost = Post(jsonPost: jsonPost.crosspost_parent_list![0])
        }
        else if (jsonPost.post_hint != nil && jsonPost.post_hint! == "image") {
            self.contentType = ContentType.image
            if (jsonPost.preview?.images[0].variants?.mp4 != nil) {
                self.contentType = ContentType.video // or gif?
            } else {
                var jsonImage = jsonPost.preview?.images[0]
                self.imageLink = jsonImage!.source.url
                self.imagePreviewLink = jsonImage!.resolutions[jsonImage!.resolutions.count - 2].url
            }
        }
        else if (jsonPost.post_hint == nil) {
            self.contentType = ContentType.link
            self.externalLink = jsonPost.url
            self.externalLinkDomain = jsonPost.domain
        }
        
        self.awards = []
        self.displayAge = ""
        self.displayAge = readableAge(difference: jsonPost.created)
    }
    
    init(_ linkToThread: String, title: String, flair: String?, community: String?, commentCount: String,
         userName: String?, submittedAge: String, score: String, contentType: ContentType,
         mediaLink: String?, thumbnailLink: String?, externalLink: String?, gallery: Gallery?, crosspost: Crosspost?,
         isActiveLoadMarker: Bool, isUpvoted: Bool, isDownvoted: Bool, isSaved: Bool, awards: [Award]) {
        self.id = linkToThread
        self.title = title
        self.flair = flair
        self.community = community
        self.commentCount = commentCount
        self.userName = userName
        self.displayAge = submittedAge
        self.linkToThread = linkToThread
        self.score = score
        self.contentType = contentType
        self.mediaLink = mediaLink
        self.thumbnailLink = thumbnailLink
        self.externalLink = externalLink
        self.gallery = gallery
        self.crosspost = crosspost
        self.isActiveLoadMarker = isActiveLoadMarker
        self.isUpvoted = isUpvoted
        self.isDownvoted = isDownvoted
        self.isSaved = isSaved
        self.awards = awards
    }
    
    func deactivateLoadMarker() {
        self.isActiveLoadMarker = false
    }
    
    func getTotalAwardCount() -> Int {
        if self.totalAwardCount != nil {
            return self.totalAwardCount!
        }
        self.totalAwardCount = self.awards.map({ Int($0.count)! }).reduce(0, +)
        return self.totalAwardCount!
    }
    
    func readableAge(difference: Double) -> String {
        let date = Date().addingTimeInterval(difference)
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
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
