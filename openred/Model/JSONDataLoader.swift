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
    
    func loadPosts(url: String, completion: @escaping (Result<[JSONPost], Error>) -> Void) {
        let urlSession = URLSession.shared.dataTask(with: URL(string: url)!) { (data, response, error) in
            
            if let error = error {
                completion(.failure(error))
            }
            
            do {
                if let data = data {
                    let parsedData: JSONPostsWrapper = try JSONDecoder().decode(JSONPostsWrapper.self, from: data)
                    let posts: [JSONPost] = parsedData.data.children.map { wrapper in
                        return wrapper.data
                    }
                    completion(.success(posts))
                }
            } catch let error {
                print(error)
            }
        }
        urlSession.resume()
    }
    
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
