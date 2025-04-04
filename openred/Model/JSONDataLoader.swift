//
//  JSONHandler.swift
//  openred
//
//  Created by Norbert Antal on 6/20/23.
//

import Foundation

class JSONDataLoader {
    var content: [String:String] = [:]
    
    func loadPosts(url: URL, markForAds: Bool = false, completion: @escaping ([PostOrComment]?, String?, Error?) -> Void) {
        let urlSession: URLSessionDataTask = URLSession.shared.dataTask(with: url) { (data, response, error) in
            do {
                if let data = data {
                    let postsWrapper: JSONPostsWrapper = try JSONDecoder().decode(JSONPostsWrapper.self, from: data)
                    var items: [PostOrComment] = []
//                    var adUnit: Int = 0
                    for i in postsWrapper.data.children.indices {
                        let wrapper = postsWrapper.data.children[i]
//                        let isAdMarker = (i == 5) || (i == 12) || (i == 24)
//                        if isAdMarker {
//                            adUnit = adUnit + 1
//                        }
                        if wrapper.data != nil {
                            items.append(PostOrComment(post: Post(jsonPost: wrapper.data!)))
                        } else if wrapper.commentData != nil {
                            items.append(PostOrComment(comment: Comment(jsonComment: wrapper.commentData!)))
                        }
                        
                    }
                    completion(items, postsWrapper.data.after, error)
                }
            } catch let error {
                print(error)
            }
        }
        urlSession.resume()
    }
    
    func loadComments(url: URL, completion: @escaping ([Comment]?, Post?, Error?) -> Void) {
        let urlSession: URLSessionDataTask = URLSession.shared.dataTask(with: url) { (data, response, error) in
            do {
                if let data = data {
                    let wrapper: [JSONEntityWrapper] = try JSONDecoder().decode([JSONEntityWrapper].self, from: data)
                    let post: Post? = wrapper[0].data!.children[0].postData.map{ Post(jsonPost: $0) }
                    let comments: [Comment] = wrapper[1].data!.children
                        .filter{$0.commentData != nil}
                        .map{ Comment(jsonComment: $0.commentData!) }
                    if comments.count > 0 && comments[0].stickied && comments[0].isMod {
                        comments[0].isCollapsed = true
                    }
                    completion(comments, post, error)
                }
            } catch let error {
                print(error)
            }
        }
        urlSession.resume()
    }
    
    func loadMessages(url: URL, completion: @escaping ([Message]?, Error?) -> Void) {
        let urlSession: URLSessionDataTask = URLSession.shared.dataTask(with: url) { (data, response, error) in
            do {
                if let data = data {
                    let wrapper: JSONMessageEntityWrapper = try JSONDecoder().decode(JSONMessageEntityWrapper.self, from: data)
                    let messages: [Message] = wrapper.data!.children
                        .filter{$0.messageData != nil}
                        .map{ Message(json: $0.messageData!, type: $0.kind) }
                    completion(messages, error)
                }
            } catch let error {
                print(error)
            }
        }
        urlSession.resume()
    }
    
    func loadRules(url: URL, completion: @escaping ([CommunityRule]?, Error?) -> Void) {
        let urlSession: URLSessionDataTask = URLSession.shared.dataTask(with: url) { (data, response, error) in
            do {
                if let data = data {
                    let wrapper: JSONRulesWrapper = try JSONDecoder().decode(JSONRulesWrapper.self, from: data)
                    let rules: [CommunityRule] = wrapper.rules
                        .map{ CommunityRule(json: $0) }
                    completion(rules, error)
                }
            } catch let error {
                print(error)
            }
        }
        urlSession.resume()
    }
    
    func loadAboutCommunity(url: URL, completion: @escaping (AboutCommunity?, Error?) -> Void) {
        let urlSession: URLSessionDataTask = URLSession.shared.dataTask(with: url) { (data, response, error) in
            do {
                if let data = data {
                    let wrapper: JSONAboutWrapper = try JSONDecoder().decode(JSONAboutWrapper.self, from: data)
                    let about = AboutCommunity(json: wrapper.data)
                    completion(about, error)
                }
            } catch let error {
                print(error)
            }
        }
        urlSession.resume()
    }
    
    func loadAboutCommunities(url: URL, completion: @escaping ([AboutCommunity]?, String?, Error?) -> Void) {
        let urlSession: URLSessionDataTask = URLSession.shared.dataTask(with: url) { (data, response, error) in
            do {
                if let data = data {
                    let wrapper: JSONAboutCommunitiesWrapper = try JSONDecoder().decode(JSONAboutCommunitiesWrapper.self, from: data)
                    let about: [AboutCommunity] = wrapper.data.children
                        .map{ AboutCommunity(json: $0.data) }
                    let after: String? = wrapper.data.after
                    completion(about, after, error)
                }
            } catch let error {
                print(error)
            }
        }
        urlSession.resume()
    }
    
