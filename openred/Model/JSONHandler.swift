//
//  JSONHandler.swift
//  openred
//
//  Created by Norbert Antal on 6/20/23.
//

import Foundation

class JSONHandler {
    var content: [String:String] = [:]
    
    func getData(url: String) {
        let config = URLSessionConfiguration.default
        config.httpCookieStorage = HTTPCookieStorage()
        for (_, cookieProperties) in UserSessionManager().currentCookies ?? [:] {
            if let cookie = HTTPCookie(properties: cookieProperties as! [HTTPCookiePropertyKey : Any] ) {
                config.httpCookieStorage?.setCookie(cookie)
            }
        }
        let session = URLSession(configuration: config)
        let extendedUrl = url.hasSuffix("/") ? url : url + "/"
        if let URL = URL(string: extendedUrl + ".json") {
            session.dataTask(with: URL) { data, response, error in
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
    
    func mapCommentRoot(commentRoot: CommentRoot) {
        if commentRoot.data != nil {
            mapCommentData(commentData: commentRoot.data!)
        }
    }
    
    func mapCommentData(commentData: CommentData) {
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
