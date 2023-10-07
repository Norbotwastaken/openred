//
//  JSONAboutParser.swift
//  openred
//
//  Created by Norbert Antal on 8/1/23.
//

import Foundation

class JSONAboutCommunitiesWrapper: Codable {
    var kind: String
    var data: JSONAboutListWrapper
}

class JSONAboutListWrapper: Codable {
    var after: String?
    var children: [JSONAboutWrapper]
}

class JSONAboutWrapper: Codable {
    var kind: String
    var data: JSONAbout
}

class JSONAbout: Codable {
//    var user_flair_background_color: String
//    var submit_text_html: String
//    var restrict_posting: String
//    var user_is_banned: String
//    var free_form_reports: String
//    var wiki_enabled: String
//    var user_is_muted: String
//    var user_can_flair_in_sr: String
    var display_name: String
//    var header_img: String
    var title: String
//    var allow_galleries: String
//    var icon_size: String
//    var primary_color: String
    var active_user_count: Int?
//    var icon_img: String
//    var display_name_prefixed: String
//    var accounts_active: String
//    var public_traffic: String
    var subscribers: Int?
//    var user_flair_richtext: String
//    var name: String
//    var quarantine: String
//    var hide_ads: String
//    var prediction_leaderboard_entry_type: String
//    var emojis_enabled: String
    var advertiser_category: String?
    var public_description: String?
//    var comment_score_hide_mins: String
//    var allow_predictions: String
//    var user_has_favorited: String
//    var user_flair_template_id: String
    var community_icon: String?
    var banner_background_image: String?
//    var original_content_tag_enabled: String
//    var community_reviewed: String
    var submit_text: AttributedString?
//    var description_html: String
//    var spoilers_enabled: String
            
//    var allow_talks: String
//    var header_size: String
//    var user_flair_position: String
//    var all_original_content: String
//    var has_menu_widget: String
//    var is_enrolled_in_new_modmail: String
//    var key_color: String
//    var can_assign_user_flair: String
    var created: Double
//    var wls: Int // ?
//    var show_media_preview: String
//    var submission_type: String
//    var user_is_subscriber: String
//    var allow_videogifs: String
//    var should_archive_posts: String
//    var user_flair_type: String
//    var allow_polls: String
//    var collapse_deleted_comments: String
//    var emojis_custom_size: String
//    var public_description_html: String
//    var allow_videos: String
//    var is_crosspostable_subreddit: String
//    var notification_level: String
//    var should_show_media_in_comments_setting: String
//    var can_assign_link_flair: String
//    var accounts_active_is_fuzzed: String
//    var allow_prediction_contributors: String
//    var submit_text_label: String
//    var link_flair_position: String
//    var user_sr_flair_enabled: String
//    var user_flair_enabled_in_sr: String
//    var allow_chat_post_creation: String
//    var allow_discovery: String
//    var accept_followers: String
//    var user_sr_theme_enabled: String
//    var link_flair_enabled: String
//    var disable_contributor_requests: String
//    var subreddit_type: String
//    var suggested_comment_sort: String
//    var banner_img: String
//    var user_flair_text: String
//    var banner_background_color: String
//    var show_media: String
//    var id: String
//    var user_is_moderator: String
    var over18: Bool?
    var header_title: String?
    var description: AttributedString?
//    var is_chat_post_feature_enabled: String
//    var submit_link_label: String
//    var user_flair_text_color: String
//    var restrict_commenting: String
//    var user_flair_css_class: String
//    var allow_images: String
//    var lang: String
    var whitelist_status: String?
//    var url: String
//    var created_utc: String
//    var banner_size: String
//    var mobile_banner_image: String
//    var user_is_contributor: String
//    var allow_predictions_tournament: String
    required init(from decoder: Decoder) throws {
        let container =  try decoder.container(keyedBy: CodingKeys.self)
        do { try self.banner_background_image = container.decode(String?.self, forKey: .banner_background_image) } catch {}
        do { try self.public_description = container.decode(String?.self, forKey: .public_description) } catch {}
        do { try self.advertiser_category = container.decode(String?.self, forKey: .advertiser_category) } catch {}
        do { try self.header_title = container.decode(String?.self, forKey: .header_title) } catch {}
        do { try self.active_user_count = container.decode(Int?.self, forKey: .active_user_count) } catch {}
        do { try self.subscribers = container.decode(Int?.self, forKey: .subscribers) } catch {}
        do { try self.whitelist_status = container.decode(String?.self, forKey: .whitelist_status) } catch {}
        do {
            var text: String = ""
            var attributedText: AttributedString?
            try? attributedText = container.decode(AttributedString?.self, forKey: .description)
            if attributedText != nil {
                text = String(attributedText!.characters[...])
                self.description = ContentFormatter().formatAndConvert(text: text)
            }
        }
        do {
            var text: String = ""
            var attributedText: AttributedString?
            try? attributedText = container.decode(AttributedString?.self, forKey: .submit_text)
            if attributedText != nil {
                text = String(attributedText!.characters[...])
                self.submit_text = ContentFormatter().formatAndConvert(text: text)
            }
        }
        do { try self.community_icon = String(htmlEncodedString: container.decode( String?.self, forKey: .community_icon)!) } catch {}
        
        try self.title = container.decode(String.self, forKey: .title)
        try self.display_name = container.decode(String.self, forKey: .display_name)
        try? self.over18 = container.decode(Bool?.self, forKey: .over18)
        try self.created = container.decode(Double.self, forKey: .created)
//        try self.whitelist_status = container.decode(String.self, forKey: .whitelist_status)
    }
}

