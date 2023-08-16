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
    var body: AttributedString?
    var link_title: String?
    var dest: String // my username or sub name
//    var was_comment: Bool
//    var body_html: String
//    var name: String
    var created: Int
//    var created_utc: String
    var context: String // link
    var distinguished: String?
    
    required init(from decoder: Decoder) throws {
        let container =  try decoder.container(keyedBy: CodingKeys.self)
        do { try self.subreddit = container.decode(String?.self, forKey: .subreddit) } catch {}
        do { try self.parent_id = container.decode(String?.self, forKey: .parent_id) } catch {}
        do { try self.num_comments = container.decode(Int?.self, forKey: .num_comments) } catch {}
        do { try self.link_title = container.decode(String?.self, forKey: .link_title) } catch {}
        do { try self.distinguished = container.decode(String?.self, forKey: .distinguished) } catch {}
        do {
            var text: String = ""
            try text = String(container.decode(AttributedString?.self, forKey: .body)!.characters[...])
            self.body = ContentFormatter().format(text: text)
        } catch {}
        
        try self.id = container.decode(String.self, forKey: .id)
        try self.context = container.decode(String.self, forKey: .context)
        try self.subject = container.decode(String.self, forKey: .subject)
        try self.author = container.decode(String.self, forKey: .author)
        try self.new = container.decode(Bool.self, forKey: .new)
        try self.dest = container.decode(String.self, forKey: .dest)
        try self.created = container.decode(Int.self, forKey: .created)
    }
}

class Message: Identifiable, ObservableObject {
    var subreddit: String?
    var id: String
    var subject: String
    var author: String
    var num_comments: Int?
    var parent_id: String?
    var new: Bool
    var body: AttributedString
    var link_title: String?
    var dest: String
    var created: Int
    var context: String
    var age: String = ""
    var type: String
    var isAdminMessage: Bool = false
    
    init(json: JSONMessage, type: String) {
        self.subreddit = json.subreddit
        self.id = json.id
        self.subject = json.subject
        self.author = json.author
        self.num_comments = json.num_comments
        self.parent_id = json.parent_id
        self.new = json.new
        self.body = json.body ?? ""
        self.link_title = json.link_title
        self.dest = json.dest
        self.created = json.created
        self.context = json.context
        self.type = type
        if json.distinguished == "admin" {
            self.isAdminMessage = true
        }
        
        self.age = displayAge(Date(timeIntervalSince1970: TimeInterval(json.created)).timeAgoDisplay())
    }
    
    func displayAge(_ formattedTime: String) -> String {
        var timeSections = formattedTime.components(separatedBy: " ")
        return timeSections[0] + timeSections[1].prefix(1)
    }
}
