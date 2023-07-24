//
//  Community.swift
//  openred
//
//  Created by Norbert Antal on 6/9/23.
//

import Foundation

struct CommunityOrUser: Identifiable, Codable {
    var id: String
    var community: Community?
    var user: User?
    var isUser: Bool = false
    var isMultiCommunity: Bool = false
    
    init(community: Community? = nil, user: User? = nil) {
        if community != nil {
            self.community = community
            self.id = community!.id
            self.isUser = false
            self.isMultiCommunity = community!.isMultiCommunity
        } else {
            self.user = user
            self.id = user!.id
            self.isUser = true
            self.isMultiCommunity = true
        }
    }
}

struct Community: Identifiable, Codable {
    var id: String
    
    var name: String
    var link: String
    var iconName: String?
    var isMultiCommunity: Bool = false
    var communityCode: String
    
    init(_ name: String, link: String, iconName: String?,
         isMultiCommunity: Bool = false, communityCode: String){
        self.id = name
        self.name = name
        self.link = link
        self.iconName = iconName
        self.isMultiCommunity = isMultiCommunity
        self.communityCode = communityCode
    }
}

struct User: Identifiable, Codable {
    var id: String
    var name: String
    
    init(_ name: String) {
        self.id = name
        self.name = name
    }
}