class AboutCommunity: ObservableObject {
    var title: String
    var displayName: String
    var activeUserCount: Int
    var subscribers: Int?
    var advertiserCategory: String?
    var publicDescription: String?
    var communityIcon: String?
    var bannerBackgroundImage: String?
    var submitText: AttributedString?
    var over18: Bool?
    var headerTitle: String?
    var description: AttributedString?
//    var whitelistStatus: String
    var isAdFriendly: Bool
    var created: String
    
    init(json: JSONAbout) {
        self.title = json.title
        self.displayName = json.display_name
        self.activeUserCount = json.active_user_count ?? 0
        self.subscribers = json.subscribers
        self.advertiserCategory = json.advertiser_category
        self.publicDescription = json.public_description
        self.communityIcon = json.community_icon ?? ""
        self.bannerBackgroundImage = json.banner_background_image
        self.submitText = json.submit_text
        self.over18 = json.over18
        self.headerTitle = json.header_title
        self.description = json.description
        self.isAdFriendly = json.whitelist_status == "all_ads"
//        self.whitelistStatus = json.whitelist_status
        self.created = ""
        self.created = displayAge(Date(timeIntervalSince1970: TimeInterval(json.created)).timeAgoDisplay())
    }
    
    func displayAge(_ formattedTime: String) -> String {
        var timeSections = formattedTime.components(separatedBy: " ")
        return timeSections[0] + timeSections[1].prefix(1)
    }
}

class JSONRulesWrapper: Codable {
    var rules: [JSONRule]
}

class JSONRule: Codable {
    var kind: String
    var description: AttributedString?
    var short_name: AttributedString?
    var violation_reason: String
    var priority: Int
    
    required init(from decoder: Decoder) throws {
        let container =  try decoder.container(keyedBy: CodingKeys.self)
        do {
            var text: String = ""
            var desc: AttributedString?
            try desc = container.decode(AttributedString?.self, forKey: .description)
            if desc != nil {
                text = String(desc!.characters[...])
                self.description = ContentFormatter().formatAndConvert(text: text)
            }
        } catch {}
        do {
            var text: String = ""
            var sname: AttributedString?
            try sname = container.decode(AttributedString?.self, forKey: .short_name)
            if sname != nil {
                text = String(sname!.characters[...])
                self.short_name = ContentFormatter().formatAndConvert(text: text)
            }
        } catch {}
        
        try self.kind = container.decode(String.self, forKey: .kind)
        try self.violation_reason = container.decode(String.self, forKey: .violation_reason)
        try self.priority = container.decode(Int.self, forKey: .priority)
    }
}

class CommunityRule: Codable, Identifiable {
    var id: Int
    var kind: String
    var description: AttributedString
    var short_name: AttributedString
    var violation_reason: String
    var priority: Int
    
    init(json: JSONRule) {
        self.id = json.priority
        self.kind = json.kind
        self.description = json.description ?? ""
        self.short_name = json.short_name ?? ""
        self.violation_reason = json.violation_reason
        self.priority = json.priority
    }
}

class JSONAboutUserWrapper: Codable {
    var kind: String
    var data: JSONAboutUser
}

class JSONAboutUser: Codable {
//    var is_employee: Bool
    var is_friend: Bool
    var subreddit: JSONAboutUserSubreddit
//    var snoovatar_size: String
    var awardee_karma: Int
    var id: String
    var verified: Bool
    var is_gold: Bool
    var is_mod: Bool
    var awarder_karma: Int
//    var has_verified_email: Bool
    var icon_img: String?
//    var hide_from_robots: Bool
    var link_karma: Int
//    var pref_show_snoovatar: Bool
    var is_blocked: Bool
    var total_karma: Int
//    var accept_chats: Bool
    var name: String
    var created: Double
//    var created_utc: String
//    var snoovatar_img: String
    var comment_karma: Int
    var accept_followers: Bool
    var has_subscribed_to_premium: Bool?
//    var has_subscribed: Bool
//    var accept_pms: Bool
}

