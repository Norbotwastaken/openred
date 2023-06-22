//
//  JSONParser.swift
//  openred
//
//  Created by Norbert Antal on 6/22/23.
//

import Foundation

class JSONPostsWrapper: Codable {
    var kind: String
    var data: JSONPostsData
}

class JSONPostsData: Codable {
    var after: String?
    var dist: Int?
    var children: [JSONPostWrapper]
}

class JSONPostWrapper: Codable {
    var kind: String
    var data: JSONPost
}

class JSONPost: Codable {
//    var approved_at_utc: String?
    var subreddit: String?
    var selftext: String?
    var author_fullname: String?
    var saved: Bool //
//    var mod_reason_title: String?
//    var gilded: Int?
    var clicked: Bool
    var title: String? //
//    var link_flair_richtext: String?
    var subreddit_name_prefixed: String?
    var hidden: Bool
//    var pwls: Int
//    var link_flair_css_class: String?
//    var downs: Int
//    var thumbnail_height: Int
//    var top_awarded_type: String?
//    var hide_score: Bool
    var name: String? // t3_ + id
//    var quarantine: Bool
//    var link_flair_text_color: String?
//    var upvote_ratio: Double
//    var author_flair_background_color: String?
//    var ups: Int
//    var total_awards_received: Int
//    var media_embed: String?
//    var thumbnail_width: Int
//    var author_flair_template_id: String?
//    var is_original_content: Bool
//    var user_reports: [String]
//    var secure_media: String?
    var is_reddit_media_domain: Bool
    var is_meta: Bool
//    var category: String?
//    var secure_media_embed: String?
    var link_flair_text: String?
//    var can_mod_post: Bool
    var score: Int
//    var approved_by: String?
//    var is_created_from_ads_ui: Bool
//    var author_premium: Bool
    var thumbnail: String?
    var edited: Bool
//    var author_flair_css_class: String?
//    var author_flair_richtext: String?
//    var gildings: String?
    var post_hint: String? // image, link, self, hosted:video, rich:video (tiktok)
//    var content_categories: String?
    var is_self: Bool
//    var subreddit_type: String?
    var created: Double
//    var link_flair_type: String?
//    var wls: Int
//    var removed_by_category: String?
//    var banned_by: String?
//    var author_flair_type: String?
    var domain: String?
//    var allow_live_comments: Bool
//    var selftext_html: String?
    var likes: Bool? // true/false/null
//    var suggested_sort: String?
//    var banned_at_utc: String?
    var url_overridden_by_dest: String? // in case of image
//    var view_count: Int?
    var archived: Bool
//    var no_follow: Bool
//    var is_crosspostable: Bool
    var pinned: Bool
    var over_18: Bool
    
    var preview: JSONPostDataPreview?
    var media_metadata: JSONPostMediaMetaData? // gallery
    
    var all_awardings: [JSONPostAwarding]
//    var awarders: [String]
    var media_only: Bool
//    var link_flair_template_id: String?
//    var can_gild: Bool
    var spoiler: Bool
    var locked: Bool
    var author_flair_text: String? //
//    var treatment_tags: [String]
    var visited: Bool
//    var removed_by: String?
//    var mod_note: String?
//    var distinguished: String?
    var subreddit_id: String?
//    var author_is_blocked: Bool
//    var mod_reason_by: String?
//    var num_reports: Int?
//    var removal_reason: String?
//    var link_flair_background_color: String?
    var id: String
//    var is_robot_indexable: Bool
//    var report_reasons: String?
    var author: String
//    var discussion_type: String?
    var num_comments: Int //
//    var send_replies: Bool
    var whitelist_status: String? // all_ads
//    var contest_mode: Bool
//    var mod_reports: [String]
//    var author_patreon_flair: String?
//    var author_flair_text_color: String?
    var permalink: String
    var parent_whitelist_status: String? // all_ads
    var stickied: Bool
    var url: String?
    var subreddit_subscribers: Int
    var created_utc: Double
//    var num_crossposts: Int
    var media: JSONPostMedia? // true reddit video
    var is_video: Bool?
    var is_gallery: Bool?
    var gallery_data: JSONPostGalleryData?
    var crosspost_parent_list: [JSONPost]?
}

