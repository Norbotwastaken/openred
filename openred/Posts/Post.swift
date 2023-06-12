//
//  List.swift
//  openred
//
//  Created by Norbert Antal on 6/6/23.
//

import Foundation

struct Post: Identifiable, Codable {
    var id: String
    var title: String
    var community: String?
    var commentCount: String
    var userName: String
    var submittedAge: String
    var linkToThread: String
    var score: String
    
    init(_ linkToThread: String, title: String, community: String?, commentCount: String,
         userName: String, submittedAge: String, score: String) {
        self.id = linkToThread
        self.title = title
        self.community = community
        self.commentCount = commentCount
        self.userName = userName
        self.submittedAge = submittedAge
        self.linkToThread = linkToThread
        self.score = score
    }
}

enum ContentType {
    case text
    case image
    case video
    case link
}