class JSONAboutUserSubreddit: Codable {
//    var default_set: Bool
//    var user_is_contributor: Bool?
    var banner_img: String
//    var allowed_media_in_comments: String
//    var user_is_banned: Bool
//    var free_form_reports: Bool
//    var community_icon: String?
//    var show_media: Bool
//    var icon_color: String
//    var user_is_muted: Bool?
    var display_name: String
//    var header_img: String?
//    var title: String
//    var previous_names: [String]
    var over_18: Bool
//    var icon_size: [Int]
//    var primary_color: String
    var icon_img: String
    var description: String
//    var submit_link_label: String
//    var header_size: String
//    var restrict_posting: Bool
//    var restrict_commenting: Bool
//    var subscribers: Int
//    var submit_text_label: String
//    var is_default_icon: Bool
//    var link_flair_position: String
    var display_name_prefixed: String
//    var key_color: String
//    var name: String
//    var is_default_banner: Bool
//    var url: String
//    var quarantine: Bool?
//    var banner_size: String
//    var user_is_moderator: Bool
//    var accept_followers: Bool
    var public_description: String
//    var link_flair_enabled: Bool
//    var disable_contributor_requests: Bool
//    var subreddit_type: String
//    var user_is_subscriber: Bool
}

class AboutUser: Identifiable, ObservableObject {
    @Published var is_friend: Bool
    var awardee_karma: Int
    var id: String
    var verified: Bool
    var is_gold: Bool
    var is_mod: Bool
    var awarder_karma: Int
    var icon_img: String?
    var link_karma: Int
    @Published var is_blocked: Bool
    var total_karma: Int
    var name: String
    var created: Double
    var comment_karma: Int
    var accept_followers: Bool
//    var has_subscribed: Bool
//    var accept_pms: Bool
    
//    var user_is_contributor: Bool?
    var banner_img: String
//    var user_is_banned: Bool
//    var free_form_reports: Bool
    var display_name: String
    var over_18: Bool
    var description: String
//    var subscribers: Int
    var display_name_prefixed: String
//    var user_is_moderator: Bool
    var public_description: String
    var hasPremium: Bool = false
    
    init(json: JSONAboutUser) {
        self.is_friend = json.is_friend
        self.awardee_karma = json.awardee_karma
        self.id = json.id
        self.verified = json.verified
        self.is_gold = json.is_gold
        self.is_mod = json.is_mod
        self.awarder_karma = json.awarder_karma
        self.icon_img = json.icon_img
        self.link_karma = json.link_karma
        self.is_blocked = json.is_blocked
        self.total_karma = json.total_karma
        self.name = json.name
        self.created = json.created
        self.comment_karma = json.comment_karma
        self.accept_followers = json.accept_followers
        if json.has_subscribed_to_premium == true {
            self.hasPremium = true
        }
//        self.has_subscribed = json.has_subscribed
//        self.accept_pms = json.accept_pms
//        self.user_is_contributor = json.subreddit.user_is_contributor
        self.banner_img = json.subreddit.banner_img
//        self.user_is_banned = json.subreddit.user_is_banned
//        self.free_form_reports = json.subreddit.free_form_reports
        self.display_name = json.subreddit.display_name
        self.over_18 = json.subreddit.over_18
        self.description = json.subreddit.description
//        self.subscribers = json.subreddit.subscribers
        self.display_name_prefixed = json.subreddit.display_name_prefixed
//        self.user_is_moderator = json.subreddit.user_is_moderator
        self.public_description = json.subreddit.public_description
    }
}

class JSONTrophiesWrapper: Codable {
    var kind: String
    var data: JSONTrophies
}

class JSONTrophies: Codable {
    var trophies: [JSONTrophyWrapper]
}

class JSONTrophyWrapper: Codable {
    var kind: String
    var data: JSONTrophy
}

class JSONTrophy: Codable {
    var icon_70: String
    var granted_at: Int?
//    var url: String?
    var icon_40: String
    var name: String
    var award_id: String?
    var id: String?
    var description: String?
}

class Trophy: Identifiable {
    var id: String
    var icon_70: String
    var granted_at: Int?
//    var url: String?
    var icon_40: String
    var name: String
    var award_id: String?
//    var id: String?
    var description: String?
    
    init(json: JSONTrophy) {
        self.id = json.name
        self.icon_70 = json.icon_70
        self.granted_at = json.granted_at
        self.icon_40 = json.icon_40
        self.name = json.name
        self.award_id = json.award_id
        self.description = json.description
    }
}
