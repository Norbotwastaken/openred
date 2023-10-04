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
//    var isUser: Bool = false
    var isMultiCommunity: Bool = false
//    private var explicitURL: URL?
    
    init(community: Community? = nil, user: User? = nil, explicitURL: URL? = nil) {
        self.id = ""
        self.isMultiCommunity = false
        if community != nil {
            self.community = community
            self.id = community!.id
//            self.isUser = false
            self.isMultiCommunity = community!.isMultiCommunity
        } else if user != nil {
            self.user = user
            self.id = user!.id
//            self.isUser = true
            self.isMultiCommunity = true
        } else if explicitURL != nil && explicitURL!.pathComponents.count > 2 {
            let typeComponent = explicitURL!.pathComponents[1]
            let nameComponent = explicitURL!.pathComponents[2]
            self.id = nameComponent
            if typeComponent == "r" {
                self.community = Community(nameComponent)
            } else if typeComponent == "user" || typeComponent == "u" {
                self.user = User(nameComponent)
            }
        }
    }
    
    var isUser: Bool {
        user != nil
    }
    
    var isAdFriendly: Bool {
        community != nil && community!.isAdFriendly
    }
    
    func getCode() -> String {
        isUser ? "user/" + user!.name.lowercased() : community!.path == nil ?
        "r/" + community!.name.lowercased() : community!.path!
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
    
    init(collection: CollectionListItem) {
        self.id = collection.id.uuidString
        self.name = collection.name
        self.isMultiCommunity = true
        self.path = "r/"
        if collection.communities != nil {
            for item in collection.communities! {
                self.path = self.path! + item.name + "+"
            }
        }
    }
    
    var isAdFriendly: Bool {
        about != nil && about!.isAdFriendly
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
