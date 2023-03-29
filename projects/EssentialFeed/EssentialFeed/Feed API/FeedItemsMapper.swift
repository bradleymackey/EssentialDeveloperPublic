//
//  FeedItemsMapper.swift
//  EssentialFeed
//
//  Created by Bradley Mackey on 14/04/2022.
//

import Foundation

// When we test this code, we don't import as 'testable', just the public interface.
// Therefore, we are only testing the public interface.
// This allows us to refactor any internal structures without breaking any tests.

// We create a 'clone' of the FeedItem, that just handles the decoding for the RemoteFeedLoader.
// This is because we don't want to tie the generic model 'FeedItem' to specific coding keys, which are context dependent on where the FeedItem is actually coming from.
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

internal final class FeedItemsMapper {
    private struct Root: Decodable {
        var items: [RemoteFeedItem]
    }
    
    private static var OK_200: Int { 200 }
    
    internal static func map(_ data: Data, from response: HTTPURLResponse) throws -> [RemoteFeedItem] {
        // We are decoding AND checking the status code here.
        // However, this is not a violation of the single responsibility principle because
        // this functionality is based on the API contract, which includes the status code.
        //
        // If the status code rule changes, it's a breaking change in the API contract and
        // we need to update the component to reflect the changes.
        //
        // If, for example, there was a 401 repsonse this component would simply reject the response (rather than handling reauthentication).
        // Another component would handle the authentication so that this component could
        // then fetch valid data from a 200 response.
        guard response.statusCode == OK_200 else {
            throw RemoteFeedLoader.Error.invalidData
        }
        
        do {
            let root = try JSONDecoder().decode(Root.self, from: data)
            return root.items
        } catch {
            throw RemoteFeedLoader.Error.invalidData
        }
    }
}

