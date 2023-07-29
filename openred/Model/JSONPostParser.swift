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
    
    required init(from decoder: Decoder) throws {
        let container =  try decoder.container(keyedBy: CodingKeys.self)
        
        try self.kind = container.decode(String.self, forKey: .kind)
        try self.data = container.decode(JSONPostsData.self, forKey: .data)
    }
}

class JSONPostsData: Codable {
    var after: String?
    var dist: Int?
    var children: [JSONPostWrapper]
}

class JSONPostWrapper: Codable {
    var kind: String
    var data: JSONPost?
    var commentData: JSONCommentData?
    
    required init(from decoder: Decoder) throws {
        let container =  try decoder.container(keyedBy: CodingKeys.self)
        
        try self.kind = container.decode(String.self, forKey: .kind)
        try? self.data = container.decode(JSONPost.self, forKey: .data)
        try? self.commentData = container.decode(JSONCommentData.self, forKey: .data)
    }
}

class JSONPost: Codable {
    //    var approved_at_utc: String?
    var subreddit: String?
    var selftext: AttributedString?
    var author_fullname: String?
    var saved: Bool //
    //    var mod_reason_title: String?
    //    var gilded: Int?
    var clicked: Bool
    var title: String? //
    var link_flair_richtext: [JSONFlairSegment]
    var flair: String?
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
    var upvote_ratio: Double?
    //    var author_flair_background_color: String?
    //    var ups: Int
    var total_awards_received: Int
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
    var edited: Bool?
    var editedAt: Double?
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
    var media_metadata: DecodedMediaMetaDataArray? // image, gallery
    
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
    
    required init(from decoder: Decoder) throws {
        let container =  try decoder.container(keyedBy: CodingKeys.self)
        do { try media_metadata = container.decode(DecodedMediaMetaDataArray?.self, forKey: .media_metadata) } catch {}
        do { try self.media = container.decode( JSONPostMedia?.self, forKey: .media) } catch {}
        do { try self.is_video = container.decode( Bool?.self, forKey: .is_video) } catch {}
        do { try self.is_gallery = container.decode( Bool?.self, forKey: .is_gallery) } catch {}
        do { try self.gallery_data = container.decode( JSONPostGalleryData?.self, forKey: .gallery_data) } catch {}
        do { try self.crosspost_parent_list = container.decode( [JSONPost]?.self, forKey: .crosspost_parent_list) } catch {}
        do { try self.subreddit = container.decode(String?.self, forKey: .subreddit) } catch {}
        do { try self.upvote_ratio = container.decode( Double?.self, forKey: .upvote_ratio) } catch {}
        do {
            var text: String = ""
            try text = String(container.decode(AttributedString?.self, forKey: .selftext)!.characters[...])
            self.selftext = ContentFormatter().format(text: text)
        } catch {}
        
        do { try self.author_fullname = container.decode(String?.self, forKey: .author_fullname) } catch {}
        do { try self.title = String(htmlEncodedString: container.decode(String?.self, forKey: .title)!) } catch {}
        do { try self.subreddit_name_prefixed = container.decode(String?.self, forKey: .subreddit_name_prefixed) } catch {}
        do { try self.name = container.decode(String?.self, forKey: .name) } catch {}
        try? self.thumbnail = String(htmlEncodedString: container.decode(String?.self, forKey: .thumbnail)!)
        do { try self.post_hint = container.decode(String?.self, forKey: .post_hint) } catch {}
        do { try self.domain = container.decode(String?.self, forKey: .domain) } catch {}
        do { try self.likes = container.decode(Bool?.self, forKey: .likes) } catch {}
        do { try self.url_overridden_by_dest = String(htmlEncodedString: container.decode(String?.self, forKey: .url_overridden_by_dest)!) } catch {}
        do { try self.preview = container.decode(JSONPostDataPreview?.self, forKey: .preview) } catch {}
        do { try self.subreddit_id = container.decode( String?.self, forKey: .subreddit_id) } catch {}
        do { try self.whitelist_status = container.decode( String?.self, forKey: .whitelist_status) } catch {}
        do { try self.parent_whitelist_status = container.decode( String?.self, forKey: .parent_whitelist_status) } catch {}
        do { try self.url = String(htmlEncodedString: container.decode( String?.self, forKey: .url)!) } catch {}
        
        try self.saved = container.decode(Bool.self, forKey: .saved)
        try self.clicked = container.decode(Bool.self, forKey: .clicked)
        try self.hidden = container.decode(Bool.self, forKey: .hidden)
        try self.is_reddit_media_domain = container.decode(Bool.self, forKey: .is_reddit_media_domain)
        try self.is_meta = container.decode(Bool.self, forKey: .is_meta)
        try self.score = container.decode(Int.self, forKey: .score)
        do { try self.edited = container.decode(Bool?.self, forKey: .edited) } catch {
            self.edited = true
            try? self.editedAt = container.decode(Double?.self, forKey: .edited)
        }
        try self.is_self = container.decode(Bool.self, forKey: .is_self)
        try self.created = container.decode(Double.self, forKey: .created)
        try self.archived = container.decode(Bool.self, forKey: .archived)
        try self.pinned = container.decode(Bool.self, forKey: .pinned)
        try self.over_18 = container.decode(Bool.self, forKey: .over_18)
        try self.all_awardings = container.decode( [JSONPostAwarding].self, forKey: .all_awardings)
        try self.media_only = container.decode( Bool.self, forKey: .media_only)
        try self.spoiler = container.decode( Bool.self, forKey: .spoiler)
        try self.locked = container.decode( Bool.self, forKey: .locked)
        try self.visited = container.decode( Bool.self, forKey: .visited)
        try self.id = container.decode( String.self, forKey: .id)
        try self.author = container.decode( String.self, forKey: .author)
        try self.num_comments = container.decode( Int.self, forKey: .num_comments)
        try self.permalink = container.decode( String.self, forKey: .permalink)
        try self.stickied = container.decode( Bool.self, forKey: .stickied)
        try self.subreddit_subscribers = container.decode( Int.self, forKey: .subreddit_subscribers)
        try self.created_utc = container.decode( Double.self, forKey: .created_utc)
        try self.total_awards_received = container.decode( Int.self, forKey: .total_awards_received)
        
        try self.link_flair_richtext = container.decode( [JSONFlairSegment].self, forKey: .link_flair_richtext)
        for flairSegment in self.link_flair_richtext {
            if flairSegment.e == "text" {
                self.flair = self.flair ?? "" + flairSegment.t!
            }
        }
        
        try? self.link_flair_text = formatFlair(container.decode(String?.self, forKey: .link_flair_text))
        try? self.author_flair_text = formatFlair(container.decode( String?.self, forKey: .author_flair_text))
    }
    
