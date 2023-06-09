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
    var community: String
    var commentCount: String
    var userName: String
    var liveTimestamp: String
    var linkToThread: String
    
    init(_ id:String, title:String, community:String, commentCount:String,
         userName:String, liveTimestamp:String, linkToThread:String){
        self.id = id
        self.title = title
        self.community = community
        self.commentCount = commentCount
        self.userName = userName
        self.liveTimestamp = liveTimestamp
        self.linkToThread = linkToThread
    }
}
