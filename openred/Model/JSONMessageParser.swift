//
//  JSONMessageParser.swift
//  openred
//
//  Created by Norbert Antal on 7/13/23.
//

import Foundation

class JSONMessageEntityWrapper: Codable {
    var kind: String
    var data: JSONMessageEntityData?
    var messageData: JSONMessage?
    
    required init(from decoder: Decoder) throws {
        let container =  try decoder.container(keyedBy: CodingKeys.self)
        
        try self.kind = container.decode(String.self, forKey: .kind)
        try? self.data = container.decode(JSONMessageEntityData.self, forKey: .data)
        try? self.messageData = container.decode(JSONMessage.self, forKey: .data)
    }
}
    
class JSONMessageEntityData: Codable {
    var after: String?
    var before: String?
    var children: [JSONMessageEntityWrapper]
}

class JSONMessage: Codable {
//    var first_message: String
//    var first_message_name: String
    var subreddit: String?
//    var likes: Bool?
//    var replies: String
//    var author_fullname: String
    var id: String
    var subject: String
//    var associated_awarding_id: String
//    var score: String
    var author: String
    var num_comments: Int?
    var parent_id: String? // maybe important
//    var subreddit_name_prefixed: String
    var new: Bool // unread
//    var type: String
    var body: String
    var link_title: String?
    var dest: String // my username or sub name
//    var was_comment: Bool
//    var body_html: String
//    var name: String
    var created: Int
//    var created_utc: String
    var context: String? // link
//    var distinguished: String?
}

class Message: Identifiable, ObservableObject {
    var subreddit: String?
    var id: String
    var subject: String
    var author: String
    var num_comments: Int?
    var parent_id: String?
    var new: Bool
    var body: String
    var link_title: String?
    var dest: String
    var created: Int
    var context: String?
    var age: String = ""
    var type: String
    
    init(json: JSONMessage, type: String) {
        self.subreddit = json.subreddit
        self.id = json.id
        self.subject = json.subject
        self.author = json.author
        self.num_comments = json.num_comments
        self.parent_id = json.parent_id
        self.new = json.new
        self.body = json.body
        self.link_title = json.link_title
        self.dest = json.dest
        self.created = json.created
        self.context = json.context
        self.type = type
        
        self.age = displayAge(Date(timeIntervalSince1970: TimeInterval(json.created)).timeAgoDisplay())
    }
    
    func displayAge(_ formattedTime: String) -> String {
        var timeSections = formattedTime.components(separatedBy: " ")
        return timeSections[0] + timeSections[1].prefix(1)
    }
}
