//
//  JSONDataCommentParser.swift
//  openred
//
//  Created by Norbert Antal on 6/26/23.
//

import Foundation

class JSONEntityWrapper: Codable {
    var kind: String
    var data: JSONEntityData?
    var commentData: JSONCommentData?
    var postData: JSONPost?
    
    required init(from decoder: Decoder) throws {
        let container =  try decoder.container(keyedBy: CodingKeys.self)
        
        try self.kind = container.decode(String.self, forKey: .kind)
        try? self.data = container.decode(JSONEntityData.self, forKey: .data)
        try? self.commentData = container.decode(JSONCommentData.self, forKey: .data)
        try? self.postData = container.decode(JSONPost.self, forKey: .data)
    }
}

class JSONEntityData: Codable {
    var after: String?
    var dist: Int?
    var children: [JSONEntityWrapper]
}

class JSONCommentData: Codable {
//    var subreddit_id: String?
//    var approved_at_utc: String?
    var author_is_blocked: Bool
//    var comment_type: String?
//    var awarders: [String]
//    var mod_reason_by: String?
//    var banned_by: String?
    var author_flair_type: String?
    var total_awards_received: Int?
    var subreddit: String?
//    var author_flair_template_id: String?
    var likes: Bool?
//    var user_reports: String?
    var saved: Bool
    var id: String
//    var banned_at_utc: String?
//    var mod_reason_title: String?
//    var gilded: Int
    var archived: Bool
//    var collapsed_reason_code: String?
//    var no_follow: String?
    var author: String
//    var can_mod_post: String?
    var created_utc: Double
//    var send_replies: String?
    var parent_id: String?
    var score: Int
    var author_fullname: String?
//    var approved_by: String?
//    var mod_note: String?
    var all_awardings: [JSONPostAwarding]
    var collapsed: Bool
    var body: AttributedString? // the content
    var rawContent: String?
//    var edited: Bool // or maybe double
//    var top_awarded_type: String?
//    var author_flair_css_class: String?
//    var name: String?
    var is_submitter: Bool // op?
//    var downs: String?
//    var author_flair_richtext: String?
//    var author_patreon_flair: String?
//    var body_html: String?
//    var removal_reason: String?
//    var collapsed_reason: String?
    var distinguished: String?
//    var associated_award: String?
    var stickied: Bool
//    var author_premium: String?
//    var can_gild: String?
//    var gildings: String?
//    var unrepliable_reason: String?
//    var author_flair_text_color: String?
    var score_hidden: Bool
    var permalink: String?
    var subreddit_type: String?
    var locked: Bool
//    var report_reasons: String?
    var created: Double
    var author_flair_text: String?
//    var treatment_tags: String?
//    var link_id: String?
    var subreddit_name_prefixed: String?
//    var controversiality: Int
    var depth: Int
    var over_18: Bool?
//    var author_flair_background_color: String?
//    var collapsed_because_crowd_control: String?
//    var mod_reports: String?
//    var num_reports: String?
//    var ups: Int
    var replies: JSONEntityWrapper? // ="" when empty
    var link_title: String?
    var link_permalink: String?
    var media_metadata: DecodedMediaMetaDataArray?
    var spoiler: Bool = false
    
    required init(from decoder: Decoder) throws {
        let container =  try decoder.container(keyedBy: CodingKeys.self)
        
        do { try media_metadata = container.decode(DecodedMediaMetaDataArray?.self, forKey: .media_metadata) } catch {}
        try self.author_is_blocked = container.decode(Bool.self, forKey: .author_is_blocked)
        try? self.author_flair_type = container.decode(String?.self, forKey: .author_flair_type)
        try? self.total_awards_received = container.decode(Int?.self, forKey: .total_awards_received)
        try? self.subreddit = container.decode(String?.self, forKey: .subreddit)
        try? self.likes = container.decode(Bool?.self, forKey: .likes)
        try self.saved = container.decode(Bool.self, forKey: .saved)
        try self.id = container.decode(String.self, forKey: .id)
        try self.archived = container.decode(Bool.self, forKey: .archived)
        try self.author = container.decode(String.self, forKey: .author)
        try self.created_utc = container.decode(Double.self, forKey: .created_utc)
        try? self.parent_id = container.decode(String?.self, forKey: .parent_id)
        try self.score = container.decode(Int.self, forKey: .score)
        try? self.author_fullname = container.decode(String?.self, forKey: .author_fullname)
//        try? self.link_permalink = container.decode(String?.self, forKey: .link_permalink)
        do { try self.link_permalink = String(htmlEncodedString: container.decode( String?.self, forKey: .link_permalink)!) } catch {}
        try self.all_awardings = container.decode([JSONPostAwarding].self, forKey: .all_awardings)
        try self.collapsed = container.decode(Bool.self, forKey: .collapsed)

        var text: String = ""
        try text = String(container.decode(AttributedString?.self, forKey: .body)!.characters[...])
        self.body = ContentFormatter().formatAndConvert(text: text)
        self.rawContent = ContentFormatter().format(text: text)
        self.spoiler = rawContent?.contains("&gt;!") == true && rawContent?.contains("!&lt;") == true
        
        try self.is_submitter = container.decode(Bool.self, forKey: .is_submitter)
        try self.stickied = container.decode(Bool.self, forKey: .stickied)
        try self.score_hidden = container.decode(Bool.self, forKey: .score_hidden)
        try? self.permalink = container.decode(String?.self, forKey: .permalink)
        try? self.subreddit_type = container.decode(String?.self, forKey: .subreddit_type)
        try self.locked = container.decode(Bool.self, forKey: .locked)
        try? self.over_18 = container.decode(Bool?.self, forKey: .over_18)
        try self.created = container.decode(Double.self, forKey: .created)
        try? self.author_flair_text = container.decode(String?.self, forKey: .author_flair_text)
        try? self.distinguished = container.decode(String?.self, forKey: .distinguished)
        try? self.subreddit_name_prefixed = container.decode(String?.self, forKey: .subreddit_name_prefixed)
        try? self.link_title = container.decode(String?.self, forKey: .link_title)
        self.depth = 0
        try? self.depth = container.decode(Int.self, forKey: .depth)
        
        self.replies = nil
        try? self.replies = container.decode(JSONEntityWrapper?.self, forKey: .replies)
    }
}

