//
//  JSONHandler.swift
//  openred
//
//  Created by Norbert Antal on 6/20/23.
//

import Foundation

class JSONDataLoader {
    var content: [String:String] = [:]
    
    func getData(url: String) {
        if let URL = URL(string: url) {
            URLSession.shared.dataTask(with: URL) { data, response, error in
                if let data = data {
                    do {
                        let parsedData: [CommentRoot] = try JSONDecoder().decode([CommentRoot].self, from: data)
                        self.mapCommentRoot(commentRoot: parsedData[1])
                    } catch let error {
                        print(error)
                    }
                }
            }.resume()
        }
    }
    
//    func loadPosts(url: URL, completion: @escaping ([JSONPost]?, String?, Error?) -> Void) {
//        let urlSession: URLSessionDataTask = URLSession.shared.dataTask(with: url) { (data, response, error) in
//            do {
//                if let data = data {
//                    let postsWrapper: JSONPostsWrapper = try JSONDecoder().decode(JSONPostsWrapper.self, from: data)
//                    let posts: [JSONPost] = postsWrapper.data.children.map { wrapper in
//                        return wrapper.data
//                    }
//                    completion(posts, postsWrapper.data.after, error)
//                }
//            } catch let error {
//                print(error)
//            }
//        }
//        urlSession.resume()
//    }
    
    func loadItems(url: URL, completion: @escaping ([PostOrComment]?, String?, Error?) -> Void) {
        let urlSession: URLSessionDataTask = URLSession.shared.dataTask(with: url) { (data, response, error) in
            do {
                if let data = data {
                    let postsWrapper: JSONPostsWrapper = try JSONDecoder().decode(JSONPostsWrapper.self, from: data)
                    var items: [PostOrComment] = []
                    for i in postsWrapper.data.children.indices {
                        let wrapper = postsWrapper.data.children[i]
                        let isActiveLoadMarker = (i == postsWrapper.data.children.count - 7)
                        if wrapper.data != nil {
                            items.append(PostOrComment(post: Post(jsonPost: wrapper.data!),
                                                       isActiveLoadMarker: isActiveLoadMarker))
                        } else if wrapper.commentData != nil {
                            items.append(PostOrComment(comment: Comment(jsonComment: wrapper.commentData!),
                                                       isActiveLoadMarker: isActiveLoadMarker))
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
    
    func loadComments(url: URL, completion: @escaping ([Comment]?, Error?) -> Void) {
        let urlSession: URLSessionDataTask = URLSession.shared.dataTask(with: url) { (data, response, error) in
            do {
                if let data = data {
                    let wrapper: [JSONEntityWrapper] = try JSONDecoder().decode([JSONEntityWrapper].self, from: data)
                    let comments: [Comment] = wrapper[1].data!.children
                        .filter{$0.commentData != nil}
                        .map{ Comment(jsonComment: $0.commentData!) }
                    if comments[0].stickied && comments[0].isMod {
                        comments[0].isCollapsed = true
                    }
                    completion(comments, error)
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
    func format(text: String) -> AttributedString {
        var result: AttributedString = AttributedString()
        var formatted: String = text
        
        formatted = formatted.replacingOccurrences(of: "&amp;#x200B;", with: "")
        try? result = AttributedString(markdown: formatted, options: AttributedString
            .MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace))
        return result
    }
}
