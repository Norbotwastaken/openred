//
//  Community.swift
//  openred
//
//  Created by Norbert Antal on 6/9/23.
//

import Foundation

struct Community: Identifiable, Codable {
    var id: String
    
    var name: String
    var link: String
    var iconName: String?
    
    init(_ name:String, link:String, iconName:String?){
        self.id = name
        self.name = name
        self.link = link
        self.iconName = iconName
    }
}
