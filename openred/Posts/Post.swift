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
    var submittedAge: String
    var linkToThread: String
    var score: String
    var contentType: ContentType
    var mediaLink: String?
    var thumbnailLink: String?
    var externalLink: String?
    var gallery: Gallery?
    var crosspost: Crosspost?
    var isActiveLoadMarker: Bool
    @Published var isUpvoted: Bool
    @Published var isDownvoted: Bool
    var awards: [Award]
    private var totalAwardCount: Int?
    
    init(_ linkToThread: String, title: String, flair: String?, community: String?, commentCount: String,
         userName: String?, submittedAge: String, score: String, contentType: ContentType,
         mediaLink: String?, thumbnailLink: String?, externalLink: String?, gallery: Gallery?, crosspost: Crosspost?,
         isActiveLoadMarker: Bool, isUpvoted: Bool, isDownvoted: Bool, awards: [Award]) {
        self.id = linkToThread
        self.title = title
        self.flair = flair
        self.community = community
        self.commentCount = commentCount
        self.userName = userName
        self.submittedAge = submittedAge
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