    func loadAboutUser(url: URL, completion: @escaping (AboutUser?, Error?) -> Void) {
        let urlSession: URLSessionDataTask = URLSession.shared.dataTask(with: url) { (data, response, error) in
            do {
                if let data = data {
                    let wrapper: JSONAboutUserWrapper = try JSONDecoder().decode(JSONAboutUserWrapper.self, from: data)
                    let about = AboutUser(json: wrapper.data)
                    completion(about, error)
                }
            } catch let error {
                print(error)
            }
        }
        urlSession.resume()
    }
    
    func loadTrophies(url: URL, completion: @escaping ([Trophy]?, Error?) -> Void) {
        let urlSession: URLSessionDataTask = URLSession.shared.dataTask(with: url) { (data, response, error) in
            do {
                if let data = data {
                    let wrapper: JSONTrophiesWrapper = try JSONDecoder().decode(JSONTrophiesWrapper.self, from: data)
                    let rules: [Trophy] = wrapper.data.trophies
                        .map{ Trophy(json: $0.data) }
                    completion(rules, error)
                }
            } catch let error {
                print(error)
            }
        }
        urlSession.resume()
    }
    
    func loadUpdates(url: URL, completion: @escaping ([Comment]?, Post?, Error?) -> Void) {
        let urlSession: URLSessionDataTask = URLSession.shared.dataTask(with: url) { (data, response, error) in
            do {
                if let data = data {
                    let wrapper: [JSONEntityWrapper] = try JSONDecoder().decode([JSONEntityWrapper].self, from: data)
                    let post: Post? = wrapper[0].data!.children[0].postData.map{ Post(jsonPost: $0) }
                    let comments: [Comment] = wrapper[1].data!.children
                        .filter{$0.commentData != nil}
                        .map{ Comment(jsonComment: $0.commentData!) }
                    if comments.count > 0 && comments[0].stickied && comments[0].isMod {
                        comments[0].isCollapsed = true
                    }
                    completion(comments, post, error)
                }
            } catch let error {
                print(error)
            }
        }
        urlSession.resume()
    }
    
//    func loadPosts(url: String, completion: @escaping ([JSONPost]?, Error?) -> Void) {
//        URLSession.shared.dataTask(for: URL(string: url)!) { (data, response, error) in
//            do {
//                if let data = data {
//                    let parsedData: JSONPostsWrapper = try JSONDecoder().decode(JSONPostsWrapper.self, from: data)
//                    let posts: [JSONPost] = parsedData.data.children.map { wrapper in
//                        return wrapper.data
//                    }
//                    completion(posts, error)
//                }
//            } catch let error {
//                print(error)
//            }
//        }
//        urlSession.resume()
//    }
    
    private func mapCommentRoot(commentRoot: CommentRoot) {
        if commentRoot.data != nil {
            mapCommentData(commentData: commentRoot.data!)
        }
    }
    
    private func mapCommentData(commentData: CommentData) {
        if commentData.id != nil && commentData.body != nil {
            content[commentData.id!] = commentData.body!
        }
        if commentData.children != nil {
            for commentChild in commentData.children! {
                mapCommentRoot(commentRoot: commentChild)
            }
        }
        if commentData.replies != nil {
            mapCommentRoot(commentRoot: commentData.replies!)
        }
    }
}
    
    
class CommentRoot: Codable {
    var kind: String?
    var data: CommentData?
}

class CommentData: Codable {
    var children: [CommentRoot]?
    var replies: CommentRoot?
    var childrenString: [String]?
    var id: String?
    var body: String?
    
    required init(from decoder: Decoder) throws {
        let container =  try decoder.container(keyedBy: CodingKeys.self)
        
        do {
            try id = container.decode(String?.self, forKey: .id)
            try body = container.decode(String?.self, forKey: .body)
        } catch { }
        do {
            try replies = container.decode(CommentRoot.self, forKey: .replies)
        } catch { }
        do {
            children = try container.decode([CommentRoot].self, forKey: .children)
            childrenString = nil
        } catch {
            do {
                childrenString = try container.decode([String].self, forKey: .children)
                children = nil
            } catch {
                // no children
            }
        }
    }
}

struct ContentFormatter {
    // TODO: more formatting options (>, #, etc.) using attrString.range(of:)
    func formatAndConvert(text: String) -> AttributedString {
        var result: AttributedString = AttributedString()
        try? result = AttributedString(markdown: format(text: text), options: AttributedString
            .MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace))
        return result
    }
    
    func format(text: String) -> String {
        var formatted: String = text
        // &amp;nbsp; == &nbsp; in text
        return formatted.replacingOccurrences(of: "&amp;nbsp;", with: "")
            .replacingOccurrences(of: "&amp;#x200B;", with: "")
    }
}
