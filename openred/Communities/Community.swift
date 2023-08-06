//
//  Community.swift
//  openred
//
//  Created by Norbert Antal on 6/9/23.
//

import Foundation

class CommunityOrUser: Identifiable, ObservableObject {
    var id: String
    @Published var community: Community?
    @Published var user: User?
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
    
    func getCode() -> String {
        isUser ? "user/" + user!.name.lowercased() : "r/" + community!.name.lowercased()
    }
}

class Community: Identifiable, ObservableObject {
    var id: String
    var name: String
    var iconName: String?
    var iconURL: String?
    var displayName: String?
    var path: String? // for pages with path other than r/whatever, eg. /saved
    var isMultiCommunity: Bool = false
    @Published var isFavorite: Bool = false
    @Published var about: AboutCommunity?
    @Published var rules: [CommunityRule] = []
    
    init(_ name: String, iconName: String? = nil, iconURL: String? = nil, isMultiCommunity: Bool = false, displayName: String? = nil, path: String? = nil) {
        self.id = name
        self.name = name
        self.iconName = iconName
        self.iconURL = iconURL
        self.isMultiCommunity = isMultiCommunity
        self.displayName = displayName
        self.path = path
    }
}

class User: Identifiable, ObservableObject {
    var id: String
    var name: String
    @Published var trophies: [Trophy] = []
    @Published var about: AboutUser?
    
    init(_ name: String) {
        self.id = name
        self.name = name
    }
}
