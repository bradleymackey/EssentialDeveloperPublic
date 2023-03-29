//
//  RemoteFeedItem.swift
//  EssentialFeed
//
//  Created by Bradley Mackey on 30/04/2022.
//

import Foundation

// We create a 'clone' of the FeedItem, that just handles the decoding for the RemoteFeedLoader.
// This is because we don't want to tie the generic model 'FeedItem' to specific coding keys, which are context dependent on where the FeedItem is actually coming from.

/// The representation of a feed item as recieved by the Remote API.
internal struct RemoteFeedItem: Decodable {
    internal let id: UUID
    internal let description: String?
    internal let location: String?
    internal let imageURL: URL
    
    private enum CodingKeys: String, CodingKey {
        case id
        case description
        case location
        case imageURL = "image"
    }
}