    func formatFlair(_ flair: String?) -> String? {
        if flair == nil {
            return nil
        }
        if flair!.hasPrefix(":") && flair!.hasSuffix(":") {
            return decodeEmojis(flair!.components(separatedBy: ":")[2])
        }
        return decodeEmojis(flair!)
    }
    
    func decodeEmojis(_ s: String?) -> String? {
        if s == nil {
            return nil
        }
        let data = s!.data(using: .utf8)!
        return String(data: data, encoding: .nonLossyASCII)
    }
}

class JSONPostMedia: Codable {
    var reddit_video: JSONPostRedditVideo?
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
    var url: String //
    var width: Int
    var height: Int
    
    required init(from decoder: Decoder) throws {
        let container =  try decoder.container(keyedBy: CodingKeys.self)
        try url = String(htmlEncodedString: container.decode(String.self, forKey: .url))!
        try width = container.decode(Int.self, forKey: .width)
        try height = container.decode(Int.self, forKey: .height)
    }
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
    var e: String?
//    var m: String?
    var p: [JSONPostMediaMetaDataItemImage] // preview data
    var s: JSONPostMediaMetaDataItemImage?
    var id: String?
}

class JSONPostMediaMetaDataItemImage: Codable {
    var u: String? // url of gallery image
//    var gif: String? // url if animated image
    var mp4: String? // url if animated image
    required init(from decoder: Decoder) throws {
        let container =  try decoder.container(keyedBy: CodingKeys.self)
        try? self.u = String(htmlEncodedString: container.decode(String?.self, forKey: .u)!)
        try? self.mp4 = String(htmlEncodedString: container.decode(String?.self, forKey: .mp4)!)
    }
}

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

class JSONFlairSegment: Codable {
    var e: String?
    var t: String?
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
    var resized_icons: [JSONPostImageData]? // first is smallest
    var name: String?
    var static_icon_url: String?
}