/// Not JSON
class Comment: Identifiable, ObservableObject {
    var id: String
    var depth: Int
    var score: Int
    var content: AttributedString?
    var rawContent: String?
    var media_metadata: DecodedMediaMetaDataArray?
    var user: String?
    var age: String?
    @Published var isUpvoted: Bool
    @Published var isDownvoted: Bool
    @Published var isSaved: Bool
    
    var flair: String?
    var awardLinks: [String] = []
    var awardCount: Int?
    var communityName: String
    var archived: Bool
    var linkTitle: String?
    var postLink: String?
    
    var isOP: Bool
    var isMod: Bool
    var stickied: Bool
    var locked: Bool
    var nsfw: Bool
    @Published var replies: [Comment] = []
    
    @Published var isCollapsed: Bool
    var allParents: [String] = []
    var spoiler: Bool = false
    
    init(jsonComment: JSONCommentData) {
        self.id = jsonComment.id
        self.depth = jsonComment.depth
        self.score = jsonComment.score
        self.content = jsonComment.body
        self.rawContent = jsonComment.rawContent
        self.media_metadata = jsonComment.media_metadata
        self.user = jsonComment.author
        self.isUpvoted = jsonComment.likes != nil ? jsonComment.likes! : false
        self.isDownvoted = jsonComment.likes != nil ? !jsonComment.likes! : false
        self.isSaved = jsonComment.saved
        self.flair = jsonComment.author_flair_text
        for award in jsonComment.all_awardings {
            self.awardLinks.append(award.resized_icons![1].url)
        }
        self.awardCount = jsonComment.total_awards_received
        self.communityName = jsonComment.subreddit ?? ""
        self.archived = jsonComment.archived
        self.isOP = jsonComment.is_submitter
        self.stickied = jsonComment.stickied
        self.locked = jsonComment.locked
        if jsonComment.replies != nil {
            self.replies = jsonComment.replies!.data!.children
                .filter{$0.commentData != nil}
                .map{ Comment(jsonComment: $0.commentData!) }
        }
        self.isCollapsed = jsonComment.collapsed
        self.linkTitle = jsonComment.link_title
        self.isMod = jsonComment.distinguished == "moderator"
        self.nsfw = jsonComment.over_18 ?? false
        if jsonComment.link_permalink != nil {
            self.postLink = URL(string: jsonComment.link_permalink!
                .addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)!)!.path
        }
        
        self.spoiler = jsonComment.spoiler
        self.age = displayAge(Date(timeIntervalSince1970: TimeInterval(jsonComment.created)).timeAgoDisplay())
    }
    
    init(id: String, depth: Int, content: String, user: String) {
        self.id = id
        self.depth = depth
        self.score = 1
        try? self.content = AttributedString(markdown: content)
        self.user = user
        self.isUpvoted = true
        self.isDownvoted = false
        self.isSaved = false
        self.awardCount = 0
        self.archived = false
        self.isOP = false // ?
        self.stickied = false
        self.locked = false
        self.isCollapsed = false
        self.communityName = ""
        self.isMod = false
        self.nsfw = false
        self.spoiler = false
//        self.age = displayAge(Date(timeIntervalSince1970: TimeInterval(jsonComment.created)).timeAgoDisplay())
    }
    
    // TODO: duplicate of funciton in post
    func displayAge(_ formattedTime: String) -> String {
        let timeSections = formattedTime.components(separatedBy: " ")
        return timeSections[0] + timeSections[1].prefix(1)
    }
}
