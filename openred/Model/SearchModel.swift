//
//  SearchModel.swift
//  openred
//
//  Created by Norbert Antal on 8/12/23.
//

import Foundation

class SearchModel: ObservableObject {
    @Published var communities: [Community] = []
    @Published var popularCommunities: [Community] = []
    @Published var visitedCommunities: [Community] = []
    private var cachedResults: [String:[Community]] = [:]
    private let jsonLoader: JSONDataLoader = JSONDataLoader()
    
    init() {
        loadPopularCommunities()
    }
    
    func searchCommunities(searchQuery: String) {
        if cachedResults[searchQuery] != nil {
            communities = cachedResults[searchQuery]!
            return
        }
        var components = URLComponents()
        components.scheme = "https"
        components.host = "old.reddit.com"
        components.queryItems = []
        components.path = "/subreddits/search/.json"
        components.queryItems!.append(URLQueryItem(name: "q", value: searchQuery))
        components.queryItems!.append(URLQueryItem(name: "limit", value: "20"))
        jsonLoader.loadAboutCommunities(url: components.url!) { (abouts, after, error) in
            DispatchQueue.main.async {
                if let abouts = abouts {
                    self.communities = abouts
                        .map{ Community($0.displayName, iconURL: $0.communityIcon!,
                                        isMultiCommunity: false) }
                    self.cachedResults[searchQuery] = self.communities
                }
            }
        }
    }
    
    func loadPopularCommunities() {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "old.reddit.com"
        components.queryItems = []
        components.path = "/subreddits/.json"
        components.queryItems!.append(URLQueryItem(name: "limit", value: "100"))
        jsonLoader.loadAboutCommunities(url: components.url!) { (abouts, after, error) in
            DispatchQueue.main.async {
                if let abouts = abouts {
                    self.popularCommunities = []
                    for _ in 1...5 {
                        let about = abouts[Int.random(in: 2..<98)]
                        self.popularCommunities.append(Community(about.displayName,iconURL: about.communityIcon!,
                                                                 isMultiCommunity: false))
                    }
                }
            }
        }
    }
    
    func addVisitedCommunity(community: Community) {
        if let index = (visitedCommunities.indices.filter{ visitedCommunities[$0].name == community.name }.first) {
            visitedCommunities.remove(at: index)
        }
        visitedCommunities.insert(community, at: 0)
    }
}