class JSONPostMedia: Codable {
    var reddit_video: JSONPostRedditVideo
}

class JSONPostRedditVideo: Codable {
    var hls_url: String
}

class JSONPostDataPreview: Codable {
    var images: [JSONPostImage]
    var reddit_video_preview: JSONPostDataPreviewRedditVideo? // fake gif to reddit video
    var enabled: Bool
}

class JSONPostDataPreviewRedditVideo: Codable {
    var hls_url: String
}

class JSONPostImage: Codable {
    var source: JSONPostImageData
    var resolutions: [JSONPostImageData]
    var variants: JSONPostImageVariants?
    var id: String?
}

class JSONPostImageVariants: Codable {
    var gif: JSONPostImage?
    var mp4: JSONPostImage?
}

class JSONPostImageData: Codable {
    var url: String
    var width: Int
    var height: Int
}

class JSONPostGalleryData: Codable {
    var items: [JSONPostGalleryDataItem]
}

class JSONPostGalleryDataItem: Codable {
    var media_id: String
    var id: Int
    var caption: String?
    var outbound_url: String?
}

class JSONPostMediaMetaData: Codable {
    var galleryItems: DecodedMediaMetaDataArray
    
    required init(from decoder: Decoder) throws {
        let container =  try decoder.container(keyedBy: CodingKeys.self)
        try galleryItems = container.decode(DecodedMediaMetaDataArray.self, forKey: .galleryItems)
    }
}

class JSONPostMediaMetaDataItem: Codable {
    var status: String?
//    var e: String?
//    var m: String?
    var p: [JSONPostMediaMetaDataItemImage] // preview data
    var s: JSONPostMediaMetaDataItemImage?
    var id: String?
}

class JSONPostMediaMetaDataItemImage: Codable {
    var u: String? // url of gallery image
}

//struct DecodedMediaMetaDataArray: Codable {
//    var array: [JSONPostMediaMetaDataItem]
//    private struct DynamicCodingKeys: CodingKey {
//        var stringValue: String
//        init?(stringValue: String) {
//            self.stringValue = stringValue
//        }
//        var intValue: Int?
//        init?(intValue: Int) {
//            return nil
//        }
//    }
//
//    init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: DynamicCodingKeys.self)
//        var tempArray = [JSONPostMediaMetaDataItem]()
//        for key in container.allKeys {
//            let decodedObject = try container.decode(JSONPostMediaMetaDataItem.self, forKey: DynamicCodingKeys(stringValue: key.stringValue)!)
//            tempArray.append(decodedObject)
//        }
//        array = tempArray
//    }
//}

struct DecodedMediaMetaDataArray: Codable {
    var elements: [String : JSONPostMediaMetaDataItem]
    private struct DynamicCodingKeys: CodingKey {
        var stringValue: String
        init?(stringValue: String) {
            self.stringValue = stringValue
        }
        var intValue: Int?
        init?(intValue: Int) {
            return nil
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKeys.self)
        var tempElements: [String : JSONPostMediaMetaDataItem] = [:]
        for key in container.allKeys {
            let decodedObject = try container.decode(JSONPostMediaMetaDataItem.self, forKey: DynamicCodingKeys(stringValue: key.stringValue)!)
            tempElements[decodedObject.id!] = decodedObject
        }
        elements = tempElements
    }
}


class JSONPostAwarding: Codable {
//    var giver_coin_reward: String?
//    var subreddit_id: String?
//    var is_new: Bool
//    var days_of_drip_extension: String?
    var coin_price: Int?
    var id: String?
//    var penny_donate: String?
//    var award_sub_type: String?
//    var coin_reward: Int
    var icon_url: String?
//    var days_of_premium: Int?
//    var tiers_by_required_awardings: String?
    var resized_icon: [JSONPostImageData]? // first is smallest
    var name: String?
    var static_icon_url: String?
}
